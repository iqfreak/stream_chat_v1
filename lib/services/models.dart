// ─── Models ───────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  String name;
  String email;
  String avatarUrl;
  bool isOnline;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
  });

  /// The Stream Chat user ID is the username (e.g. "johndoe")
  String get username => id;
}

class AppReaction {
  final String type; // Stream reaction type, e.g. 'like', 'love'
  final String emoji; // Display emoji
  final List<String> userIds;

  AppReaction({required this.type, required this.emoji, required this.userIds});

  AppReaction copyWith({List<String>? userIds}) =>
      AppReaction(type: type, emoji: emoji, userIds: userIds ?? this.userIds);
}

class AppMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  bool isPinned;
  bool isRead;
  List<AppReaction> reactions;
  List<AppMessage> threadReplies;
  List<AppAttachment> attachments;
  bool isDeleted;
  String? editedText;

  AppMessage({
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

  /// The actual typed text, with no attachment placeholders.
  /// Use this to check whether the message truly has text content.
  String get pureText => editedText ?? text;

  /// Returns the edited text if available, then the raw text.
  /// If the message has no text but has attachments, returns a type emoji.
  /// Used for chat-list previews — NOT for edit/copy visibility checks.
  String get displayText {
    final base = editedText ?? text;
    if (base.isNotEmpty) return base;
    final hasVideo = attachments.any((a) => a.type == 'video');
    if (hasVideo) return '🎥 Video';
    final hasImage = attachments.any((a) => a.type == 'image');
    if (hasImage) return '📷 Photo';
    if (attachments.isNotEmpty) return '📎 File';
    return '';
  }
}

class AppAttachment {
  final String type; // 'image' | 'video' | 'file'
  final String name;
  final String url;

  const AppAttachment({
    required this.type,
    required this.name,
    required this.url,
  });
}

class AppChannel {
  final String id;
  String name;
  final bool isGroup;
  final List<String> memberIds;
  List<AppMessage> messages;
  int unreadCount;
  String? avatarUrl;
  String? groupImageUrl;

  AppChannel({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.memberIds,
    required this.messages,
    this.unreadCount = 0,
    this.avatarUrl,
    this.groupImageUrl,
  });

  AppMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

class AppNotification {
  final String id;
  final String fromUserId;
  final String channelId;
  final String messageId;
  final String text;
  final DateTime createdAt;
  bool isRead;

  /// True when the current user was @mentioned, false for a normal new message.
  final bool isMention;

  AppNotification({
    required this.id,
    required this.fromUserId,
    required this.channelId,
    required this.messageId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.isMention = false,
  });
}
