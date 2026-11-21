import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Signature Accent (Punchy Peach-Coral) ────────────────────────
  static const Color primary       = Color(0xFFFF5364); // Vibrant Coral-Pink
  static const Color primaryAccent = Color(0xFFFF7A68); // Warm Peach-Coral
  static const Color secondary     = Color(0xFFFF5364);
  static const Color tertiary      = Color(0xFFFFECEB); // Soft subtle coral tint

  // ─── Backgrounds & Surfaces (Crisp, High-Contrast Modern Light) ──────────
  static const Color background    = Color(0xFFFFFFFF); // Pure White – never muddy
  static const Color surface       = Color(0xFFFFFFFF); // Pure White cards
  static const Color surfaceLight  = Color(0xFFF3F4F6); // Clean Light Gray (search, bubbles, inputs)
  static const Color cardBorder    = Color(0xFFE5E7EB); // Crisp border definition

  // ─── Typography (High Contrast, Crystal Clear) ──────────────────────────
  static const Color textPrimary   = Color(0xFF111827); // Dark Charcoal / Near Black
  static const Color textSecondary = Color(0xFF4B5563); // Slate Gray – readable body
  static const Color textMuted     = Color(0xFF9CA3AF); // Crisp Neutral Gray – timestamps, hints

  // ─── Swipe Action Colors ────────────────────────────────────────────────
  static const Color like      = Color(0xFF10B981); // Emerald Green
  static const Color nope      = Color(0xFFEF4444); // Crimson Red
  static const Color superLike = Color(0xFF3B82F6); // Electric Blue
  static const Color rewind    = Color(0xFFF59E0B); // Amber Sun
  static const Color boost     = Color(0xFF8B5CF6); // Royal Purple

  // ─── Aliases ────────────────────────────────────────────────────────────
  static const Color lightBackground   = background;
  static const Color lightSurface      = surface;
  static const Color lightTextPrimary  = textPrimary;
  static const Color lightTextSecondary = textSecondary;

  // ─── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryAccent],
  );

  /// Card overlay gradient to guarantee white name & age are 100% readable
  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 0.65, 1.0],
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color(0x66000000),
      Color(0xDD000000),
    ],
  );

  /// Match celebration gradient
  static const LinearGradient matchCelebrationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF5364), Color(0xFFFF8E72)],
  );
}
