import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/discovery_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/home_navigation_screen.dart';

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

  // Initialize Supabase (falls back smoothly to Demo Mode if placeholder keys are present)
  await SupabaseService().initialize();

  // Remove splash screen now that core services are ready
  FlutterNativeSplash.remove();

  runApp(const CrushApp());
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
        home: const AuthGate(),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFD297B)),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeNavigationScreen();
    }

    return const LoginScreen();
  }
}
