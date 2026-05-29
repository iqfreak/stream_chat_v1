import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';
import '../config/stream_config.dart';
import 'models.dart';

export 'models.dart'
    show
        AppUser,
        AppChannel,
        AppMessage,
        AppAttachment,
        AppNotification,
        AppReaction;

class StreamChatService extends ChangeNotifier {
  final StreamChatClient _client;

  AppUser? _currentUser;
  final List<AppChannel> _channels = [];
  final List<AppNotification> _notifications = [];
  final Map<String, Channel> _streamChannels = {};
  final Map<String, AppUser> _cachedUsers = {};
  StreamSubscription<Event>? _eventSub;

  StreamChatService()
    : _client = StreamChatClient(kStreamApiKey, logLevel: Level.SEVERE);

  StreamChatClient get client => _client;
  bool get isConnected => _client.state.currentUser != null;

  AppUser get currentUser => _currentUser!;

  List<AppChannel> get myChannels => List.unmodifiable(_channels);
  List<AppChannel> get channels => List.unmodifiable(_channels);
  List<AppUser> get allUsers => _cachedUsers.values.toList();
  List<AppUser> get otherUsers =>
      _cachedUsers.values.where((u) => u.id != _currentUser?.id).toList();

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.reversed.toList());
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  AppUser? userById(String id) => _cachedUsers[id];

  AppChannel? channelById(String id) {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Token & password helpers ─────────────────────────────────────────────

  static String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static String _generateToken(String userId) {
    // طرحنا 5 دقائق بدل 5 ثواني عشان نحل مشكلة اختلاف التوقيت مع السيرفر
    final iat = DateTime.now().subtract(const Duration(minutes: 5));
    final jwt = JWT({
      'user_id': userId,
      'iat': iat.millisecondsSinceEpoch ~/ 1000,
    });
    return jwt.sign(SecretKey(kStreamApiSecret), noIssueAt: true);
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    final hash = _hashPassword(password);
    Map<String, dynamic>? record;
    for (final u in users) {
      if (u['email'] == email && u['password_hash'] == hash) {
        record = u;
        break;
      }
    }
    if (record == null) return false;

    await _connectUser(
      userId: record['id'] as String,
      name: record['name'] as String,
      email: email,
      avatarUrl: record['avatar_url'] as String? ?? '',
    );
    await prefs.setString('sc_current_user_id', record['id'] as String);
    return true;
  }

  // Returns null if valid, or an error message string.
  static String? validateUsername(String username) {
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 24) return 'Username must be 24 characters or less';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Only lowercase letters, numbers, and underscores';
    }
    if (!RegExp(r'^[a-z]').hasMatch(username)) {
      return 'Username must start with a letter';
    }
    return null;
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String username, {
    String? avatarPath,
  }) async {
    final sanitized = username.trim().toLowerCase();
    final validationError = validateUsername(sanitized);
    if (validationError != null) throw Exception(validationError);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    if (users.any((u) => u['email'] == email)) {
      throw Exception('Email already registered');
    }
    if (users.any((u) => u['id'] == sanitized)) {
      throw Exception('Username @$sanitized is already taken');
    }

    // Also check against Stream Chat to catch users from other devices
    try {
      final existing = await _client.queryUsers(
        filter: Filter.equal('id', sanitized),
        pagination: const PaginationParams(limit: 1),
      );
      if (existing.users.isNotEmpty) {
        throw Exception('Username @$sanitized is already taken');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already taken')) rethrow;
    }

    users.add({
      'id': sanitized,
      'name': name,
      'email': email,
      'password_hash': _hashPassword(password),
      'avatar_url': avatarPath ?? '',
    });

    await prefs.setString('sc_users', jsonEncode(users));
    await prefs.setString('sc_current_user_id', sanitized);

    await _connectUser(
      userId: sanitized,
      name: name,
      email: email,
      avatarUrl: avatarPath ?? '',
    );
  }

  Future<void> logout() async {
    _eventSub?.cancel();
    _eventSub = null;
    await _client.disconnectUser();
    _currentUser = null;
    _channels.clear();
    _streamChannels.clear();
    _notifications.clear();
    _cachedUsers.clear();
    notifyListeners();
  }

  // ─── Connection & init ────────────────────────────────────────────────────

  Future<void> _connectUser({
    required String userId,
    required String name,
    required String email,
    required String avatarUrl,
  }) async {
    final token = _generateToken(userId);

    await _client.connectUser(
      User(
        id: userId,
        name: name,
        image: avatarUrl.isNotEmpty ? avatarUrl : null,
        extraData: const {},
      ),
      token,
    );

    _currentUser = AppUser(
      id: userId,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      isOnline: true,
    );
    _cachedUsers[userId] = _currentUser!;

    await _loadChannels();
    await _loadAllUsers();
    _startEvents();
    notifyListeners();
  }

  Future<void> _loadChannels() async {
    _channels.clear();
    _streamChannels.clear();

    final channelList = await _client
        .queryChannels(
          filter: Filter.in_('members', [_currentUser!.id]),
          channelStateSort: [SortOption.desc('last_message_at')],
          messageLimit: 30,
          memberLimit: 100,
        )
        .first;

    for (final ch in channelList) {
      await ch.watch();
      _streamChannels[ch.id!] = ch;
      _channels.add(_toAppChannel(ch));
      _cacheMembers(ch);
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final response = await _client.queryUsers(
        filter: Filter.notEqual('id', _currentUser!.id),
        sort: [SortOption.asc('name')],
        pagination: const PaginationParams(limit: 100),
      );
      for (final u in response.users) {
        _cachedUsers[u.id] = _toAppUser(u);
      }
    } catch (_) {}
  }

  void _startEvents() {
    _eventSub?.cancel();
    _eventSub = _client.on().listen(_handleEvent);
  }

  // ─── Event handling ───────────────────────────────────────────────────────

  void _handleEvent(Event event) {
    final type = event.type;

    if (type == EventType.messageNew ||
        type == EventType.messageUpdated ||
        type == EventType.messageDeleted ||
        type == EventType.reactionNew ||
        type == EventType.reactionDeleted) {
      _refreshChannel(event.cid);

      if (type == EventType.messageNew) {
        final msg = event.message;
        if (msg != null && msg.user?.id != _currentUser?.id) {
          _addNotification(event);
        }
      }
      notifyListeners();
      return;
    }

    if (type == EventType.channelUpdated ||
        type == 'member.added' ||
        type == 'member.removed' ||
        type == 'channel.visible') {
      _refreshChannel(event.cid);
      notifyListeners();
      return;
    }

    if (type == EventType.notificationMessageNew ||
        type == 'notification.added_to_channel') {
      _onNotificationChannel(event);
      return;
    }

    if (type == 'user.presence.changed') {
      final u = event.user;
      if (u != null) _cachedUsers[u.id] = _toAppUser(u);
      for (final ch in List<AppChannel>.from(_channels)) {
        if (ch.memberIds.contains(u?.id)) _refreshChannelById(ch.id);
      }
      notifyListeners();
    }
  }

  void _refreshChannel(String? cid) {
    if (cid == null) return;
    final id = cid.contains(':') ? cid.split(':').last : cid;
    _refreshChannelById(id);
  }

  void _refreshChannelById(String id) {
    final ch = _streamChannels[id];
    if (ch == null) return;
    final idx = _channels.indexWhere((c) => c.id == id);
    final updated = _toAppChannel(ch);
    if (idx >= 0) {
      _channels[idx] = updated;
    } else {
      _channels.insert(0, updated);
    }
    _cacheMembers(ch);
    _sortChannels();
  }

  Future<void> _onNotificationChannel(Event event) async {
    final cid = event.cid;
    if (cid == null) return;
    final id = cid.contains(':') ? cid.split(':').last : cid;

    if (!_streamChannels.containsKey(id)) {
      final ch = _client.channel('messaging', id: id);
      await ch.watch();
      _streamChannels[id] = ch;
      _channels.insert(0, _toAppChannel(ch));
      _cacheMembers(ch);
    }

    if (event.message != null && event.message!.user?.id != _currentUser?.id) {
      _addNotification(event);
    }
    notifyListeners();
  }

  void _addNotification(Event event) {
    final msg = event.message;
    if (msg == null) return;
    final cid = event.cid ?? '';
    final channelId = cid.contains(':') ? cid.split(':').last : cid;

    final notifId = 'notif_${msg.id}';
    if (_notifications.any((n) => n.id == notifId)) return;

    _notifications.add(
      AppNotification(
        id: notifId,
        fromUserId: msg.user?.id ?? '',
        channelId: channelId,
        messageId: msg.id,
        text: msg.text ?? '',
        createdAt: msg.createdAt,
        isRead: false,
      ),
    );
  }

  void _sortChannels() {
    _channels.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? DateTime(2000);
      final bTime = b.lastMessage?.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
  }

  // ─── Channels ─────────────────────────────────────────────────────────────

  Future<String> createChannel({
    required bool isGroup,
    required String name,
    required List<String> memberIds,
  }) async {
    late Channel ch;

    if (!isGroup) {
      ch = _client.channel(
        'messaging',
        extraData: {'is_group': false, 'members': memberIds},
      );
    } else {
      final id = 'grp_${const Uuid().v4().replaceAll('-', '')}';
      ch = _client.channel(
        'messaging',
        id: id,
        extraData: {'name': name, 'is_group': true},
      );
    }

    await ch.watch();

    if (isGroup) {
      await ch.addMembers(memberIds);
    }

    final channelId = ch.id!;
    _streamChannels[channelId] = ch;
    _channels.removeWhere((c) => c.id == channelId);
    _channels.insert(0, _toAppChannel(ch));
    _cacheMembers(ch);
    notifyListeners();
    return channelId;
  }

  Future<void> deleteChannel(String channelId) async {
    final ch = _streamChannels[channelId];
    if (ch != null) {
      await ch.hide(clearHistory: true);
    }
    _streamChannels.remove(channelId);
    _channels.removeWhere((c) => c.id == channelId);
    notifyListeners();
  }

  Future<void> leaveChannel(String channelId) async {
    final ch = _streamChannels[channelId];
    if (ch != null && _currentUser != null) {
      await ch.removeMembers([_currentUser!.id]);
    }
    _streamChannels.remove(channelId);
    _channels.removeWhere((c) => c.id == channelId);
    notifyListeners();
  }

  void markChannelRead(String channelId) {
    final ch = _streamChannels[channelId];
    ch?.markRead();
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx >= 0) {
      final old = _channels[idx];
      _channels[idx] = AppChannel(
        id: old.id,
        name: old.name,
        isGroup: old.isGroup,
        memberIds: old.memberIds,
        messages: old.messages,
        unreadCount: 0,
      );
      notifyListeners();
    }
  }

  Future<void> addMemberToChannel(String channelId, String userId) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;
    await ch.addMembers([userId]);
    _refreshChannelById(channelId);
    notifyListeners();
  }

  Future<void> updateChannelName(String channelId, String newName) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;
    await ch.update({'name': newName});
    _refreshChannelById(channelId);
    notifyListeners();
  }

  Future<void> renameChannel(String channelId, String newName) =>
      updateChannelName(channelId, newName);

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(String channelId, String text) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;
    await ch.sendMessage(Message(text: text));
  }

  Future<void> sendMessageWithAttachment(
    String channelId,
    String text,
    List<AppAttachment> attachments,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    final streamAttachments = attachments.map((a) {
      return Attachment(
        type: a.type,
        title: a.name,
        assetUrl: a.url,
        imageUrl: a.type == 'image' ? a.url : null,
      );
    }).toList();

    await ch.sendMessage(Message(text: text, attachments: streamAttachments));
  }

  Future<void> sendThreadReply(
    String channelId,
    String parentId,
    String text,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;
    await ch.sendMessage(
      Message(text: text, parentId: parentId, showInChannel: false),
    );
  }

  Future<List<AppMessage>> getThreadReplies(
    String channelId,
    String parentId,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return [];
    final response = await ch.getReplies(parentId);
    return response.messages.map(_toAppMessage).toList();
  }

  Future<void> toggleReaction(
    String channelId,
    String messageId,
    String emoji,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    final mock = channelById(channelId);
    final msg = mock?.messages.where((m) => m.id == messageId).firstOrNull;
    final alreadyReacted =
        msg?.reactions.any(
          (r) => r.emoji == emoji && r.userIds.contains(_currentUser?.id),
        ) ??
        false;

    if (alreadyReacted) {
      await _client.deleteReaction(messageId, emoji);
    } else {
      await _client.sendReaction(messageId, emoji);
    }
  }

  Future<void> togglePin(String channelId, String messageId) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    final mock = channelById(channelId);
    final msg = mock?.messages.where((m) => m.id == messageId).firstOrNull;
    if (msg == null) return;

    if (msg.isPinned) {
      await ch.unpinMessage(Message(id: messageId));
    } else {
      await ch.pinMessage(Message(id: messageId));
    }
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    await _client.deleteMessage(messageId);
  }

  Future<void> editMessage(
    String channelId,
    String messageId,
    String newText,
  ) async {
    await _client.updateMessage(Message(id: messageId, text: newText));
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  void markNotificationRead(String notifId) {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx >= 0) {
      final old = _notifications[idx];
      _notifications[idx] = AppNotification(
        id: old.id,
        fromUserId: old.fromUserId,
        channelId: old.channelId,
        messageId: old.messageId,
        text: old.text,
        createdAt: old.createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      final old = _notifications[i];
      _notifications[i] = AppNotification(
        id: old.id,
        fromUserId: old.fromUserId,
        channelId: old.channelId,
        messageId: old.messageId,
        text: old.text,
        createdAt: old.createdAt,
        isRead: true,
      );
    }
    notifyListeners();
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client.queryUsers(
        filter: Filter.or([
          Filter.autoComplete('name', query),
          Filter.autoComplete('id', query),
        ]),
        sort: [SortOption.asc('name')],
        pagination: const PaginationParams(limit: 20),
      );
      for (final u in response.users) {
        _cachedUsers[u.id] = _toAppUser(u);
      }
      return response.users
          .where((u) => u.id != _currentUser?.id)
          .map(_toAppUser)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<({AppMessage message, AppChannel channel})>> searchMessages(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client.search(
        Filter.in_('members', [_currentUser!.id]),
        query: query,
        sort: [SortOption.desc('created_at')],
        paginationParams: const PaginationParams(limit: 25),
      );

      final results = <({AppMessage message, AppChannel channel})>[];
      for (final r in response.results) {
        final streamMsg = r.message;
        final channelId = r.channel?.id ?? '';
        final mock = channelById(channelId);
        if (mock == null) continue;
        results.add((message: _toAppMessage(streamMsg), channel: mock));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ─── User profile ─────────────────────────────────────────────────────────

  Future<void> updateUserInfo(String newName, String newEmail) async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;

    await _client.updateUser(
      User(
        id: userId,
        name: newName,
        image: _currentUser!.avatarUrl.isNotEmpty
            ? _currentUser!.avatarUrl
            : null,
        extraData: const {},
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == userId) {
        users[i] = {...users[i], 'name': newName, 'email': newEmail};
        break;
      }
    }
    await prefs.setString('sc_users', jsonEncode(users));

    _currentUser = AppUser(
      id: userId,
      name: newName,
      email: newEmail,
      avatarUrl: _currentUser!.avatarUrl,
      isOnline: true,
    );
    _cachedUsers[userId] = _currentUser!;
    notifyListeners();
  }

  Future<void> updateUserAvatar(String avatarUrl) async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;

    await _client.updateUser(
      User(
        id: userId,
        name: _currentUser!.name,
        image: avatarUrl.isNotEmpty ? avatarUrl : null,
        extraData: const {},
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == userId) {
        users[i] = {...users[i], 'avatar_url': avatarUrl};
        break;
      }
    }
    await prefs.setString('sc_users', jsonEncode(users));

    _currentUser = AppUser(
      id: userId,
      name: _currentUser!.name,
      email: _currentUser!.email,
      avatarUrl: avatarUrl,
      isOnline: true,
    );
    _cachedUsers[userId] = _currentUser!;
    notifyListeners();
  }

  // ─── Converters ───────────────────────────────────────────────────────────

  void _cacheMembers(Channel ch) {
    for (final m in ch.state?.members ?? <Member>[]) {
      final u = m.user;
      if (u != null) _cachedUsers[u.id] = _toAppUser(u);
    }
  }

  AppUser _toAppUser(User u) => AppUser(
    id: u.id,
    name: u.name,
    email: (u.extraData['email'] as String?) ?? '',
    avatarUrl: u.image ?? '',
    isOnline: u.online,
  );

  AppChannel _toAppChannel(Channel ch) {
    final state = ch.state;
    final isGroup = (ch.extraData['is_group'] as bool?) ?? false;
    final memberIds = (state?.members ?? <Member>[])
        .map((m) => m.userId ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    String name;
    if (!isGroup && _currentUser != null) {
      final otherId = memberIds.firstWhere(
        (id) => id != _currentUser!.id,
        orElse: () => '',
      );
      name =
          _cachedUsers[otherId]?.name ??
          (ch.extraData['name'] as String?) ??
          ch.name ??
          'DM';
    } else {
      name = (ch.extraData['name'] as String?) ?? ch.name ?? 'Group';
    }

    final messages = (state?.messages ?? <Message>[])
        .where((m) => m.parentId == null)
        .map(_toAppMessage)
        .toList();

    return AppChannel(
      id: ch.id!,
      name: name,
      isGroup: isGroup,
      memberIds: memberIds,
      messages: messages,
      unreadCount: state?.unreadCount ?? 0,
    );
  }

  AppMessage _toAppMessage(Message m) {
    final isDeleted = m.deletedAt != null || m.type == 'deleted';
    final text = m.text ?? '';
    final wasEdited =
        m.updatedAt.difference(m.createdAt).inSeconds > 3 && text.isNotEmpty;

    final reactions = _groupReactions(m.latestReactions ?? []);

    final attachments = m.attachments.map((a) {
      final url = a.assetUrl ?? a.imageUrl ?? a.thumbUrl ?? '';
      return AppAttachment(
        type: a.type ?? 'file',
        name: a.title ?? 'file',
        url: url,
      );
    }).toList();

    final replyPlaceholders = List<AppMessage>.generate(
      m.replyCount ?? 0,
      (i) => AppMessage(
        id: '__placeholder_$i',
        senderId: '',
        text: '',
        createdAt: m.createdAt,
      ),
    );

    return AppMessage(
      id: m.id,
      senderId: m.user?.id ?? '',
      text: text,
      createdAt: m.createdAt,
      isPinned: m.pinned,
      isRead: false,
      reactions: reactions,
      threadReplies: replyPlaceholders,
      attachments: attachments,
      isDeleted: isDeleted,
      editedText: wasEdited ? text : null,
    );
  }

  List<AppReaction> _groupReactions(List<Reaction> reactions) {
    final grouped = <String, List<String>>{};
    for (final r in reactions) {
      grouped.putIfAbsent(r.type, () => []).add(r.userId ?? '');
    }
    return grouped.entries
        .map((e) => AppReaction(emoji: e.key, userIds: e.value))
        .toList();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _client.dispose();
    super.dispose();
  }
}
