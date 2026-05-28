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
  List<({MockMessage message, MockChannel channel})> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _doSearch(String query) async {
    setState(() { _query = query; _searching = query.isNotEmpty; });
    if (query.isEmpty) { setState(() { _results = []; _searching = false; }); return; }
    final results = await context.read<StreamChatService>().searchMessages(query);
    if (!mounted) return;
    setState(() { _results = results; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavScaffold(
      selectedIndex: 1,
      child: Scaffold(
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
            Expanded(
              child: _query.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : _searching
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.search_off, size: 64, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                              const SizedBox(height: 12),
                              Text('No results for "$_query"', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            ]))
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => Divider(height: 0, indent: 72, color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB)),
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
