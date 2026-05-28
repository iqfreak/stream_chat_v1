import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/channels/channel_list_screen.dart';
import '../screens/channels/create_channel_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/thread_screen.dart';
import '../screens/chat/channel_info_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/settings_sub_screens.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const channelList = '/channels';
  static const createChannel = '/channels/create';
  static const chat = '/channels/:channelId/chat';
  static const thread = '/channels/:channelId/chat/:messageId/thread';
  static const channelInfo = '/channels/:channelId/info';
  static const search = '/search';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const security = '/security';
  static const privacy = '/privacy';
  static const help = '/help';
  static const about = '/about';
}

GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = appState.isAuthenticated;
      final onSplash = state.matchedLocation == AppRoutes.splash;
      final onAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (!isAuth && !onSplash && !onAuth) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.channelList,
        name: 'channelList',
        builder: (context, state) => const ChannelListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createChannel',
            builder: (context, state) {
              // extra carries {isNewUser: true} when coming from registration
              final extra = state.extra as Map<String, dynamic>?;
              final isNewUser = extra?['isNewUser'] == true;
              return CreateChannelScreen(isNewUser: isNewUser);
            },
          ),
          GoRoute(
            path: ':channelId/chat',
            name: 'chat',
            builder: (context, state) {
              final channelId = state.pathParameters['channelId']!;
              return ChatScreen(channelId: channelId);
            },
            routes: [
              GoRoute(
                path: ':messageId/thread',
                name: 'thread',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  final messageId = state.pathParameters['messageId']!;
                  return ThreadScreen(
                    channelId: channelId,
                    messageId: messageId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: ':channelId/info',
            name: 'channelInfo',
            builder: (context, state) {
              final channelId = state.pathParameters['channelId']!;
              return ChannelInfoScreen(channelId: channelId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        name: 'security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
