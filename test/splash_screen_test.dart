import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_theme.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/screens/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders hero logo, tagline, and progress indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: SplashScreen(
            embedded: true,
          ),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Spark genuine connections'), findsOneWidget);
    expect(find.text('For unspoken love'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Advance time past flutter_animate entrance delays (650ms) to drain pending timers
    await tester.pump(const Duration(milliseconds: 1500));

    // Pump widget tree away to clean up controllers
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SplashScreen auto-navigates to destination',
      (WidgetTester tester) async {
    const destinationKey = Key('destination_screen');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SplashScreen(
            minDurationMs: 300,
            destination: Scaffold(
              key: destinationKey,
              body: Center(child: Text('Destination Screen')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance time past minDurationMs and animation duration
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 700));

    // Verify destination is visible
    expect(find.byKey(destinationKey), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });
}
