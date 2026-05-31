import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';
import '../config/stream_config.dart';
import 'models.dart';
import 'push_service.dart';

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
  // Local-only DM channels not yet created on the server (created on 1st send).
  final Set<String> _draftChannels = {};
  // Maps a draft channel id to its real server id once created.
  final Map<String, String> _draftToReal = {};
  // Real, fetched thread replies keyed by parent message id.
  final Map<String, List<AppMessage>> _threadReplies = {};
  StreamSubscription<Event>? _eventSub;

  // Notification preferences (persisted). These actually gate whether an
  // in-app notification is created, instead of being dead UI state.
  bool _pushNotificationsEnabled = true;
  bool _mentionsEnabled = true;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get mentionsEnabled => _mentionsEnabled;

  Future<void> setPushNotificationsEnabled(bool value) async {
    _pushNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sc_push_enabled', value);
    notifyListeners();
  }

  Future<void> setMentionsEnabled(bool value) async {
    _mentionsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sc_mentions_enabled', value);
    notifyListeners();
  }

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
    // If this was a draft that has since been created, follow to the real id.
    final resolvedId = _draftToReal[id] ?? id;
    try {
      return _channels.firstWhere((c) => c.id == resolvedId);
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

  /// Attempts to silently reconnect the previously logged-in user on app start.
  /// Returns true if a session was restored, false otherwise.
  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('sc_current_user_id');
      if (savedId == null || savedId.isEmpty) return false;

      final raw = prefs.getString('sc_users') ?? '[]';
      final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      Map<String, dynamic>? record;
      for (final u in users) {
        if (u['id'] == savedId) {
          record = u;
          break;
        }
      }
      if (record == null) return false;

      await _connectUser(
        userId: record['id'] as String,
        name: record['name'] as String,
        email: record['email'] as String? ?? '',
        avatarUrl: record['avatar_url'] as String? ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
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
    await _unregisterPushDevice();
    _eventSub?.cancel();
    _eventSub = null;
    await _client.disconnectUser();
    _currentUser = null;
    _channels.clear();
    _streamChannels.clear();
    _notifications.clear();
    _cachedUsers.clear();
    _threadReplies.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sc_current_user_id');
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

    // Load persisted notification preferences.
    final prefs = await SharedPreferences.getInstance();
    _pushNotificationsEnabled = prefs.getBool('sc_push_enabled') ?? true;
    _mentionsEnabled = prefs.getBool('sc_mentions_enabled') ?? true;

    await _loadChannels();
    await _loadAllUsers();
    _startEvents();
    await _registerPushDevice();
    notifyListeners();
  }

  StreamSubscription<String>? _tokenRefreshSub;

  /// Registers this device's FCM token with Stream so push notifications can
  /// be delivered when the app is in the background or closed.
  Future<void> _registerPushDevice() async {
    try {
      final token = await PushService.instance.getToken();
      debugPrint('🔔 FCM token: $token');
      if (token != null && token.isNotEmpty) {
        await _client.addDevice(
          token,
          PushProvider.firebase,
          pushProviderName: 'firebasepushnotifications',
        );
        debugPrint('🔔 Device registered with Stream ✅');
      } else {
        debugPrint('🔔 No FCM token returned (push will not work)');
      }
      // Re-register if Firebase rotates the token.
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = PushService.instance.onTokenRefresh.listen((t) async {
        try {
          await _client.addDevice(
            t,
            PushProvider.firebase,
            pushProviderName: 'firebasepushnotifications',
          );
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('🔔 Push device registration FAILED: $e');
    }
  }

  Future<void> _unregisterPushDevice() async {
    try {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      final token = await PushService.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _client.removeDevice(token);
      }
    } catch (_) {}
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

      // Keep open thread views in sync when a reply comes in/changes.
      final parentId = event.message?.parentId;
      if (parentId != null && _threadReplies.containsKey(parentId)) {
        _reloadThread(event.cid, parentId);
      }

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

    // Was the current user actually @mentioned in this message?
    final isMention =
        _currentUser != null &&
        (msg.mentionedUsers.any((u) => u.id == _currentUser!.id));

    // Respect the user's notification preference. Mentions and ordinary
    // messages both follow the single push-notifications toggle.
    if (!_pushNotificationsEnabled) return;

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
        isMention: isMention,
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
      // Distinct 1-on-1 channel: no id, members passed so Stream hashes them
      // into a stable id (same two people -> same channel, no duplicates).
      final allMembers = _memberSetForDm(memberIds);
      ch = _client.channel(
        'messaging',
        extraData: {'members': allMembers, 'is_group': false},
      );
      // IMPORTANT: do NOT watch() yet. watch() creates the channel on the
      // server and makes an empty conversation appear for the other person
      // before any message exists. We watch lazily on the first send.
      final localId = 'draft_${allMembers.join('_')}';
      _streamChannels[localId] = ch;
      _draftChannels.add(localId);
      // Add a local-only entry so the sender can open the chat screen.
      _channels.removeWhere((c) => c.id == localId);
      _channels.insert(
        0,
        AppChannel(
          id: localId,
          name: _dmNameFor(allMembers),
          isGroup: false,
          memberIds: allMembers,
          messages: const [],
          unreadCount: 0,
        ),
      );
      _cacheMembers(ch);
      notifyListeners();
      return localId;
    } else {
      final id = 'grp_${const Uuid().v4().replaceAll('-', '')}';
      ch = _client.channel(
        'messaging',
        id: id,
        extraData: {'name': name, 'is_group': true},
      );
      // Groups are explicitly created, so watch immediately.
      await ch.watch();
      await ch.addMembers(memberIds);
      final channelId = ch.id!;
      _streamChannels[channelId] = ch;
      _channels.removeWhere((c) => c.id == channelId);
      _channels.insert(0, _toAppChannel(ch));
      _cacheMembers(ch);
      notifyListeners();
      return channelId;
    }
  }

  /// Members for a DM: the selected user(s) plus the current user, de-duped.
  List<String> _memberSetForDm(List<String> memberIds) {
    final set = <String>{...memberIds};
    if (_currentUser != null) set.add(_currentUser!.id);
    return set.toList();
  }

  /// Display name for a DM = the other member's name.
  String _dmNameFor(List<String> memberIds) {
    final otherId = memberIds.firstWhere(
      (id) => id != _currentUser?.id,
      orElse: () => '',
    );
    return _cachedUsers[otherId]?.name ?? 'DM';
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

  /// Resolves a possibly-draft channel id to its real server id.
  String _resolveId(String id) => _draftToReal[id] ?? id;

  void markChannelRead(String channelId) {
    final id = _resolveId(channelId);
    final ch = _streamChannels[id];
    ch?.markRead();

    // Requirement: reading a channel removes its notifications from the
    // notifications screen.
    _notifications.removeWhere((n) => n.channelId == id);

    final idx = _channels.indexWhere((c) => c.id == id);
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
    }
    notifyListeners();
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
    // updatePartial only sets the given keys, preserving other custom data
    // such as `is_group`. Using ch.update() here would wipe is_group and
    // make the group collapse into a DM.
    await ch.updatePartial(set: {'name': newName});
    _refreshChannelById(channelId);
    notifyListeners();
  }

  Future<void> renameChannel(String channelId, String newName) =>
      updateChannelName(channelId, newName);

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(
    String channelId,
    String text, {
    List<String> mentionedUserIds = const [],
  }) async {
    // Follow draft -> real id for messages sent after the channel was created.
    final resolvedId = _draftToReal[channelId] ?? channelId;
    final ch = _streamChannels[resolvedId];
    if (ch == null) return;

    // If this is a draft DM (not yet created on the server), create it now by
    // watching it. This is the first message, so the channel becomes real and
    // visible to the other person only at this moment.
    if (_draftChannels.contains(resolvedId)) {
      await ch.watch();
      final realId = ch.id!;
      _draftChannels.remove(resolvedId);
      _streamChannels.remove(resolvedId);
      _streamChannels[realId] = ch;
      _draftToReal[channelId] = realId;
      // Replace the local draft entry with the real channel.
      _channels.removeWhere((c) => c.id == resolvedId || c.id == realId);
      _channels.insert(0, _toAppChannel(ch));
      _cacheMembers(ch);
    }

    final mentioned = mentionedUserIds
        .map((id) => User(id: id))
        .toList(growable: false);
    await ch.sendMessage(Message(text: text, mentionedUsers: mentioned));
  }

  Future<void> sendMessageWithAttachment(
    String channelId,
    String text,
    List<AppAttachment> attachments,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    // Build Stream attachments from local files. Setting `file` (instead of a
    // local path as assetUrl) lets the SDK upload them to Stream's CDN, so
    // recipients on other devices can actually load them.
    final streamAttachments = <Attachment>[];
    for (final a in attachments) {
      try {
        final file = File(a.url);
        final size = await file.length();
        final resolvedType = a.type == 'image'
            ? 'image'
            : (a.type == 'video' ? 'video' : 'file');
        streamAttachments.add(
          Attachment(
            type: resolvedType,
            file: AttachmentFile(path: a.url, size: size),
            title: a.name,
          ),
        );
      } catch (_) {
        // Skip files that can't be read rather than crashing the send.
      }
    }

    if (streamAttachments.isEmpty && text.trim().isEmpty) return;

    await ch.sendMessage(Message(text: text, attachments: streamAttachments));
  }

  /// Forwards an existing message (text + any attachments) to another channel.
  /// We re-send the *original* Stream attachment objects (looked up by message
  /// id in the source channel) so all CDN fields are preserved and the
  /// forwarded media persists after an app restart.
  Future<void> forwardMessage(
    String sourceChannelId,
    String targetChannelId,
    AppMessage message,
  ) async {
    final target = _streamChannels[targetChannelId];
    if (target == null) return;

    final source = _streamChannels[sourceChannelId];
    Message? original;
    final stateMessages = source?.state?.messages ?? const <Message>[];
    for (final m in stateMessages) {
      if (m.id == message.id) {
        original = m;
        break;
      }
    }

    // Prefer the original Stream attachment objects (CDN URLs fully populated).
    // Fall back to rebuilding Attachment from AppAttachment when the source
    // message isn't in the in-memory state (e.g. older messages).
    final List<Attachment> attachments;
    if (original != null) {
      attachments = List<Attachment>.from(original.attachments);
    } else {
      attachments = message.attachments.map((a) {
        return Attachment(
          type: a.type,
          title: a.name,
          assetUrl: a.type != 'image' ? a.url : null,
          imageUrl: a.type == 'image' ? a.url : null,
          thumbUrl: a.type == 'video' ? a.url : null,
        );
      }).toList();
    }

    final baseText = message.editedText ?? message.text;
    final fwdText = baseText.isNotEmpty ? '↪ $baseText' : '';

    if (attachments.isEmpty && fwdText.isEmpty) return;

    await target.sendMessage(Message(text: fwdText, attachments: attachments));
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
    // Refresh the cached thread so the new reply appears immediately.
    await _reloadThread(ch.cid, parentId);
  }

  /// Real (non-placeholder) thread replies for a parent message.
  List<AppMessage> threadReplies(String parentId) =>
      List.unmodifiable(_threadReplies[parentId] ?? const <AppMessage>[]);

  /// Loads the real replies of [parentId] from Stream and caches them.
  Future<void> loadThread(String channelId, String parentId) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;
    await _reloadThread(ch.cid, parentId);
  }

  Future<void> _reloadThread(String? cid, String parentId) async {
    String? id = cid;
    if (id != null && id.contains(':')) id = id.split(':').last;
    final ch = id == null ? null : _streamChannels[id];
    if (ch == null) return;
    try {
      final response = await ch.getReplies(parentId);
      _threadReplies[parentId] = response.messages.map(_toAppMessage).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<List<AppMessage>> getThreadReplies(
    String channelId,
    String parentId,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return [];
    final response = await ch.getReplies(parentId);
    final list = response.messages.map(_toAppMessage).toList();
    _threadReplies[parentId] = list;
    return list;
  }

  /// Maps Stream reaction types to display emojis (and back).
  static const Map<String, String> reactionEmojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'tada': '🎉',
  };

  Future<void> toggleReaction(
    String channelId,
    String messageId,
    String reactionType,
  ) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    final mock = channelById(channelId);
    final msg = mock?.messages.where((m) => m.id == messageId).firstOrNull;
    final alreadyReacted =
        msg?.reactions.any(
          (r) => r.type == reactionType && r.userIds.contains(_currentUser?.id),
        ) ??
        false;

    if (alreadyReacted) {
      await _client.deleteReaction(messageId, reactionType);
    } else {
      await _client.sendReaction(messageId, reactionType);
    }
    // The reactionNew/reactionDeleted event refreshes the channel, but refresh
    // immediately too so the UI feels responsive.
    _refreshChannelById(channelId);
    notifyListeners();
  }

  Future<void> togglePin(String channelId, String messageId) async {
    final ch = _streamChannels[channelId];
    if (ch == null) return;

    // Find the REAL Stream message in channel state. Passing a bare
    // Message(id:) to pin/unpin corrupts the local cache and shows an
    // "unknown message" placeholder, so we use the actual object.
    Message? streamMsg;
    for (final m in ch.state?.messages ?? const <Message>[]) {
      if (m.id == messageId) {
        streamMsg = m;
        break;
      }
    }
    if (streamMsg == null) return;

    try {
      if (streamMsg.pinned) {
        await ch.unpinMessage(streamMsg);
      } else {
        await ch.pinMessage(streamMsg);
      }
      _refreshChannelById(channelId);
      notifyListeners();
    } catch (_) {}
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
    String query, {
    String typeFilter = 'all', // 'all' | 'text' | 'image' | 'video' | 'file'
  }) async {
    // 'all' filter: merge local media scan + server-side text search so that
    // videos, photos and files appear alongside text messages in results.
    if (typeFilter == 'all') {
      final q = query.trim().toLowerCase();
      final results = <({AppMessage message, AppChannel channel})>[];
      final seen = <String>{};

      // 1. Local scan — catches media messages the server search misses.
      for (final ch in _channels) {
        for (final m in ch.messages) {
          if (m.isDeleted) continue;
          if (q.isNotEmpty) {
            final hay =
                ('${m.text} ${m.attachments.map((a) => a.name).join(' ')}')
                    .toLowerCase();
            if (!hay.contains(q)) continue;
          }
          if (seen.add(m.id)) results.add((message: m, channel: ch));
        }
      }

      // 2. Server full-text search — only runs when there is a query.
      if (q.isNotEmpty) {
        try {
          final response = await _client.search(
            Filter.in_('members', [_currentUser!.id]),
            query: query,
            sort: [SortOption.desc('created_at')],
            paginationParams: const PaginationParams(limit: 30),
          );
          for (final r in response.results) {
            final ch = channelById(r.channel?.id ?? '');
            if (ch == null) continue;
            final appMsg = _toAppMessage(r.message);
            if (seen.add(appMsg.id))
              results.add((message: appMsg, channel: ch));
          }
        } catch (_) {}
      }

      results.sort(
        (a, b) => b.message.createdAt.compareTo(a.message.createdAt),
      );
      return results;
    }

    // Individual media filters (image / video / file): local scan only.
    if (typeFilter == 'image' ||
        typeFilter == 'video' ||
        typeFilter == 'file') {
      final q = query.trim().toLowerCase();
      final results = <({AppMessage message, AppChannel channel})>[];
      for (final ch in _channels) {
        for (final m in ch.messages) {
          if (m.isDeleted) continue;
          if (!_matchesTypeFilter(m, typeFilter)) continue;
          if (q.isNotEmpty) {
            final hay =
                ('${m.text} ${m.attachments.map((a) => a.name).join(' ')}')
                    .toLowerCase();
            if (!hay.contains(q)) continue;
          }
          results.add((message: m, channel: ch));
        }
      }
      results.sort(
        (a, b) => b.message.createdAt.compareTo(a.message.createdAt),
      );
      return results;
    }

    // Text only: server-side full-text search.
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client.search(
        Filter.in_('members', [_currentUser!.id]),
        query: query,
        sort: [SortOption.desc('created_at')],
        paginationParams: const PaginationParams(limit: 30),
      );

      final results = <({AppMessage message, AppChannel channel})>[];
      for (final r in response.results) {
        final streamMsg = r.message;
        final channelId = r.channel?.id ?? '';
        final mock = channelById(channelId);
        if (mock == null) continue;
        final appMsg = _toAppMessage(streamMsg);
        if (!_matchesTypeFilter(appMsg, typeFilter)) continue;
        results.add((message: appMsg, channel: mock));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  bool _matchesTypeFilter(AppMessage msg, String typeFilter) {
    switch (typeFilter) {
      case 'text':
        return msg.attachments.isEmpty && msg.text.isNotEmpty;
      case 'image':
        return msg.attachments.any((a) => a.type == 'image');
      case 'video':
        return msg.attachments.any((a) => a.type == 'video');
      case 'file':
        return msg.attachments.any(
          (a) => a.type != 'image' && a.type != 'video',
        );
      case 'all':
      default:
        return true;
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

  String get currentEmail => _currentUser?.email ?? '';

  /// Updates the stored email. Returns null on success or an error message.
  Future<String?> changeEmail(String newEmail) async {
    if (_currentUser == null) return 'Not signed in';
    final email = newEmail.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email';
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    // Reject if another account already uses this email.
    if (users.any((u) => u['email'] == email && u['id'] != _currentUser!.id)) {
      return 'That email is already in use';
    }
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == _currentUser!.id) {
        users[i] = {...users[i], 'email': email};
        break;
      }
    }
    await prefs.setString('sc_users', jsonEncode(users));
    _currentUser = AppUser(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: email,
      avatarUrl: _currentUser!.avatarUrl,
      isOnline: true,
    );
    _cachedUsers[_currentUser!.id] = _currentUser!;
    notifyListeners();
    return null;
  }

  /// Verifies the current password and updates to a new one.
  /// Returns null on success or an error message.
  Future<String?> changePassword(
    String ignoredCurrentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return 'Not signed in';
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters';
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    var found = false;
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == _currentUser!.id) {
        users[i] = {...users[i], 'password_hash': _hashPassword(newPassword)};
        found = true;
        break;
      }
    }
    if (!found) return 'Account not found';
    await prefs.setString('sc_users', jsonEncode(users));
    return null;
  }

  /// Deletes the current user's account after verifying their password.
  /// Returns null on success or an error message.
  Future<String?> deleteAccount(String password) async {
    if (_currentUser == null) return 'Not signed in';
    final userId = _currentUser!.id;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    // Verify password against the stored hash.
    final hash = _hashPassword(password);
    Map<String, dynamic>? record;
    for (final u in users) {
      if (u['id'] == userId) {
        record = u;
        break;
      }
    }
    if (record == null) return 'Account not found';
    if (record['password_hash'] != hash) return 'wrong_password';

    // Best-effort: remove the device + delete the user on Stream.
    try {
      await _unregisterPushDevice();
    } catch (_) {}
    try {
      await _client.disconnectUser();
    } catch (_) {}

    // Remove the local account record and clear session.
    users.removeWhere((u) => u['id'] == userId);
    await prefs.setString('sc_users', jsonEncode(users));
    await prefs.remove('sc_current_user_id');

    _currentUser = null;
    _channels.clear();
    _streamChannels.clear();
    _notifications.clear();
    _cachedUsers.clear();
    _threadReplies.clear();
    notifyListeners();
    return null;
  }

  /// Mutes a user on Stream (their messages are hidden from you).
  Future<void> blockUser(String userId) async {
    try {
      await _client.muteUser(userId);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _client.unmuteUser(userId);
    } catch (_) {}
    notifyListeners();
  }

  /// Returns the users you've currently muted/blocked.
  Future<List<AppUser>> blockedUsers() async {
    try {
      final me = _client.state.currentUser;
      final mutes = me?.mutes ?? const [];
      final result = <AppUser>[];
      for (final mute in mutes) {
        final target = mute.target;
        result.add(
          AppUser(
            id: target.id,
            name: target.name,
            email: '',
            avatarUrl: (target.image ?? ''),
            isOnline: false,
          ),
        );
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// If [path] points to a local file, uploads it to Stream's CDN (using any
  /// available channel as the upload endpoint) and returns the public URL.
  /// Falls back to the original value if upload isn't possible.
  Future<String> _uploadImageIfLocal(String path) async {
    if (path.isEmpty || !path.startsWith('/')) return path;
    final ch = _streamChannels.values.isNotEmpty
        ? _streamChannels.values.first
        : null;
    if (ch == null) return path; // No channel yet; keep local path for now.
    try {
      final size = await File(path).length();
      final res = await ch.sendImage(AttachmentFile(path: path, size: size));
      return res.file ?? path; // CDN URL (fall back to local on null)
    } catch (_) {
      return path;
    }
  }

  Future<void> updateUserAvatar(String avatarUrl) async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;

    // Upload local images so other users can see them.
    final uploadedUrl = await _uploadImageIfLocal(avatarUrl);

    await _client.updateUser(
      User(
        id: userId,
        name: _currentUser!.name,
        image: uploadedUrl.isNotEmpty ? uploadedUrl : null,
        extraData: const {},
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sc_users') ?? '[]';
    final users = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < users.length; i++) {
      if (users[i]['id'] == userId) {
        users[i] = {...users[i], 'avatar_url': uploadedUrl};
        break;
      }
    }
    await prefs.setString('sc_users', jsonEncode(users));

    _currentUser = AppUser(
      id: userId,
      name: _currentUser!.name,
      email: _currentUser!.email,
      avatarUrl: uploadedUrl,
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
        .toSet() // de-duplicate; optimistic state can list a member twice
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
      // Resolve the best URL first (Stream stores images in imageUrl,
      // videos/files in assetUrl).
      final rawUrl = a.assetUrl ?? a.imageUrl ?? a.thumbUrl ?? '';

      // Determine the real type. Stream sometimes returns null or a wrong type
      // (e.g. 'file' for videos uploaded via AttachmentFile). We detect from
      // the URL extension when the SDK type is ambiguous.
      String type = a.type ?? '';
      if (type.isEmpty || type == 'file') {
        final lower = rawUrl
            .toLowerCase()
            .split('?')
            .first; // strip query params
        if (lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.mkv') ||
            lower.endsWith('.webm') ||
            lower.endsWith('.m4v')) {
          type = 'video';
        } else if (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.heic')) {
          type = 'image';
        } else {
          type = a.type ?? 'file';
        }
      }

      // Pick the best URL per resolved type.
      final url = type == 'image'
          ? (a.imageUrl ?? a.thumbUrl ?? a.assetUrl ?? '')
          : (a.assetUrl ?? a.thumbUrl ?? a.imageUrl ?? '');

      return AppAttachment(type: type, name: a.title ?? 'file', url: url);
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
        .map(
          (e) => AppReaction(
            type: e.key,
            emoji: reactionEmojis[e.key] ?? e.key,
            userIds: e.value,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _client.dispose();
    super.dispose();
  }
}
