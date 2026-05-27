import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final bool _showTyping = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    context.read<MockDataService>().sendMessage(widget.channelId, text);
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

  void _showActionSheet(MockMessage msg) {
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
    final data = context.watch<MockDataService>();
    final channel = data.channelById(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Channel not found')),
      );
    }

    final me = data.currentUser;
    final messages = channel.messages;

    String title;
    String subtitle;
    if (channel.isGroup) {
      title = channel.name;
      subtitle = '${channel.memberIds.length} members';
    } else {
      final otherId = channel.memberIds
          .firstWhere((id) => id != me.id, orElse: () => me.id);
      final other = data.userById(otherId);
      title = other?.name ?? channel.name;
      subtitle = other?.isOnline == true ? 'Online' : 'Last seen recently';
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: GestureDetector(
          onTap: () => context.push('/channels/${widget.channelId}/info'),
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
            onPressed: () =>
                context.push('/channels/${widget.channelId}/info'),
          ),
        ],
      ),
      body: Column(
        children: [
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
                      final showAvatar = !isMine &&
                          (i == 0 || messages[i - 1].senderId != msg.senderId);
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        sender: sender,
                        showAvatar: showAvatar,
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
          // Typing indicator
          if (_showTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Sarah is typing...',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          // Input area
          _InputArea(
            controller: _inputCtrl,
            isDark: isDark,
            onSend: _send,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MockMessage message;
  final bool isMine;
  final MockUser? sender;
  final bool showAvatar;
  final bool isDark;
  final String channelId;
  final VoidCallback onLongPress;
  final VoidCallback onThreadTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.sender,
    required this.showAvatar,
    required this.isDark,
    required this.channelId,
    required this.onLongPress,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkDivider
                        : Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                '🚫 Message deleted',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bubbleColor = isMine
        ? AppColors.sentBubble
        : isDark
            ? AppColors.receivedBubbleDark
            : AppColors.receivedBubbleLight;

    final textColor = isMine
        ? Colors.white
        : isDark
            ? AppColors.textDark
            : AppColors.textLight;

    return Padding(
      padding: EdgeInsets.only(
        bottom: message.reactions.isNotEmpty ||
                message.threadReplies.isNotEmpty ||
                message.isPinned
            ? 2
            : 6,
        top: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Pin indicator
          if (message.isPinned)
            Padding(
              padding: EdgeInsets.only(
                left: isMine ? 0 : 52,
                right: isMine ? 0 : 0,
                bottom: 2,
              ),
              child: Row(
                mainAxisAlignment:
                    isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Icon(Icons.push_pin, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Pinned',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine)
                SizedBox(
                  width: 40,
                  child: showAvatar
                      ? UserAvatar(
                          name: sender?.name ?? '?',
                          avatarUrl: sender?.avatarUrl,
                          size: 32,
                        )
                      : null,
                ),
              GestureDetector(
                onLongPress: onLongPress,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMine && showAvatar && sender != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              sender!.name,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          message.displayText,
                          style: TextStyle(color: textColor, fontSize: 14.5),
                        ),
                        if (message.editedText != null)
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              timeago.format(message.createdAt,
                                  allowFromNow: true),
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor.withValues(alpha: 0.65),
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 14,
                                color: message.isRead
                                    ? Colors.lightBlueAccent
                                    : textColor.withValues(alpha: 0.65),
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
          // Reactions
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: isMine ? 0 : 52,
                top: 4,
                bottom: 2,
              ),
              child: Wrap(
                spacing: 6,
                children: message.reactions.map((r) {
                  final data = context.read<MockDataService>();
                  final myId = data.currentUser.id;
                  final iReacted = r.userIds.contains(myId);
                  return GestureDetector(
                    onTap: () => data.toggleReaction(
                        channelId, message.id, r.emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: iReacted
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : (isDark
                                ? AppColors.reactionBg
                                : Colors.grey.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: iReacted
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${r.emoji} ${r.userIds.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Thread reply badge
          if (message.threadReplies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: isMine ? 0 : 52, top: 2),
              child: GestureDetector(
                onTap: onThreadTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${message.threadReplies.length} ${message.threadReplies.length == 1 ? 'reply' : 'replies'}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Input area ──────────────────────────────────────────────────────────────

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _InputArea({
    required this.controller,
    required this.isDark,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkAppBar : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCard
                    : const Color(0xFFF0F2F5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
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
    );
  }
}
