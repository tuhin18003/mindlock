import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFF6C63FF);
  static const Color brandSecondary = Color(0xFF3ECFCF);
  static const Color brandAccent = Color(0xFFFF6B6B);

  // Neutrals
  static const Color black = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color surfaceHighlight = Color(0xFF252535);
  static const Color border = Color(0xFF2E2E42);
  static const Color borderSubtle = Color(0xFF1E1E2E);

  // Text
  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textTertiary = Color(0xFF6B6B8A);
  static const Color textDisabled = Color(0xFF3E3E55);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successSurface = Color(0xFF1A2E1A);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningSurface = Color(0xFF2E2000);
  static const Color error = Color(0xFFEF5350);
  static const Color errorSurface = Color(0xFF2E1A1A);
  static const Color info = Color(0xFF2196F3);
  static const Color infoSurface = Color(0xFF0A1E2E);

  // Feature-specific
  static const Color recoveredTime = Color(0xFF4CAF50);
  static const Color blockedTime = Color(0xFF6C63FF);
  static const Color screenTime = Color(0xFFFF9800);
  static const Color focusSession = Color(0xFF3ECFCF);
  static const Color streak = Color(0xFFFFD700);
  static const Color emergencyUnlock = Color(0xFFFF6B6B);
  static const Color lockOverlay = Color(0xE6000000);

  // Pro badge
  static const Color proBadgeGold = Color(0xFFFFD700);
  static const Color proBadgeSurface = Color(0xFF2A2000);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, brandSecondary],
  );

  static const LinearGradient recoveryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF3ECFCF)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFFF9800)],
  );
}
