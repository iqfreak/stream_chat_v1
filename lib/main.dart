import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/mock_data.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => MockDataService()),
      ],
      child: const StreamChatApp(),
    ),
  );
}

class StreamChatApp extends StatefulWidget {
  const StreamChatApp({super.key});

  @override
  State<StreamChatApp> createState() => _StreamChatAppState();
}

class _StreamChatAppState extends State<StreamChatApp> {
  late final _router = buildRouter(context.read<AppState>());

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp.router(
      title: 'Stream Chat V1',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      routerConfig: _router,
    );
  }
}
