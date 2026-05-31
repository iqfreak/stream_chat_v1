import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final notifications = data.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = data.unreadNotificationCount;

    return BottomNavScaffold(
      selectedIndex: 2,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: data.markAllNotificationsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 72,
                      color: isDark
                          ? AppColors.textDarkSecondary.withValues(alpha: 0.5)
                          : AppColors.textLightSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You\'ll see @mentions and alerts here',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDarkSecondary.withValues(alpha: 0.7)
                          : AppColors.textLightSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
              ),
              itemBuilder: (context, i) {
                final notif = notifications[i];
                final sender = data.userById(notif.fromUserId);
                final channel = data.channelById(notif.channelId);
                return _NotifTile(
                  notification: notif,
                  sender: sender,
                  channelName: channel?.name ?? 'Unknown',
                  isDark: isDark,
                  onTap: () {
                    data.markNotificationRead(notif.id);
                    // Also clear the unread badge on the channel tile.
                    data.markChannelRead(notif.channelId);
                    context.push('/channels/${notif.channelId}/chat');
                  },
                );
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notification;
  final AppUser? sender;
  final String channelName;
  final bool isDark;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notification,
    required this.sender,
    required this.channelName,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.primary.withValues(alpha: 0.04))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                UserAvatar(
                  name: sender?.name ?? '?',
                  avatarUrl: sender?.avatarUrl,
                  size: 48,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBackground
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      notification.isMention
                          ? Icons.alternate_email
                          : Icons.chat_bubble,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                      children: [
                        TextSpan(
                          text: sender?.name ?? 'Someone',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: notification.isMention
                              ? ' mentioned you in '
                              : ' messaged you in ',
                        ),
                        TextSpan(
                          text: channelName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
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
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
