import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melo/main.dart';

void main() {
  testWidgets('MeloApp smoke test and brand presence', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MeloApp(),
      ),
    );

    // Verify brand title and key action buttons render
    expect(find.text('Melo'), findsOneWidget);
    expect(find.text('+ Upload MIDI File (.mid)'), findsOneWidget);
    expect(find.text('Convert Any MP3 to MIDI'), findsOneWidget);
  });
}
