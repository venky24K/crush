import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'core/constants/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/discovery_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/onboarding_screen.dart';
import 'ui/screens/home_navigation_screen.dart';
import 'ui/screens/splash/splash_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash screen while initialization finishes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set light status bar & navigation bar for warm ivory theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,          // dark icons on light bg
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize live Supabase backend services
  await SupabaseService().initialize();

  // Remove splash screen now that core services are ready
  FlutterNativeSplash.remove();

  runApp(const CrushApp());

  // Check for Shorebird over-the-air patches in the background
  _checkForShorebirdUpdates();
}

final _shorebirdUpdater = ShorebirdUpdater();

void _checkForShorebirdUpdates() {
  _shorebirdUpdater.checkForUpdate().then((status) {
    if (status == UpdateStatus.outdated) {
      debugPrint('[Shorebird] New patch available. Downloading in background...');
      _shorebirdUpdater.update().then((_) {
        debugPrint('[Shorebird] Patch downloaded! Will apply on next restart.');
      });
    }
  }).catchError((e) {
    debugPrint('[Shorebird] Update check notice: $e');
  });
}

class CrushApp extends StatelessWidget {
  const CrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Crush',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const SplashScreen(embedded: true);
    }

    // 1. Returning user: authenticated with profile -> Main App
    if (authProvider.isAuthenticated) {
      return const HomeNavigationScreen();
    }

    // 2. New OAuth user: signed in via Google / Apple but profile not created yet -> Guided Onboarding
    if (authProvider.needsOnboarding) {
      final user = authProvider.currentUser;
      final email = user?.email;
      final name = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String?;
      final provider = user?.appMetadata['provider'] as String? ?? 'google';

      return OnboardingScreen(
        authProvider: provider,
        initialEmail: email,
        initialName: name,
      );
    }

    // 3. Not signed in -> Login Screen
    return const LoginScreen();
  }
}
