import 'package:flutter_test/flutter_test.dart';
import 'package:stream_chat_v1/main.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_v1/providers/app_state.dart';
import 'package:stream_chat_v1/services/stream_chat_service.dart';

void main() {
  testWidgets('App launches and renders splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => StreamChatService()),
        ],
        child: const StreamChatApp(),
      ),
    );
    // Pump one frame — splash appears
    await tester.pump();
    expect(find.byType(StreamChatApp), findsOneWidget);
    // Cancel pending timers by pumping with duration
    await tester.pump(const Duration(seconds: 3));
  }, timeout: const Timeout(Duration(seconds: 10)));
}
