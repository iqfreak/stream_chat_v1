import 'package:flutter/material.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class MockUser {
  final String id;
  String name;
  String email;
  String avatarUrl;
  bool isOnline;

  MockUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
  });
}

class MockReaction {
  final String emoji;
  final List<String> userIds;

  MockReaction({required this.emoji, required this.userIds});

  MockReaction copyWith({List<String>? userIds}) =>
      MockReaction(emoji: emoji, userIds: userIds ?? this.userIds);
}

class MockMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  bool isPinned;
  bool isRead;
  List<MockReaction> reactions;
  List<MockMessage> threadReplies;
  List<MockAttachment> attachments;
  bool isDeleted;
  String? editedText;

  MockMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isPinned = false,
    this.isRead = false,
    this.reactions = const [],
    this.threadReplies = const [],
    this.attachments = const [],
    this.isDeleted = false,
    this.editedText,
  });

  /// Returns the edited text if available, then the raw text.
  /// If the message has no text but has image attachments, returns '📷 Photo'.
  /// If there are other file attachments, returns '📎 File'.
  String get displayText {
    final base = editedText ?? text;
    if (base.isNotEmpty) return base;
    final hasImage = attachments.any((a) => a.type == 'image');
    if (hasImage) return '📷 Photo';
    final hasFile = attachments.isNotEmpty;
    if (hasFile) return '📎 File';
    return '';
  }
}

class MockAttachment {
  final String type; // 'image' | 'video' | 'file'
  final String name;
  final String url;

  const MockAttachment({
    required this.type,
    required this.name,
    required this.url,
  });
}

class MockChannel {
  final String id;
  String name;
  final bool isGroup;
  final List<String> memberIds;
  List<MockMessage> messages;
  int unreadCount;
  String? avatarUrl;
  String? groupImageUrl;

  MockChannel({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.memberIds,
    required this.messages,
    this.unreadCount = 0,
    this.avatarUrl,
    this.groupImageUrl,
  });

  MockMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

class MockNotification {
  final String id;
  final String fromUserId;
  final String channelId;
  final String messageId;
  final String text;
  final DateTime createdAt;
  bool isRead;

  MockNotification({
    required this.id,
    required this.fromUserId,
    required this.channelId,
    required this.messageId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });
}

// ─── Data Layer ───────────────────────────────────────────────────────────────

class MockDataService extends ChangeNotifier {
  // Current logged-in user.
  // `late` is required because _allUsers is now an instance field (not static),
  // so it cannot be referenced in a non-late field initialiser at the class level.
  late MockUser _currentUser = _allUsers[0];
  MockUser get currentUser => _currentUser;

  void setCurrentUser(MockUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateUserInfo(String newName, String newEmail) {
    _currentUser.name = newName;
    _currentUser.email = newEmail;
    notifyListeners();
  }

  /// Updates the current user's avatar URL (local file path or network URL).
  void updateUserAvatar(String avatarUrl) {
    _currentUser.avatarUrl = avatarUrl;
    notifyListeners();
  }

  // All users — instance field (not static) so each MockDataService instance
  // owns its own list and registered users don't bleed across instances.
  final List<MockUser> _allUsers = [
    MockUser(
      id: 'user_1',
      name: 'Alex Chen',
      email: 'alex@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      isOnline: true,
    ),
    MockUser(
      id: 'user_2',
      name: 'Sarah Johnson',
      email: 'sarah@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      isOnline: true,
    ),
    MockUser(
      id: 'user_3',
      name: 'Mike Williams',
      email: 'mike@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      isOnline: false,
    ),
    MockUser(
      id: 'user_4',
      name: 'Emma Davis',
      email: 'emma@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      isOnline: true,
    ),
    MockUser(
      id: 'user_5',
      name: 'James Wilson',
      email: 'james@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      isOnline: false,
    ),
    MockUser(
      id: 'user_6',
      name: 'Olivia Brown',
      email: 'olivia@streamchat.io',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      isOnline: true,
    ),
  ];

  List<MockUser> get allUsers => List.unmodifiable(_allUsers);

  List<MockUser> get otherUsers =>
      _allUsers.where((u) => u.id != _currentUser.id).toList();

  MockUser? userById(String id) {
    try {
      return _allUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // Channels
  late final List<MockChannel> _channels = _buildInitialChannels();

  List<MockChannel> get channels => _channels;

  MockChannel? channelById(String id) {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<MockChannel> _buildInitialChannels() {
    final now = DateTime.now();
    return [
      MockChannel(
        id: 'ch_1',
        name: 'Sarah Johnson',
        isGroup: false,
        memberIds: ['user_1', 'user_2'],
        unreadCount: 3,
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        messages: [
          MockMessage(
            id: 'm_1_1',
            senderId: 'user_2',
            text: 'Hey! Did you see the latest design updates?',
            createdAt: now.subtract(const Duration(hours: 2)),
            isRead: true,
          ),
          MockMessage(
            id: 'm_1_2',
            senderId: 'user_1',
            text: 'Yeah, they look amazing! Love the new color palette.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 55)),
            isRead: true,
            reactions: [
              MockReaction(emoji: '👍', userIds: ['user_2']),
            ],
          ),
          MockMessage(
            id: 'm_1_3',
            senderId: 'user_2',
            text: 'We should schedule a call to review everything together.',
            createdAt: now.subtract(const Duration(minutes: 30)),
            isRead: false,
          ),
          MockMessage(
            id: 'm_1_4',
            senderId: 'user_2',
            text: 'How does Thursday at 3pm sound?',
            createdAt: now.subtract(const Duration(minutes: 20)),
            isRead: false,
          ),
          MockMessage(
            id: 'm_1_5',
            senderId: 'user_2',
            text: '@Alex Chen can you confirm?',
            createdAt: now.subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
        ],
      ),
      MockChannel(
        id: 'ch_2',
        name: 'Design Team',
        isGroup: true,
        memberIds: ['user_1', 'user_2', 'user_3', 'user_4'],
        unreadCount: 1,
        messages: [
          MockMessage(
            id: 'm_2_1',
            senderId: 'user_3',
            text: 'Good morning team! Ready for the sprint review?',
            createdAt: now.subtract(const Duration(hours: 3)),
            isRead: true,
          ),
          MockMessage(
            id: 'm_2_2',
            senderId: 'user_4',
            text: 'Absolutely! I\'ve prepared the slide deck.',
            createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
            isRead: true,
            reactions: [
              MockReaction(emoji: '🎉', userIds: ['user_1', 'user_2']),
              MockReaction(emoji: '👏', userIds: ['user_3']),
            ],
            isPinned: true,
          ),
          MockMessage(
            id: 'm_2_3',
            senderId: 'user_2',
            text: 'The new chat UI mockups are ready for review.',
            createdAt: now.subtract(const Duration(hours: 1)),
            isRead: true,
            threadReplies: [
              MockMessage(
                id: 'm_2_3_r1',
                senderId: 'user_1',
                text: 'These look great! One small tweak on the bubble radius.',
                createdAt: now.subtract(const Duration(minutes: 50)),
                isRead: true,
              ),
              MockMessage(
                id: 'm_2_3_r2',
                senderId: 'user_4',
                text: 'Agreed. Also check spacing on mobile.',
                createdAt: now.subtract(const Duration(minutes: 45)),
                isRead: true,
              ),
            ],
          ),
          MockMessage(
            id: 'm_2_4',
            senderId: 'user_3',
            text: 'Shipping the final build tonight! 🚀',
            createdAt: now.subtract(const Duration(minutes: 10)),
            isRead: false,
          ),
        ],
      ),
      MockChannel(
        id: 'ch_3',
        name: 'Mike Williams',
        isGroup: false,
        memberIds: ['user_1', 'user_3'],
        unreadCount: 0,
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        messages: [
          MockMessage(
            id: 'm_3_1',
            senderId: 'user_1',
            text: 'Hey Mike, can you review my PR?',
            createdAt: now.subtract(const Duration(days: 1)),
            isRead: true,
          ),
          MockMessage(
            id: 'm_3_2',
            senderId: 'user_3',
            text: 'Sure! Give me an hour.',
            createdAt: now.subtract(const Duration(days: 1, minutes: -30)),
            isRead: true,
            reactions: [
              MockReaction(emoji: '🙏', userIds: ['user_1']),
            ],
          ),
          MockMessage(
            id: 'm_3_3',
            senderId: 'user_3',
            text: 'PR looks good! Left some minor comments.',
            createdAt: now.subtract(const Duration(hours: 20)),
            isRead: true,
          ),
        ],
      ),
      MockChannel(
        id: 'ch_4',
        name: 'Product Squad',
        isGroup: true,
        memberIds: ['user_1', 'user_2', 'user_5', 'user_6'],
        unreadCount: 0,
        messages: [
          MockMessage(
            id: 'm_4_1',
            senderId: 'user_5',
            text: 'Q3 roadmap is finalized. Check the Notion doc.',
            createdAt: now.subtract(const Duration(days: 2)),
            isRead: true,
          ),
          MockMessage(
            id: 'm_4_2',
            senderId: 'user_6',
            text: 'Great work everyone! The new features look solid.',
            createdAt: now.subtract(const Duration(days: 2, minutes: -20)),
            isRead: true,
            reactions: [
              MockReaction(emoji: '🎉', userIds: ['user_1', 'user_5']),
            ],
          ),
        ],
      ),
      MockChannel(
        id: 'ch_5',
        name: 'Emma Davis',
        isGroup: false,
        memberIds: ['user_1', 'user_4'],
        unreadCount: 0,
        avatarUrl: 'https://i.pravatar.cc/150?img=9',
        messages: [
          MockMessage(
            id: 'm_5_1',
            senderId: 'user_4',
            text: 'Hey! Did you get a chance to look at the new designs?',
            createdAt: now.subtract(const Duration(days: 2)),
            isRead: true,
          ),
          MockMessage(
            id: 'm_5_2',
            senderId: 'user_1',
            text: 'Of course! Looking forward to the final version.',
            createdAt: now.subtract(const Duration(days: 2, minutes: -10)),
            isRead: true,
          ),
        ],
      ),
    ];
  }

  void addChannel(MockChannel channel) {
    _channels.insert(0, channel);
    notifyListeners();
  }

  /// Removes a channel entirely (used for delete-chat on DMs).
  void deleteChannel(String channelId) {
    _channels.removeWhere((c) => c.id == channelId);
    notifyListeners();
  }

  /// Removes the current user from a group channel.
  /// If the current user was the last member, the channel is also deleted
  /// so it doesn't linger as an orphan with 0 members.
  void leaveChannel(String channelId) {
    final ch = channelById(channelId);
    if (ch == null) return;
    ch.memberIds.remove(_currentUser.id);
    // Auto-clean orphan channels (no members left)
    if (ch.memberIds.isEmpty) {
      _channels.remove(ch);
    }
    notifyListeners();
  }

  /// Clears the unread badge for a channel (call when opening the chat).
  void markChannelRead(String channelId) {
    final ch = channelById(channelId);
    if (ch == null) return;
    ch.unreadCount = 0;
    notifyListeners();
  }

  void sendMessage(String channelId, String text) {
    final ch = channelById(channelId);
    if (ch == null) return;
    // Guard: only members can send messages
    if (!ch.memberIds.contains(_currentUser.id)) return;
    final msg = MockMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      text: text,
      createdAt: DateTime.now(),
    );
    ch.messages.add(msg);
    // Increment unread for other members
    ch.unreadCount = 0;
    notifyListeners();
  }

  void sendMessageWithAttachment(
      String channelId, String text, List<MockAttachment> attachments) {
    final ch = channelById(channelId);
    if (ch == null) return;
    // Guard: only members can send
    if (!ch.memberIds.contains(_currentUser.id)) return;
    final msg = MockMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      text: text,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    ch.messages.add(msg);
    ch.unreadCount = 0;
    notifyListeners();
  }

  void sendThreadReply(String channelId, String messageId, String text) {
    final ch = channelById(channelId);
    if (ch == null) return;
    // Guard: only members can reply in threads
    if (!ch.memberIds.contains(_currentUser.id)) return;
    final tIdx = ch.messages.indexWhere((m) => m.id == messageId);
    if (tIdx == -1) return;
    final msg = ch.messages[tIdx];
    final reply = MockMessage(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      text: text,
      createdAt: DateTime.now(),
    );
    msg.threadReplies = [...msg.threadReplies, reply];
    notifyListeners();
  }

  void toggleReaction(String channelId, String messageId, String emoji) {
    final ch = channelById(channelId);
    if (ch == null) return;
    final rIdx = ch.messages.indexWhere((m) => m.id == messageId);
    if (rIdx == -1) return;
    final msg = ch.messages[rIdx];
    final uid = _currentUser.id;
    final existing = msg.reactions.where((r) => r.emoji == emoji).toList();
    if (existing.isEmpty) {
      msg.reactions = [
        ...msg.reactions,
        MockReaction(emoji: emoji, userIds: [uid]),
      ];
    } else {
      final r = existing.first;
      if (r.userIds.contains(uid)) {
        final newIds = r.userIds.where((id) => id != uid).toList();
        if (newIds.isEmpty) {
          msg.reactions = msg.reactions.where((r) => r.emoji != emoji).toList();
        } else {
          msg.reactions = msg.reactions.map((react) {
            if (react.emoji == emoji) {
              return react.copyWith(userIds: newIds);
            }
            return react;
          }).toList();
        }
      } else {
        msg.reactions = msg.reactions.map((react) {
          if (react.emoji == emoji) {
            return react.copyWith(userIds: [...react.userIds, uid]);
          }
          return react;
        }).toList();
      }
    }
    notifyListeners();
  }

  void togglePin(String channelId, String messageId) {
    final ch = channelById(channelId);
    if (ch == null) return;
    final idx = ch.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = ch.messages[idx];
    msg.isPinned = !msg.isPinned;
    notifyListeners();
  }

  void deleteMessage(String channelId, String messageId) {
    final ch = channelById(channelId);
    if (ch == null) return;
    final idx = ch.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = ch.messages[idx];
    msg.isDeleted = true;
    notifyListeners();
  }

  void editMessage(String channelId, String messageId, String newText) {
    final ch = channelById(channelId);
    if (ch == null) return;
    final idx = ch.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = ch.messages[idx];
    msg.editedText = newText;
    notifyListeners();
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  List<({MockMessage message, MockChannel channel})> searchMessages(
    String query,
  ) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <({MockMessage message, MockChannel channel})>[];
    for (final ch in _channels) {
      for (final msg in ch.messages) {
        if (!msg.isDeleted && msg.displayText.toLowerCase().contains(q)) {
          results.add((message: msg, channel: ch));
        }
      }
    }
    return results;
  }

  // ── Fake login / register ───────────────────────────────────────────────────

  bool login(String email, String password) {
    try {
      final user = _allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Registers a new user. If [avatarPath] is provided (local file path from
  /// image_picker), it is used as the avatar; otherwise a default avatar is used.
  void register(String name, String email, {String? avatarPath}) {
    final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
        ? avatarPath
        : 'https://i.pravatar.cc/150?img=33';
    final newUser = MockUser(
      id: 'user_new_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      isOnline: true,
    );
    _allUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();
  }

  void logout() {
    // Remove any dynamically-registered users so they don't accumulate
    // across sessions and don't appear in the contact list after sign-out.
    _allUsers.removeWhere((u) => u.id.startsWith('user_new_'));
    _currentUser = _allUsers[0];
    notifyListeners();
  }

  // ── Channel list filtered by current user ───────────────────────────────────
  List<MockChannel> get myChannels =>
      _channels.where((c) => c.memberIds.contains(_currentUser.id)).toList();

  // ── Notifications ───────────────────────────────────────────────────────────

  final List<MockNotification> _notifications = _buildInitialNotifications();

  List<MockNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  static List<MockNotification> _buildInitialNotifications() {
    final now = DateTime.now();
    return [
      MockNotification(
        id: 'notif_1',
        fromUserId: 'user_2',
        channelId: 'ch_1',
        messageId: 'm_1_5',
        text: '@Alex Chen can you confirm?',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      MockNotification(
        id: 'notif_2',
        fromUserId: 'user_3',
        channelId: 'ch_2',
        messageId: 'm_2_4',
        text: 'Shipping the final build tonight! 🚀',
        createdAt: now.subtract(const Duration(minutes: 10)),
        isRead: false,
      ),
      MockNotification(
        id: 'notif_3',
        fromUserId: 'user_4',
        channelId: 'ch_2',
        messageId: 'm_2_2',
        text: 'Absolutely! I\'ve prepared the slide deck.',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        isRead: true,
      ),
    ];
  }

  void markNotificationRead(String notifId) {
    try {
      final n = _notifications.firstWhere((n) => n.id == notifId);
      n.isRead = true;
      notifyListeners();
    } catch (_) {}
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addMemberToChannel(String channelId, String userId) {
    final ch = channelById(channelId);
    if (ch == null) return;
    if (!ch.memberIds.contains(userId)) {
      ch.memberIds.add(userId);
      notifyListeners();
    }
  }

  void updateChannelName(String channelId, String newName) {
    final ch = channelById(channelId);
    if (ch == null) return;
    ch.name = newName;
    notifyListeners();
  }
}
