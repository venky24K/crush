import 'package:flutter_test/flutter_test.dart';
import 'package:crush/main.dart';

void main() {
  testWidgets('App loads AuthGate', (WidgetTester tester) async {
    await tester.pumpWidget(const CrushApp());
    expect(find.byType(CrushApp), findsOneWidget);
  });
}
