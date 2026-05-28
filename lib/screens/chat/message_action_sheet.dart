import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';

class MessageActionSheet extends StatelessWidget {
  final AppMessage message;
  final String channelId;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.channelId,
  });

  static const _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🎉'];

  @override
  Widget build(BuildContext context) {
    final data = context.read<StreamChatService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMine = message.senderId == data.currentUser.id;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final hasText = message.displayText.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Quick emoji reactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _quickEmojis.map((emoji) {
                final alreadyReacted = message.reactions
                    .any((r) =>
                        r.emoji == emoji &&
                        r.userIds.contains(data.currentUser.id));
                return GestureDetector(
                  onTap: () {
                    data.toggleReaction(channelId, message.id, emoji);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: alreadyReacted
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF5F6FA)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alreadyReacted
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 0),
          // Actions
          _ActionTile(
            icon: Icons.forum_outlined,
            label: 'Reply in Thread',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              context.push(
                '/channels/$channelId/chat/${message.id}/thread',
              );
            },
          ),
          // Copy — only shown when there is text to copy
          if (hasText)
            _ActionTile(
              icon: Icons.copy_outlined,
              label: 'Copy Text',
              color: const Color(0xFF007AFF),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.displayText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          // Forward
          _ActionTile(
            icon: Icons.forward_outlined,
            label: 'Forward Message',
            color: const Color(0xFF5856D6),
            onTap: () {
              Navigator.pop(context);
              _showForwardSheet(context, data);
            },
          ),
          _ActionTile(
            icon: message.isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            label: message.isPinned ? 'Unpin Message' : 'Pin Message',
            color: const Color(0xFFFF9500),
            onTap: () {
              data.togglePin(channelId, message.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message.isPinned
                      ? 'Message unpinned'
                      : 'Message pinned'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          if (isMine)
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Message',
              color: const Color(0xFF34C759),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, data);
              },
            ),
          if (isMine)
            _ActionTile(
              icon: Icons.delete_outlined,
              label: 'Delete Message',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, data);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Shows a bottom sheet to pick a channel to forward the message to.
  void _showForwardSheet(BuildContext context, StreamChatService data) {
    final channels = data.myChannels
        .where((c) => c.id != channelId)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Forward to...',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Divider(height: 0),
                if (channels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No other chats to forward to.'),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: channels.length,
                      itemBuilder: (_, i) {
                        final ch = channels[i];
                        final otherUser = ch.isGroup
                            ? null
                            : ch.memberIds
                                .where((id) => id != data.currentUser.id)
                                .map((id) => data.userById(id))
                                .whereType<AppUser>()
                                .firstOrNull;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Icon(
                              ch.isGroup ? Icons.group : Icons.person,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            ch.isGroup
                                ? ch.name
                                : (otherUser?.name ?? ch.name),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            // Forward: send the display text (and attachments)
                            // as a new message in the target channel.
                            final fwdText =
                                '↪ ${message.displayText}';
                            data.sendMessage(ch.id, fwdText);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Forwarded to ${ch.isGroup ? ch.name : (otherUser?.name ?? ch.name)}',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, StreamChatService data) {
    final ctrl =
        TextEditingController(text: message.editedText ?? message.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          decoration:
              const InputDecoration(hintText: 'Edit your message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                data.editMessage(channelId, message.id, text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, StreamChatService data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
            'This message will be removed for all members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              data.deleteMessage(channelId, message.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
