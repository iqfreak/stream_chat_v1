import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class ChannelInfoScreen extends StatelessWidget {
  final String channelId;

  const ChannelInfoScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
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
        .whereType<AppUser>()
        .toList();

    final pinnedMessages = channel.messages.where((m) => m.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Channel Info'),
        actions: [
          if (channel.isGroup)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename group',
              onPressed: () => _showRenameDialog(context, data, channel.name),
            ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
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
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 40,
                    ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

          // Members section header with "Add member" button for groups
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Members (${members.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (channel.isGroup)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () =>
                        _showAddMemberSheet(context, data, channel),
                  ),
              ],
            ),
          ),

          ...members.map(
            (user) => ListTile(
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
                user.id == data.currentUser.id
                    ? 'You · @${user.username}'
                    : '@${user.username}',
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.online.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          color: AppColors.online,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 8),

          // Pinned messages
          _SectionHeader(title: 'Pinned Messages (${pinnedMessages.length})'),
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
                leading: const Icon(
                  Icons.push_pin,
                  color: AppColors.primary,
                  size: 20,
                ),
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

          // Leave / Delete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.exit_to_app, color: AppColors.error),
              label: Text(
                channel.isGroup ? 'Leave Channel' : 'Delete Chat',
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      channel.isGroup ? 'Leave Channel' : 'Delete Chat',
                    ),
                    content: Text(
                      channel.isGroup
                          ? 'Are you sure you want to leave this channel?'
                          : 'Are you sure you want to delete this chat?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          channel.isGroup ? 'Leave' : 'Delete',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  if (channel.isGroup) {
                    context.read<StreamChatService>().leaveChannel(channelId);
                  } else {
                    context.read<StreamChatService>().deleteChannel(channelId);
                  }
                  context.go('/channels');
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    StreamChatService data,
    String currentName,
  ) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename group'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new group name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                data.renameChannel(channelId, name);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberSheet(
    BuildContext context,
    StreamChatService data,
    AppChannel channel,
  ) {
    final nonMembers = data.allUsers
        .where((u) => !channel.memberIds.contains(u.id))
        .toList();

    if (nonMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All users are already members.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Add Member',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 0),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: nonMembers.length,
                itemBuilder: (_, i) {
                  final user = nonMembers[i];
                  return ListTile(
                    leading: UserAvatar(
                      name: user.name,
                      avatarUrl: user.avatarUrl,
                      size: 42,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      data.addMemberToChannel(channel.id, user.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${user.name} added to ${channel.name}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
