import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFEC4899); // Pink

  // Light Mode Colors
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0B0F19); // Deep space dark
  static const Color surfaceDark = Color(0xFF161E2E); // Dark blue-grey card
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark = Color(0xFF2E3B4E); // Darker border

  // Semantic Colors
  static const Color homeMarker = Color(0xFFEF4444); // Red for Home base
  static const Color visited = Color(0xFF10B981); // Emerald Green
  static const Color pending = Color(0xFFF59E0B); // Amber
  
  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkBackgroundGradient = LinearGradient(
    colors: [bgDark, Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
}
