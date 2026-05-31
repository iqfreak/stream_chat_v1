import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import '../../widgets/user_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _typeFilter = 'all'; // all | text | image | video | file
  List<({AppMessage message, AppChannel channel})> _results = [];
  bool _searching = false;

  static const _filters = [
    ('all', 'All', Icons.all_inclusive),
    ('text', 'Text', Icons.notes),
    ('image', 'Photos', Icons.image),
    ('video', 'Videos', Icons.videocam),
    ('file', 'Files', Icons.insert_drive_file),
  ];

  bool get _mediaFilter =>
      _typeFilter == 'image' || _typeFilter == 'video' || _typeFilter == 'file';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _doSearch(String query) async {
    setState(() => _query = query);
    // Media filters can run with an empty query (browse all media).
    final shouldSearch = query.isNotEmpty || _mediaFilter;
    if (!shouldSearch) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    final results = await context
        .read<StreamChatService>()
        .searchMessages(query, typeFilter: _typeFilter);
    if (!mounted) return;
    setState(() { _results = results; _searching = false; });
  }

  void _onFilterChanged(String filter) {
    setState(() => _typeFilter = filter);
    _doSearch(_query);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavScaffold(
      selectedIndex: 1,
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              onChanged: _doSearch,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () { _ctrl.clear(); _doSearch(''); })
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = _typeFilter == f.$1;
                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    f.$3,
                    size: 16,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  label: Text(f.$2),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  backgroundColor:
                      isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
                  selectedColor: AppColors.primary,
                  onSelected: (_) => _onFilterChanged(f.$1),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: (_query.isEmpty && !_mediaFilter)
                ? _EmptyState(isDark: isDark)
                : _searching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off, size: 64, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                            const SizedBox(height: 12),
                            Text(_query.isEmpty ? 'No items found' : 'No results for "$_query"', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                          ]))
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => Divider(height: 0, indent: 72, color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB)),
                            itemBuilder: (context, i) {
                              final msg = _results[i].message;
                              final ch = _results[i].channel;
                              final sender = data.userById(msg.senderId);
                              return ListTile(
                                leading: UserAvatar(name: sender?.name ?? '?', avatarUrl: sender?.avatarUrl, size: 44),
                                title: Row(children: [
                                  Expanded(child: Text(sender?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                  Text(timeago.format(msg.createdAt), style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                                ]),
                                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _HighlightText(text: msg.displayText, query: _query, isDark: isDark),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.chat_bubble_outline, size: 11, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(ch.name, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                  ]),
                                ]),
                                onTap: () => context.push('/channels/${ch.id}/chat'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text; final String query; final bool isDark;
  const _HighlightText({required this.text, required this.query, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx == -1) { spans.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(text: text.substring(idx, idx + query.length), style: const TextStyle(backgroundColor: Color(0x33005FFF), color: AppColors.primary, fontWeight: FontWeight.w700)));
      start = idx + query.length;
    }
    return Text.rich(TextSpan(children: spans, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)), maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search, size: 72, color: isDark ? AppColors.textDarkSecondary.withValues(alpha: 0.5) : AppColors.textLightSecondary.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      Text('Search messages', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
      const SizedBox(height: 6),
      Text('Type to search across all your chats', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary.withValues(alpha: 0.7) : AppColors.textLightSecondary.withValues(alpha: 0.7))),
    ]));
  }
}
