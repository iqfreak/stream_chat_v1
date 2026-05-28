import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import '../../widgets/user_avatar.dart';

class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
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
                  final preview = last == null
                      ? 'No messages yet'
                      : last.isDeleted
                          ? 'Message deleted'
                          : last.displayText;

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

                  return ListTile(
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
                                            (id) => id != data.currentUser.id,
                                            orElse: () => ch.memberIds.first))
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
                            timeago.format(last.createdAt, allowFromNow: true),
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
                      context.push('/channels/${ch.id}/chat');
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final List<String> memberIds;
  final MockDataService data;
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
                    color: Theme.of(context).scaffoldBackgroundColor, width: 2),
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
