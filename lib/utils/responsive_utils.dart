import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 400;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 400 && width < 800;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 800;
  }

  static bool isTablet(BuildContext context) {
    return getScreenWidth(context) >= 600;
  }

  static bool isPhone(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  static bool isSmallHeight(BuildContext context) {
    return getScreenHeight(context) < 700;
  }

  static bool isVerySmallHeight(BuildContext context) {
    return getScreenHeight(context) < 600;
  }

  // Responsive font sizes
  static double getResponsiveFontSize(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = getScreenWidth(context);
    
    if (isSmallScreen(context)) {
      return small ?? 14.0;
    } else if (isMediumScreen(context)) {
      return medium ?? 16.0;
    } else if (isLargeScreen(context)) {
      return large ?? 18.0;
    } else if (isTablet(context)) {
      return tablet ?? 20.0;
    }
    
    return medium ?? 16.0;
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, {
    double? small,
    double? medium,
    double? large,
  }) {
    final height = getScreenHeight(context);
    
    if (isVerySmallHeight(context)) {
      return small ?? 8.0;
    } else if (isSmallHeight(context)) {
      return medium ?? 12.0;
    } else {
      return large ?? 16.0;
    }
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    
    double hPadding = horizontal ?? (isSmallScreen(context) ? 12.0 : 16.0);
    double vPadding = vertical ?? (isSmallHeight(context) ? 8.0 : 12.0);
    
    return EdgeInsets.only(
      left: left ?? hPadding,
      right: right ?? hPadding,
      top: top ?? vPadding,
      bottom: bottom ?? vPadding,
    );
  }

  // Responsive margins
  static EdgeInsets getResponsiveMargin(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final width = getScreenWidth(context);
    final height = getScreenHeight(context);
    
    double hMargin = horizontal ?? (isSmallScreen(context) ? 8.0 : 12.0);
    double vMargin = vertical ?? (isSmallHeight(context) ? 6.0 : 10.0);
    
    return EdgeInsets.only(
      left: left ?? hMargin,
      right: right ?? hMargin,
      top: top ?? vMargin,
      bottom: bottom ?? vMargin,
    );
  }

  // Responsive icon sizes
  static double getResponsiveIconSize(BuildContext context, {
    double? small,
    double? medium,
    double? large,
  }) {
    final width = getScreenWidth(context);
    
    if (isSmallScreen(context)) {
      return small ?? 16.0;
    } else if (isMediumScreen(context)) {
      return medium ?? 20.0;
    } else {
      return large ?? 24.0;
    }
  }

  // Responsive container sizes
  static double getResponsiveContainerSize(BuildContext context, {
    double? small,
    double? medium,
    double? large,
    double? tablet,
  }) {
    final width = getScreenWidth(context);
    
    if (isSmallScreen(context)) {
      return small ?? 40.0;
    } else if (isMediumScreen(context)) {
      return medium ?? 50.0;
    } else if (isLargeScreen(context)) {
      return large ?? 60.0;
    } else if (isTablet(context)) {
      return tablet ?? 70.0;
    }
    
    return medium ?? 50.0;
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, {
    double? small,
    double? medium,
    double? large,
  }) {
    final width = getScreenWidth(context);
    
    if (isSmallScreen(context)) {
      return small ?? 8.0;
    } else if (isMediumScreen(context)) {
      return medium ?? 12.0;
    } else {
      return large ?? 16.0;
    }
  }

  // Responsive height calculation
  static double getResponsiveHeight(BuildContext context, double percentage) {
    final height = getScreenHeight(context);
    return height * percentage;
  }

  // Responsive width calculation
  static double getResponsiveWidth(BuildContext context, double percentage) {
    final width = getScreenWidth(context);
    return width * percentage;
  }

  // Responsive aspect ratio
  static double getResponsiveAspectRatio(BuildContext context, {
    double? phone,
    double? tablet,
  }) {
    if (isTablet(context)) {
      return tablet ?? 16 / 9;
    } else {
      return phone ?? 4 / 3;
    }
  }
} 