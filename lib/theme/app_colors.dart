import 'package:flutter/material.dart';

class AppColors {
  // Main colors extracted from the provided logo
  static const Color primaryBlue = Color(0xFF165CA3); // The cross color
  static const Color textNavy = Color(0xFF0B1B3D);    // The "NEUROGUARD" text color
  
  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8F9FA);  // Very light grey/blue for app bg
  static const Color surface = Colors.white;          // Pure white for cards/charts
  
  // States
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFED6C02);
  static const Color inactive = Color(0xFF9E9E9E);

  // Grey shades for text and borders
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1A000000); // 10% black

  // Graph Channel Colors (Designed to pop on a white background)
  static const List<Color> channelColors = [
    Color(0xFF165CA3), // CH1: Primary Blue (matches logo)
    Color(0xFFE64A19), // CH2: Deep Orange
    Color(0xFF2E7D32), // CH3: Forest Green
    Color(0xFF6A1B9A), // CH4: Deep Purple
  ];
}