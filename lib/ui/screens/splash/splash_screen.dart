import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/main.dart';

/// Animated in-app Splash Screen for Crush.
///
/// Provides a continuous, zero-flicker transition from the native launch screen
/// (#FFF8F2) into an animated brand presentation with a heartbeat pulse on the logo,
/// smooth tagline reveal, and automatic cross-fade into [AuthGate].
class SplashScreen extends StatefulWidget {
  /// When true, renders statically as an embedded loading state without triggering auto-navigation.
  final bool embedded;

  /// Custom destination widget after splash completes (defaults to [AuthGate]).
  final Widget? destination;

  /// Minimum display duration in milliseconds before navigating (defaults to 1900ms).
  final int minDurationMs;

  const SplashScreen({
    super.key,
    this.embedded = false,
    this.destination,
    this.minDurationMs = 1900,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _navigationTimer;
  bool _hasNavigated = false;
  int _elapsedWaitMs = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (!widget.embedded) {
      _scheduleNavigation();
    }
  }

  void _scheduleNavigation() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer(
      Duration(milliseconds: widget.minDurationMs),
      _checkAndNavigate,
    );
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;

    // Check if AuthProvider is still loading in the background (with 3s timeout)
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoading && _elapsedWaitMs < 3000) {
        _elapsedWaitMs += 250;
        _navigationTimer = Timer(const Duration(milliseconds: 250), _checkAndNavigate);
        return;
      }
    } catch (_) {
      // If AuthProvider is not in tree (e.g. isolated unit tests), proceed
    }

    _proceedToDestination();
  }

  void _proceedToDestination() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final target = widget.destination ?? const AuthGate();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2), // Matches native splash perfectly
      body: Stack(
        children: [
          // ─── Subtle Ambient Background Glow ───
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.85,
                  colors: [
                    const Color(0xFFFFECEB).withValues(alpha: 0.75),
                    const Color(0xFFFFF8F2),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ─── Main Splash Content ───
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ─── Glowing Aura & Brand Logo ───
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.04);
                        final auraOpacity = 0.15 + (_pulseController.value * 0.12);

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: auraOpacity),
                                  blurRadius: 40 + (_pulseController.value * 20),
                                  spreadRadius: 4 + (_pulseController.value * 6),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'crush_logo_hero',
                        child: Image.asset(
                          'assets/images/logo_wordmark.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 650.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.88, 0.88),
                        end: const Offset(1.0, 1.0),
                        duration: 650.ms,
                        curve: Curves.easeOutBack,
                      )
                      .shimmer(
                        delay: 600.ms,
                        duration: 1200.ms,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),

                  const SizedBox(height: 14),

                  // ─── Tagline ───
                  Text(
                    'Spark genuine connections',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 600.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.35,
                        end: 0,
                        delay: 350.ms,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const Spacer(flex: 3),

                  // ─── Sleek Bottom Loading Indicator ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: SizedBox(
                      width: 140,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: Color(0xFFFFE0DC),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms),

                  const SizedBox(height: 18),

                  // ─── Subtitle & Brand Tag ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'For unspoken love',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
