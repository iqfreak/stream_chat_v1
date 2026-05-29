import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/stream_chat_service.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// 👇 السطر ده هو اللي كان ناقص عشان الكلاس يتقري
import 'package:stream_chat_localizations/stream_chat_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => StreamChatService()),
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

      // ===== الأكواد المسؤولة عن تعميم اللغة =====
      locale: Locale(appState.locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalStreamChatLocalizations
            .delegate, // دلوقتي الكلاس ده هيتقري بدون أي خطأ
      ],
      // ===========================================
    );
  }
}
