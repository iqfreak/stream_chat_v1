import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class CreateChannelScreen extends StatefulWidget {
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
  bool _creating = false;
  bool _searching = false;
  List<AppUser> _searchResults = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() => _search = query);
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    final results = await context.read<StreamChatService>().searchUsers(query);
    if (!mounted) return;
    setState(() { _searchResults = results; _searching = false; });
  }

  Future<void> _create() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one member')));
      return;
    }
    if (_isGroup && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    setState(() => _creating = true);
    final data = context.read<StreamChatService>();
    final me = data.currentUser.id;
    final memberIds = [me, ..._selected];
    final channelName = _isGroup
        ? _nameCtrl.text.trim()
        : (data.userById(_selected.first)?.name ?? 'DM');
    try {
      final channelId = await data.createChannel(isGroup: _isGroup, name: channelName, memberIds: memberIds);
      if (!mounted) return;
      context.go('/channels/$channelId/chat');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _skipToChannels() => context.go('/channels');

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show search results when actively searching, otherwise show cached users
    final List<AppUser> displayList = _search.trim().length >= 2
        ? _searchResults
        : data.otherUsers
            .where((u) => _search.isEmpty || u.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: widget.isNewUser
            ? IconButton(icon: const Icon(Icons.close), tooltip: 'Skip for now', onPressed: _skipToChannels)
            : const BackButton(),
        title: Text(widget.isNewUser ? 'Start a Chat' : 'New Chat'),
        actions: [
          if (widget.isNewUser)
            TextButton(
              onPressed: _skipToChannels,
              child: Text('Skip', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            ),
          _creating
              ? const Padding(padding: EdgeInsets.only(right: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(onPressed: _create, child: const Text('Create', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Column(
        children: [
          // Welcome banner (new user only)
          if (widget.isNewUser)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.waving_hand_rounded, color: AppColors.primary, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome to StreamChat!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? AppColors.textDark : AppColors.textLight)),
                  const SizedBox(height: 2),
                  Text('Search by name to find and start chatting.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                ])),
              ]),
            ),

          // DM / Group toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Expanded(child: _TypeButton(label: 'Direct Message', icon: Icons.person, selected: !_isGroup, onTap: () => setState(() { _isGroup = false; _selected.clear(); }))),
              const SizedBox(width: 12),
              Expanded(child: _TypeButton(label: 'Group Chat', icon: Icons.group, selected: _isGroup, onTap: () => setState(() => _isGroup = true))),
            ]),
          ),

          // Group name field
          if (_isGroup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Group name', prefixIcon: Icon(Icons.group_outlined))),
            ),

          // Selected member chips
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
                        avatar: UserAvatar(name: data.userById(id)?.name ?? id, size: 24, avatarUrl: data.userById(id)?.avatarUrl),
                        label: Text(data.userById(id)?.name ?? id),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selected.remove(id)),
                      ),
                    ),
                ],
              ),
            ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchCtrl.clear(); _onSearchChanged(''); })
                        : null,
              ),
            ),
          ),

          // Hint when search is short but not empty
          if (_search.trim().isNotEmpty && _search.trim().length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('Type at least 2 characters to search all users', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            ),

          // User list
          Expanded(
            child: displayList.isEmpty && !_searching
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_search, size: 48, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _search.trim().length >= 2 ? 'No users found for "$_search"' : 'No users yet',
                        style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                      ),
                      if (_search.trim().length < 2) ...[
                        const SizedBox(height: 6),
                        Text('Search by name to find people', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary.withValues(alpha: 0.7) : AppColors.textLightSecondary.withValues(alpha: 0.7))),
                      ],
                    ]),
                  )
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, i) {
                      final user = displayList[i];
                      final selected = _selected.contains(user.id);
                      return ListTile(
                        leading: UserAvatar(name: user.name, avatarUrl: user.avatarUrl, size: 44, showOnline: user.isOnline),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('@${user.username}', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 12)),
                        trailing: selected ? const CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Icon(Icons.check, color: Colors.white, size: 14)) : null,
                        onTap: () {
                          setState(() {
                            if (!_isGroup) { _selected.clear(); _selected.add(user.id); }
                            else { if (selected) _selected.remove(user.id); else _selected.add(user.id); }
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

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3), width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? AppColors.primary : Colors.grey, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}
