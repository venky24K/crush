import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Signature Crush Brand Gradients & Colors
  static const Color primary = Color(0xFFFD297B); // Vibrant Rose Pink
  static const Color primaryAccent = Color(0xFFFF5864); // Sunset Coral
  static const Color secondary = Color(0xFFFF655B); // Warm Orange-Pink
  static const Color tertiary = Color(0xFF6C5CE7); // Deep Romantic Violet

  // Match / Swiping Action Colors
  static const Color like = Color(0xFF20BF6B); // Fresh Emerald Green
  static const Color nope = Color(0xFFEB3B5A); // Bright Crimson
  static const Color superLike = Color(0xFF3867D6); // Electric Blue
  static const Color rewind = Color(0xFFF7B731); // Golden Sun
  static const Color boost = Color(0xFF8854D0); // Royal Purple

  // Neutral Tones
  static const Color background = Color(0xFF0F0E17); // Premium Dark Background
  static const Color surface = Color(0xFF1E1E28); // Card/Surface Dark
  static const Color surfaceLight = Color(0xFF2A2A38);
  static const Color cardBorder = Color(0xFF323244);

  static const Color textPrimary = Color(0xFFFFFFFE);
  static const Color textSecondary = Color(0xFFA7A9BE);
  static const Color textMuted = Color(0xFF6B6E82);

  // Light theme fallbacks
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A1A24);
  static const Color lightTextSecondary = Color(0xFF5F6368);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 0.7, 1.0],
    colors: [
      Colors.transparent,
      Colors.transparent,
      Colors.black38,
      Colors.black87,
    ],
  );

  static const LinearGradient matchCelebrationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C0A2E), Color(0xFF0F0E17)],
  );
}
