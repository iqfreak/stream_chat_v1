import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'message_action_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  const ChatScreen({super.key, required this.channelId});

  @override
  State&lt;ChatScreen&gt; createState() =&gt; _ChatScreenState();
}

class _ChatScreenState extends State&lt;ChatScreen&gt; {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final bool _showTyping = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final data = context.read&lt;MockDataService&gt;();
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

  Future&lt;void&gt; _attach() async {
    final data = context.read&lt;MockDataService&gt;();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    // Guard: non-members cannot send attachments
    if (!channel.memberIds.contains(data.currentUser.id)) {
      _showNotMemberSnackbar();
      return;
    }
    final source = await showModalBottomSheet&lt;ImageSource&gt;(
      context: context,
      builder: (_) =&gt; SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () =&gt; Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () =&gt; Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source);
    if (file == null || !mounted) return;
    context.read&lt;MockDataService&gt;().sendMessageWithAttachment(
      widget.channelId,
      '',
      [MockAttachment(type: 'image', name: file.name, url: file.path)],
    );
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showActionSheet(MockMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =&gt; MessageActionSheet(
        message: msg,
        channelId: widget.channelId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch&lt;MockDataService&gt;();
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
    final messages = channel.messages;

    String title;
    String subtitle;
    if (channel.isGroup) {
      title = channel.name;
      subtitle = '${channel.memberIds.length} members';
    } else {
      final otherId = channel.memberIds
          .firstWhere((id) =&gt; id != me.id, orElse: () =&gt; me.id);
      final other = data.userById(otherId);
      title = other?.name ?? channel.name;
      subtitle = other?.isOnline == true ? 'Online' : 'Last seen recently';
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () =&gt; context.pop()),
        title: GestureDetector(
          onTap: () =&gt; context.push('/channels/${widget.channelId}/info'),
          child: Row(
            children: [
              if (!channel.isGroup) ...[
                UserAvatar(
                  name: title,
                  avatarUrl: channel.avatarUrl,
                  size: 36,
                  showOnline: subtitle == 'Online',
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitle == 'Online'
                            ? AppColors.online
                            : isDark
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
            onPressed: () =&gt;
                context.push('/channels/${widget.channelId}/info'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-member banner
          if (channel.isGroup &amp;&amp; !isMember)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? AppColors.darkCard
                  : const Color(0xFFFFF3CD),
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
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary),
                        const SizedBox(height: 12),
                        const Text('No messages yet'),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello!',
                          style: TextStyle(
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
                        horizontal: 12, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMine = msg.senderId == me.id;
                      final sender = data.userById(msg.senderId);
                      final showAvatar = !isMine &amp;&amp;
                          (i == 0 ||
                              messages[i - 1].senderId != msg.senderId);
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        sender: sender,
                        showAvatar: showAvatar,
                        isDark: isDark,
                        channelId: widget.channelId,
                        // Bug 2 fix: never open the action sheet on deleted messages
                        onLongPress: msg.isDeleted ? null : () =&gt; _showActionSheet(msg),
                        onThreadTap: () =&gt; context.push(
                          '/channels/${widget.channelId}/chat/${msg.id}/thread',
                        ),
                      );
                    },
                  ),
          ),
          // Typing indicator
          if (_showTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Sarah is typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          // Input bar
          _InputBar(
            controller: _inputCtrl,
            onSend: _send,
            onAttach: _attach,
            isDark: isDark,
            enabled: isMember,
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ──────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isDark;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkDivider
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: enabled ? onAttach : null,
              icon: Icon(
                Icons.attach_file,
                color: enabled
                    ? (isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary)
                    : (isDark
                        ? AppColors.textDarkSecondary.withValues(alpha: 0.4)
                        : AppColors.textLightSecondary
                            .withValues(alpha: 0.4)),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      enabled ? 'Type a message...' : 'You cannot send messages here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: enabled ? (_) =&gt; onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MockMessage message;
  final bool isMine;
  final MockUser? sender;
  final bool showAvatar;
  final bool isDark;
  final String channelId;
  // Bug 2 fix: nullable so deleted messages receive null (no long-press handler)
  final VoidCallback? onLongPress;
  final VoidCallback onThreadTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.sender,
    required this.showAvatar,
    required this.isDark,
    required this.channelId,
    this.onLongPress,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted;
    final bgColor = isDeleted
        ? (isDark
            ? AppColors.darkCard.withValues(alpha: 0.5)
            : const Color(0xFFF3F4F6))
        : isMine
            ? AppColors.primary
            : (isDark ? AppColors.darkCard : Colors.white);

    final textColor = isDeleted
        ? (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
        : isMine
            ? Colors.white
            : (isDark ? AppColors.textDark : AppColors.textLight);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? UserAvatar(
                      name: sender?.name ?? '?',
                      avatarUrl: sender?.avatarUrl,
                      size: 32,
                    )
                  : const SizedBox(),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                margin: EdgeInsets.only(
                  left: isMine ? 60 : 4,
                  right: isMine ? 0 : 60,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name (group chats only, others' messages)
                    if (!isMine &amp;&amp; showAvatar &amp;&amp; sender != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sender!.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    // Deleted message
                    if (isDeleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.do_not_disturb_alt,
                              size: 14, color: textColor),
                          const SizedBox(width: 4),
                          Text(
                            'This message was deleted',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: textColor,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Image attachment
                      if (message.attachments.any((a) =&gt; a.type == 'image'))
                        _ImageAttachment(
                          attachment: message.attachments
                              .firstWhere((a) =&gt; a.type == 'image'),
                          isDark: isDark,
                        ),
                      // Bug 1 fix: use displayText instead of text
                      // so image-only messages show '📷 Photo' rather than blank.
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
                          timeago.format(message.createdAt, allowFromNow: true),
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
  final MockAttachment attachment;
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
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =&gt; _broken(isDark),
              )
            : Image.network(
                attachment.url,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =&gt; _broken(isDark),
              ),
      ),
    );
  }

  Widget _broken(bool isDark) =&gt; Container(
        width: 200,
        height: 200,
        color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
        child: Icon(Icons.broken_image_outlined,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary),
      );
}

// ─── Reactions Row ───────────────────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  final MockMessage message;
  final String channelId;
  const _ReactionsRow({required this.message, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final data = context.read&lt;MockDataService&gt;();
    final me = data.currentUser;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.map((r) {
        final reacted = r.userIds.contains(me.id);
        return GestureDetector(
          onTap: () =&gt; data.toggleReaction(channelId, message.id, r.emoji),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: reacted
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: reacted
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
