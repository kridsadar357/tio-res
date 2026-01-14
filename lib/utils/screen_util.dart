import 'package:flutter/material.dart';

/// ScreenUtil: Global utility for responsive UI design
///
/// Calculates screen dimensions and provides scaling factors for fonts and widgets
/// Ensures consistent UI across different tablet sizes
class ScreenUtil {
  static final ScreenUtil _instance = ScreenUtil._internal();
  factory ScreenUtil() => _instance;
  ScreenUtil._internal();

  // Screen dimensions
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double pixelRatio = 0;

  // Reference design dimensions (tablet landscape)
  // Designing for a typical 10" tablet in landscape mode
  static const double referenceWidth = 1280;
  static const double referenceHeight = 800;

  // Scaling factors
  static double get scaleFactor => screenWidth / referenceWidth;
  static double get scaleFactorH => screenHeight / referenceHeight;

  // Font scaling
  static double get fontScale => (scaleFactor + scaleFactorH) / 2;

  /// Initialize screen dimensions
  /// Must be called in main.dart before any UI rendering
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
  }

  /// Scale a dimension based on width
  static double setWidth(double width) => width * scaleFactor;

  /// Scale a dimension based on height
  static double setHeight(double height) => height * scaleFactorH;

  /// Scale a font size
  static double setFontSize(double fontSize) => fontSize * fontScale;

  /// Scale based on the smaller dimension
  static double setMin(double value) =>
      value * (scaleFactor < scaleFactorH ? scaleFactor : scaleFactorH);

  /// Scale based on the larger dimension
  static double setMax(double value) =>
      value * (scaleFactor > scaleFactorH ? scaleFactor : scaleFactorH);

  /// Get responsive spacing
  static double spacing(double value) => setMin(value);

  /// Get responsive padding
  static double padding(double value) => setMin(value);

  /// Get responsive border radius
  static double radius(double value) => setMin(value);

  // Pre-calculated common values for convenience
  static double get screenPadding => spacing(16);
  static double get cardPadding => spacing(12);
  static double get sectionPadding => spacing(24);
  static double get iconSize => setMin(24);
  static double get largeIconSize => setMin(32);
  static double get buttonHeight => setHeight(48);
  static double get cardElevation => 2.0;

  // Font sizes
  static double get fontSizeSmall => setFontSize(12);
  static double get fontSizeNormal => setFontSize(14);
  static double get fontSizeMedium => setFontSize(16);
  static double get fontSizeLarge => setFontSize(18);
  static double get fontSizeXLarge => setFontSize(20);
  static double get fontSizeXXLarge => setFontSize(24);
  static double get fontSizeXXXLarge => setFontSize(32);

  /// Check if device is a tablet (width > 600 in logical pixels)
  static bool get isTablet => screenWidth > 600;

  /// Check if device is in landscape mode
  static bool get isLandscape => screenWidth > screenHeight;

  /// Get screen orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Safe area padding (handles notches and system bars)
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Get screen type for conditional UI
  static ScreenType get screenType {
    if (screenWidth < 600) return ScreenType.mobile;
    if (screenWidth < 900) return ScreenType.smallTablet;
    if (screenWidth < 1200) return ScreenType.mediumTablet;
    return ScreenType.largeTablet;
  }
}

/// Screen types for conditional UI
enum ScreenType {
  mobile,
  smallTablet,
  mediumTablet,
  largeTablet,
}

/// Extension on double to easily scale values
extension ScreenUtilExtension on double {
  double get w => ScreenUtil.setWidth(this);
  double get h => ScreenUtil.setHeight(this);
  double get sp => ScreenUtil.setFontSize(this);
  double get r => ScreenUtil.radius(this);
}

/// Extension on int to easily scale values
extension ScreenUtilIntExtension on int {
  double get w => ScreenUtil.setWidth(toDouble());
  double get h => ScreenUtil.setHeight(toDouble());
  double get sp => ScreenUtil.setFontSize(toDouble());
  double get r => ScreenUtil.radius(toDouble());
}
