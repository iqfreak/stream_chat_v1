import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/stream_chat_service.dart';
import '../utils/app_strings.dart';

class BottomNavScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final int selectedIndex;
  final Widget? floatingActionButton;

  const BottomNavScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    this.appBar,
    this.floatingActionButton,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/channels');
      case 1:
        context.go('/search');
      case 2:
        context.go('/notifications');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<StreamChatService, int>(
      (svc) => svc.unreadNotificationCount,
    );

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: AppStrings.t(context, 'nav_chats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: const Icon(Icons.search),
            label: AppStrings.t(context, 'nav_search'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: AppStrings.t(context, 'nav_notifications'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: AppStrings.t(context, 'nav_settings'),
          ),
        ],
      ),
    );
  }
}
