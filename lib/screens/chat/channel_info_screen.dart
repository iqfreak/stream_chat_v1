import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class ChannelInfoScreen extends StatelessWidget {
  final String channelId;

  const ChannelInfoScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final channel = data.channelById(channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Channel not found')),
      );
    }

    final members = channel.memberIds
        .map((id) => data.userById(id))
        .whereType<MockUser>()
        .toList();

    final pinnedMessages = channel.messages.where((m) => m.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Channel Info'),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: isDark ? AppColors.darkCard : const Color(0xFFF5F6FA),
            child: Column(
              children: [
                if (channel.isGroup)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.group, color: Colors.white, size: 40),
                  )
                else ...[
                  UserAvatar(
                    name: members
                            .firstWhere(
                              (u) => u.id != data.currentUser.id,
                              orElse: () => members.first,
                            )
                            .name,
                    avatarUrl: members
                        .firstWhere(
                          (u) => u.id != data.currentUser.id,
                          orElse: () => members.first,
                        )
                        .avatarUrl,
                    size: 80,
                    showOnline: members
                        .firstWhere(
                          (u) => u.id != data.currentUser.id,
                          orElse: () => members.first,
                        )
                        .isOnline,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  channel.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  channel.isGroup
                      ? '${members.length} members'
                      : 'Direct Message',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Members
          _SectionHeader(title: 'Members (${members.length})'),
          ...members.map((user) => ListTile(
                leading: UserAvatar(
                  name: user.name,
                  avatarUrl: user.avatarUrl,
                  size: 44,
                  showOnline: user.isOnline,
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  user.id == data.currentUser.id ? 'You' : user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
                trailing: user.isOnline
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.online.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(
                              color: AppColors.online,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    : null,
              )),

          const SizedBox(height: 8),

          // Pinned messages
          _SectionHeader(
              title: 'Pinned Messages (${pinnedMessages.length})'),
          if (pinnedMessages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No pinned messages',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ),
            )
          else
            ...pinnedMessages.map((msg) {
              final sender = data.userById(msg.senderId);
              return ListTile(
                leading: const Icon(Icons.push_pin,
                    color: AppColors.primary, size: 20),
                title: Text(
                  msg.displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  sender?.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
                onTap: () => context.pop(),
              );
            }),

          const SizedBox(height: 24),

          // Leave / close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.exit_to_app, color: AppColors.error),
              label: const Text('Leave Channel',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                context.go('/channels');
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
