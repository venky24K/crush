import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crush/main.dart';
import 'package:crush/ui/screens/splash/splash_screen.dart';

void main() {
  testWidgets('App loads and displays SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const CrushApp());
    expect(find.byType(CrushApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump past splash duration to settle animations and navigation
    await tester.pump(const Duration(milliseconds: 3500));
    // Clean up test widget tree
    await tester.pumpWidget(const SizedBox());
  });
}
