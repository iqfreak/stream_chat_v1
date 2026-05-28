import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/stream_chat_service.dart';

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
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
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
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
