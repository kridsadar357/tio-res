import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Extension to get theme-aware text colors
extension ThemeHelper on BuildContext {
  /// Get the primary text color based on current theme
  Color get textColor {
    final theme = Theme.of(this);
    if (theme.brightness == Brightness.dark) {
      return AppTheme.textPrimary;
    } else {
      return AppTheme.textMainLight;
    }
  }

  /// Get the secondary text color based on current theme
  Color get textSecondaryColor {
    final theme = Theme.of(this);
    if (theme.brightness == Brightness.dark) {
      return AppTheme.textSecondary;
    } else {
      return AppTheme.textSecondary.withOpacity(0.7);
    }
  }

  /// Get surface color based on current theme
  Color get surfaceColor {
    final theme = Theme.of(this);
    if (theme.brightness == Brightness.dark) {
      return AppTheme.surface;
    } else {
      return Colors.white;
    }
  }

  /// Get background color based on current theme
  Color get backgroundColor {
    final theme = Theme.of(this);
    if (theme.brightness == Brightness.dark) {
      return AppTheme.background;
    } else {
      return AppTheme.surfaceLight;
    }
  }
}

