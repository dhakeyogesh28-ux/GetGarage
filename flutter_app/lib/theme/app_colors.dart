import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF111418);
  static const Color foreground = Color(0xFFEFF3F7);
  static const Color card = Color(0xFF1A1E24);
  static const Color cardForeground = Color(0xFFEFF3F7);
  
  static const Color primary = Color(0xFFFF9519);
  static const Color primaryForeground = Color(0xFF111418);
  
  static const Color secondary = Color(0xFF272D36);
  static const Color secondaryForeground = Color(0xFFEFF3F7);
  
  static const Color muted = Color(0xFF2B313B);
  static const Color mutedForeground = Color(0xFF8C96A3);
  
  static const Color success = Color(0xFF20C55E);
  static const Color warning = Color(0xFFEBAC08);
  static const Color info = Color(0xFF0DA5E9);
  static const Color destructive = Color(0xFFEF4444);
  
  static const Color border = Color(0xFF2B313B);
  static const Color input = Color(0xFF272D36);
  
  static const Color sidebarBackground = Color(0xFF0D0F12);
  static const Color sidebarForeground = Color(0xFFEFF3F7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9519), Color(0xFFE67E00)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF242930), Color(0xFF1A1E24)],
  );
}
