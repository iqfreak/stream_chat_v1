import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class CreateChannelScreen extends StatefulWidget {
  /// When true a welcome banner is shown (coming straight from registration).
  final bool isNewUser;

  const CreateChannelScreen({super.key, this.isNewUser = false});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  bool _isGroup = false;
  String _search = '';
  final Set<String> _selected = {};
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _create() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member')),
      );
      return;
    }
    if (_isGroup && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }

    final data = context.read<MockDataService>();
    final me = data.currentUser.id;
    final memberIds = [me, ..._selected];

    String channelName;
    if (_isGroup) {
      channelName = _nameCtrl.text.trim();
    } else {
      final otherId = _selected.first;
      channelName = data.userById(otherId)?.name ?? 'DM';
    }

    final newChannel = MockChannel(
      id: 'ch_new_${DateTime.now().millisecondsSinceEpoch}',
      name: channelName,
      isGroup: _isGroup,
      memberIds: memberIds,
      messages: [],
      unreadCount: 0,
    );

    data.addChannel(newChannel);
    context.go('/channels/${newChannel.id}/chat');
  }

  /// Skip directly to the channel list without creating anything.
  void _skipToChannels() => context.go('/channels');

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final others = data.otherUsers
        .where((u) =>
            _search.isEmpty ||
            u.name.toLowerCase().contains(_search.toLowerCase()) ||
            u.email.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // When coming from registration there's no back destination — use
        // a close/skip button instead so the user can jump to channels.
        leading: widget.isNewUser
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Skip for now',
                onPressed: _skipToChannels,
              )
            : const BackButton(),
        title: Text(widget.isNewUser ? 'Start a Chat' : 'New Chat'),
        actions: [
          if (widget.isNewUser)
            TextButton(
              onPressed: _skipToChannels,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ),
          TextButton(
            onPressed: _create,
            child: const Text(
              'Create',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Welcome banner (new-user only) ─────────────────────────────
          if (widget.isNewUser)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.waving_hand_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to StreamChat!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textDark
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Start by opening a DM or creating a group.',
                          style: TextStyle(
                            fontSize: 12,
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

          // ── DM vs Group toggle ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Direct Message',
                    icon: Icons.person,
                    selected: !_isGroup,
                    onTap: () => setState(() {
                      _isGroup = false;
                      _selected.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Group Chat',
                    icon: Icons.group,
                    selected: _isGroup,
                    onTap: () => setState(() => _isGroup = true),
                  ),
                ),
              ],
            ),
          ),

          // ── Group name field ────────────────────────────────────────────
          if (_isGroup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
            ),

          // ── Selected chips ──────────────────────────────────────────────
          if (_selected.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final id in _selected)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: UserAvatar(
                            name: data.userById(id)!.name,
                            size: 24,
                            avatarUrl: data.userById(id)!.avatarUrl),
                        label: Text(data.userById(id)!.name),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selected.remove(id)),
                      ),
                    ),
                ],
              ),
            ),

          // ── Search ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search members...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // ── Member list ─────────────────────────────────────────────────
          Expanded(
            child: others.isEmpty
                ? Center(
                    child: Text(
                      'No other users found',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: others.length,
                    itemBuilder: (context, i) {
                      final user = others[i];
                      final selected = _selected.contains(user.id);
                      return ListTile(
                        leading: UserAvatar(
                          name: user.name,
                          avatarUrl: user.avatarUrl,
                          size: 44,
                          showOnline: user.isOnline,
                        ),
                        title: Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: selected
                            ? const CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.check,
                                    color: Colors.white, size: 14),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            if (!_isGroup) {
                              _selected.clear();
                              _selected.add(user.id);
                            } else {
                              if (selected) {
                                _selected.remove(user.id);
                              } else {
                                _selected.add(user.id);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Type toggle button ──────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : Colors.grey,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
