import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/app_state.dart';
import 'services/stream_chat_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase + push notifications. Wrapped so the app still runs if Firebase
  // isn't configured on a given build (e.g. missing google-services.json).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
    await PushService.instance.init();
  } catch (e) {
    debugPrint('Firebase/push init skipped: $e');
  }

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
      title: 'Stream Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      routerConfig: _router,

      // ===== Localization + direction =====
      locale: Locale(appState.locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalStreamChatLocalizations.delegate,
      ],
      // Force the whole app to lay out right-to-left when Arabic is selected.
      builder: (context, child) {
        return Directionality(
          textDirection:
              appState.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      // ====================================
    );
  }
}
