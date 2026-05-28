import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class ThreadScreen extends StatefulWidget {
  final String channelId;
  final String messageId;

  const ThreadScreen({
    super.key,
    required this.channelId,
    required this.messageId,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendReply() {
    final data = context.read<MockDataService>();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    // Guard: non-members cannot reply in threads
    if (!channel.memberIds.contains(data.currentUser.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not a member of this group.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    data.sendThreadReply(
      widget.channelId,
      widget.messageId,
      text,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final channel = data.channelById(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not found')));
    }

    MockMessage? parent;
    try {
      parent = channel.messages.firstWhere((m) => m.id == widget.messageId);
    } catch (_) {
      parent = null;
    }

    if (parent == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Message not found')));
    }

    final replies = parent.threadReplies;
    final me = data.currentUser;
    final isMember = channel.memberIds.contains(me.id);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Thread'),
      ),
      body: Column(
        children: [
          // Non-member banner
          if (channel.isGroup && !isMember)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      'You are not a member of this group and cannot reply.',
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
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                // Parent message
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkDivider
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            name: data.userById(parent.senderId)?.name ?? '?',
                            avatarUrl: data.userById(parent.senderId)?.avatarUrl,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.userById(parent.senderId)?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  timeago.format(parent.createdAt),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(parent.displayText,
                          style: const TextStyle(fontSize: 14.5)),
                      if (parent.reactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: parent.reactions
                              .map((r) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.reactionBg
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${r.emoji} ${r.userIds.length}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (replies.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkDivider
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkDivider
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...replies.map((reply) {
                    final isMine = reply.senderId == me.id;
                    final replyUser = data.userById(reply.senderId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMine) ...[
                            UserAvatar(
                              name: replyUser?.name ?? '?',
                              avatarUrl: replyUser?.avatarUrl,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? AppColors.sentBubble
                                    : isDark
                                        ? AppColors.receivedBubbleDark
                                        : AppColors.receivedBubbleLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMine)
                                    Text(
                                      replyUser?.name ?? '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  // FIX: use displayText so edited replies show correctly
                                  Text(
                                    reply.displayText,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : isDark
                                              ? AppColors.textDark
                                              : AppColors.textLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (reply.editedText != null)
                                    Text(
                                      '(edited)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: (isMine
                                                ? Colors.white
                                                : isDark
                                                    ? AppColors.textDark
                                                    : AppColors.textLight)
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeago.format(reply.createdAt,
                                        allowFromNow: true),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: (isMine
                                              ? Colors.white
                                              : isDark
                                                  ? AppColors.textDark
                                                  : AppColors.textLight)
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMine) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          // Input area — locked for non-members in groups
          if (!channel.isGroup || isMember)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAppBar : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkDivider
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Reply in thread...',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF0F2F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendReply,
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
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAppBar : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkDivider
                        : const Color(0xFFE5E7EB),
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
                    'You cannot reply in this thread.',
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }
}
