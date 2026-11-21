import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Palette (Warm Peach / Coral) ─────────────────────────────────
  static const Color primary       = Color(0xFFFF9B85); // Peach Coral   – primary brand
  static const Color primaryAccent = Color(0xFFFFC4A8); // Soft Peach    – secondary brand
  static const Color secondary     = Color(0xFFFF9B85); // same as primary for gradient
  static const Color tertiary      = Color(0xFFFFE5D4); // Blush Cream   – highlights

  // ─── Backgrounds & Surfaces ─────────────────────────────────────────────
  static const Color background  = Color(0xFFFFF8F2); // Warm Ivory    – scaffold bg
  static const Color surface     = Color(0xFFFFFFFF); // Pure White    – cards / sheets
  static const Color surfaceLight = Color(0xFFFFF1E9); // Light Peach   – input fills / chips
  static const Color cardBorder  = Color(0xFFFFD9C8); // Soft border

  // ─── Typography ─────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF59423D); // Cocoa Brown   – headings
  static const Color textSecondary = Color(0xFF92756C); // Muted Rose    – body / captions
  static const Color textMuted     = Color(0xFFBFA59F); // Dusty Blush   – placeholders

  // ─── Swipe Action Colors (unchanged – universally recognised) ───────────
  static const Color like      = Color(0xFF20BF6B); // Emerald Green
  static const Color nope      = Color(0xFFEB3B5A); // Crimson Red
  static const Color superLike = Color(0xFF3867D6); // Electric Blue
  static const Color rewind    = Color(0xFFF7B731); // Golden Sun
  static const Color boost     = Color(0xFF8854D0); // Royal Purple

  // ─── Light-theme aliases (kept for reference) ───────────────────────────
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

  /// Warm gradient used on swipe cards (bottom overlay keeps readability)
  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 0.65, 1.0],
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color(0x55000000),
      Color(0xCC000000),
    ],
  );

  /// Match celebration — warm rose instead of dark purple
  static const LinearGradient matchCelebrationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF9B85), Color(0xFFFFC4A8)],
  );
}
