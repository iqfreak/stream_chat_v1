import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'message_action_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  const ChatScreen({super.key, required this.channelId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // Mark channel as read when the chat screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StreamChatService>().markChannelRead(widget.channelId);
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final data = context.read<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    // Guard: non-members cannot send
    if (!channel.memberIds.contains(data.currentUser.id)) {
      _showNotMemberSnackbar();
      return;
    }
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    data.sendMessage(widget.channelId, text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showNotMemberSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are not a member of this group.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _attach() async {
    final data = context.read<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    // Guard: non-members cannot send attachments
    if (!channel.memberIds.contains(data.currentUser.id)) {
      _showNotMemberSnackbar();
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source);
    if (file == null || !mounted) return;
    context.read<StreamChatService>().sendMessageWithAttachment(
      widget.channelId,
      '',
      [AppAttachment(type: 'image', name: file.name, url: file.path)],
    );
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showActionSheet(AppMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MessageActionSheet(
        message: msg,
        channelId: widget.channelId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Channel not found')),
      );
    }

    final me = data.currentUser;
    final isMember = channel.memberIds.contains(me.id);

    // For DMs, find the other user for the AppBar title & online status
    AppUser? otherUser;
    if (!channel.isGroup) {
      otherUser = channel.memberIds
          .where((id) => id != me.id)
          .map((id) => data.userById(id))
          .whereType<AppUser>()
          .firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/channels')),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.push('/channels/${widget.channelId}/info'),
          child: Row(
            children: [
              if (channel.isGroup)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.group, color: Colors.white, size: 18),
                )
              else
                UserAvatar(
                  name: otherUser?.name ?? channel.name,
                  avatarUrl: otherUser?.avatarUrl,
                  size: 36,
                  showOnline: otherUser?.isOnline ?? false,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.isGroup
                          ? channel.name
                          : (otherUser?.name ?? channel.name),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!channel.isGroup && otherUser != null)
                      Text(
                        otherUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: otherUser.isOnline
                              ? AppColors.online
                              : (isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary),
                        ),
                      )
                    else if (channel.isGroup)
                      Text(
                        '${channel.memberIds.length} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                context.push('/channels/${widget.channelId}/info'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-member warning banner
          if (channel.isGroup && !isMember)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.darkCard : const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : const Color(0xFF856404),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are not a member of this group and cannot send messages.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Message list
          Expanded(
            child: channel.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello! 👋',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: channel.messages.length,
                    itemBuilder: (context, i) {
                      final msg = channel.messages[i];
                      final isMine = msg.senderId == me.id;
                      final sender = data.userById(msg.senderId);

                      // Show sender avatar + name for the first message or
                      // after a different sender
                      final showHeader = i == 0 ||
                          channel.messages[i - 1].senderId != msg.senderId;

                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        sender: sender,
                        showHeader: showHeader,
                        isDark: isDark,
                        channelId: widget.channelId,
                        onLongPress: () => _showActionSheet(msg),
                        onThreadTap: () => context.push(
                          '/channels/${widget.channelId}/chat/${msg.id}/thread',
                        ),
                      );
                    },
                  ),
          ),
          // Input area
          _buildInputArea(context, isDark, isMember, channel.isGroup),
        ],
      ),
    );
  }

  Widget _buildInputArea(
      BuildContext context, bool isDark, bool isMember, bool isGroup) {
    // Non-members of groups see a locked bar
    if (isGroup && !isMember) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkAppBar : Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'You cannot send messages in this group.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkAppBar : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
              onPressed: _attach,
            ),
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                maxLines: 6,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AppMessage message;
  final bool isMine;
  final AppUser? sender;
  final bool showHeader;
  final bool isDark;
  final String channelId;
  final VoidCallback onLongPress;
  final VoidCallback onThreadTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.sender,
    required this.showHeader,
    required this.isDark,
    required this.channelId,
    required this.onLongPress,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? AppColors.sentBubble
        : (isDark
            ? AppColors.receivedBubbleDark
            : AppColors.receivedBubbleLight);
    final textColor = isMine
        ? Colors.white
        : (isDark ? AppColors.textDark : AppColors.textLight);

    return Padding(
      padding: EdgeInsets.only(
        top: showHeader ? 12 : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showHeader)
              UserAvatar(
                name: sender?.name ?? '?',
                avatarUrl: sender?.avatarUrl,
                size: 28,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: message.isDeleted
                      ? (isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF5F6FA))
                      : bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(isMine ? 18 : (showHeader ? 4 : 18)),
                    bottomRight:
                        Radius.circular(isMine ? (showHeader ? 4 : 18) : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader && !isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sender?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (message.isDeleted)
                      Text(
                        'This message was deleted',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      )
                    else ...[
                      // Attachments
                      ...message.attachments.map((a) => _ImageAttachment(
                            attachment: a,
                            isDark: isDark,
                          )),
                      if (message.displayText.isNotEmpty)
                        Text(
                          message.displayText,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                    ],
                    // Reactions
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _ReactionsRow(
                          message: message,
                          channelId: channelId,
                        ),
                      ),
                    // Thread replies
                    if (message.threadReplies.isNotEmpty)
                      GestureDetector(
                        onTap: onThreadTap,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.forum,
                                  size: 14,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${message.threadReplies.length} ${message.threadReplies.length == 1 ? 'reply' : 'replies'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Timestamp + edited + pinned
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 10,
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.primary),
                          ),
                        if (message.editedText != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              'edited',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isMine
                                    ? Colors.white70
                                    : (isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary),
                              ),
                            ),
                          ),
                        Text(
                          timeago.format(message.createdAt,
                              allowFromNow: true),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMine
                                ? Colors.white70
                                : (isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all
                                : Icons.check,
                            size: 12,
                            color: message.isRead
                                ? Colors.lightBlueAccent
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image Attachment ────────────────────────────────────────────────────────

class _ImageAttachment extends StatelessWidget {
  final AppAttachment attachment;
  final bool isDark;
  const _ImageAttachment({required this.attachment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLocal = attachment.url.startsWith('/') ||
        attachment.url.startsWith('file://');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isLocal
            ? Image.file(
                File(attachment.url),
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _BrokenImage(isDark: isDark),
              )
            : Image.network(
                attachment.url,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _BrokenImage(isDark: isDark),
              ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  final bool isDark;
  const _BrokenImage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
      ),
    );
  }
}

// ─── Reactions Row ───────────────────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  final AppMessage message;
  final String channelId;

  const _ReactionsRow({required this.message, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = context.read<StreamChatService>();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.map((r) {
        final mine = r.userIds.contains(data.currentUser.id);
        return GestureDetector(
          onTap: () => data.toggleReaction(channelId, message.id, r.emoji),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: mine
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark
                      ? AppColors.reactionBg
                      : Colors.grey.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
              border: mine
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5))
                  : null,
            ),
            child: Text(
              '${r.emoji} ${r.userIds.length}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
