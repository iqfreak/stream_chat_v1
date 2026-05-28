import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import '../../widgets/user_avatar.dart';

class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final channels = data.myChannels;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavScaffold(
      selectedIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StreamChat'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/channels/create'),
          child: const Icon(Icons.add),
        ),
        body: channels.isEmpty
            ? const Center(child: Text('No chats yet. Tap + to start one.'))
            : ListView.separated(
                itemCount: channels.length,
                separatorBuilder: (context, index) => Divider(
                  height: 0,
                  indent: 76,
                  color: isDark
                      ? AppColors.darkDivider
                      : const Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, i) {
                  final ch = channels[i];
                  final last = ch.lastMessage;

                  // Build preview text — prefix with sender name in groups
                  String preview;
                  if (last == null) {
                    preview = 'No messages yet';
                  } else if (last.isDeleted) {
                    preview = 'Message deleted';
                  } else {
                    final text = last.displayText;
                    if (ch.isGroup) {
                      final sender = data.userById(last.senderId);
                      final senderName = last.senderId == data.currentUser.id
                          ? 'You'
                          : (sender?.name.split(' ').first ?? 'Unknown');
                      preview = '$senderName: $text';
                    } else {
                      preview = text;
                    }
                  }

                  Widget avatar;
                  if (ch.isGroup) {
                    avatar = _GroupAvatar(
                        memberIds: ch.memberIds, data: data, name: ch.name);
                  } else {
                    final other = ch.memberIds
                        .where((id) => id != data.currentUser.id)
                        .map((id) => data.userById(id))
                        .whereType<MockUser>()
                        .firstOrNull;
                    avatar = UserAvatar(
                      avatarUrl: other?.avatarUrl,
                      name: other?.name ?? ch.name,
                      size: 52,
                      showOnline: other?.isOnline ?? false,
                    );
                  }

                  // Swipe action label depends on channel type:
                  // - DM: delete (removes the channel entirely)
                  // - Group: leave (removes current user from memberIds;
                  //   if last member, the channel is also cleaned up)
                  final swipeLabel =
                      ch.isGroup ? 'Leave' : 'Delete';
                  final swipeIcon =
                      ch.isGroup ? Icons.exit_to_app : Icons.delete_outline;

                  return Dismissible(
                    key: ValueKey(ch.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.error,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(swipeIcon, color: Colors.white, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            swipeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      final otherName = ch.isGroup
                          ? ch.name
                          : (data
                                  .userById(ch.memberIds.firstWhere(
                                      (id) => id != data.currentUser.id,
                                      orElse: () => ch.memberIds.first))
                                  ?.name ??
                              ch.name);
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                              ch.isGroup ? 'Leave group?' : 'Delete chat?'),
                          content: Text(
                            ch.isGroup
                                ? 'Leave "$otherName"? You will no longer receive messages from this group.'
                                : 'Delete your chat with "$otherName"? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(ch.isGroup ? 'Leave' : 'Delete'),
                            ),
                          ],
                        ),
                      ) ??
                          false;
                    },
                    onDismissed: (_) {
                      if (ch.isGroup) {
                        context.read<StreamChatService>().leaveChannel(ch.id);
                      } else {
                        context.read<StreamChatService>().deleteChannel(ch.id);
                      }
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: avatar,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ch.isGroup
                                  ? ch.name
                                  : (data
                                          .userById(ch.memberIds.firstWhere(
                                              (id) =>
                                                  id != data.currentUser.id,
                                              orElse: () =>
                                                  ch.memberIds.first))
                                          ?.name ??
                                      ch.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (last != null)
                            Text(
                              timeago.format(last.createdAt,
                                  allowFromNow: true),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary,
                                fontWeight: ch.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (ch.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${ch.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        context
                            .read<StreamChatService>()
                            .markChannelRead(ch.id);
                        context.push('/channels/${ch.id}/chat');
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final List<String> memberIds;
  final StreamChatService data;
  final String name;

  const _GroupAvatar(
      {required this.memberIds, required this.data, required this.name});

  @override
  Widget build(BuildContext context) {
    final members = memberIds
        .take(2)
        .map((id) => data.userById(id))
        .whereType<MockUser>()
        .toList();

    if (members.length < 2) {
      return UserAvatar(name: name, size: 52);
    }

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: UserAvatar(
              avatarUrl: members[0].avatarUrl,
              name: members[0].name,
              size: 36,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2),
              ),
              child: UserAvatar(
                avatarUrl: members[1].avatarUrl,
                name: members[1].name,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
