import 'package:flutter/material.dart';

/// Application color constants
/// 
/// Centralized color definitions for consistent theming
class AppColors {
  AppColors._(); // Private constructor

  // Primary Colors
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);

  // Status Colors
  static const Color statusAvailable = Color(0xFF4CAF50);
  static const Color statusOccupied = Color(0xFFF44336);
  static const Color statusCleaning = Color(0xFFFF9800);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF1A1F2C);

  // Text Colors
  static const Color textMainLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF2A2A3E);

  // Error & Success
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

