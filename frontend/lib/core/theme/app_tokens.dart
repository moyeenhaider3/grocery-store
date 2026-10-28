import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 72;
}

class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

class AppWidths {
  static const double content = 1200;
  static const double form = 760;
  static const double auth = 440;
  static const double narrow = 960;
}

class AppSizes {
  static const double minTap = 40;
  static const double buttonHeight = 48;
  static const double buttonHeightLarge = 56;
  static const double headerHeight = 68;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration image = Duration(milliseconds: 600);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}

/// Layered, low-contrast shadows. Dark mode leans on surfaces instead, so shadows get deeper but
/// stay subtle.
class AppShadows {
  static List<BoxShadow> soft(Brightness b) => [
    BoxShadow(color: _ink(b, 0.04), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: _ink(b, 0.05), blurRadius: 16, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> lifted(Brightness b) => [
    BoxShadow(color: _ink(b, 0.06), blurRadius: 4, offset: const Offset(0, 2)),
    BoxShadow(color: _ink(b, 0.14), blurRadius: 40, spreadRadius: -8, offset: const Offset(0, 22)),
  ];

  static List<BoxShadow> bar(Brightness b) => [
    BoxShadow(color: _ink(b, 0.08), blurRadius: 24, offset: const Offset(0, -6)),
  ];

  static Color _ink(Brightness b, double a) =>
      (b == Brightness.dark ? Colors.black : const Color(0xFF1A1D29)).withValues(alpha: b == Brightness.dark ? a * 3 : a);
}

/// Product grid maths shared by the real grid and its skeleton so nothing jumps on load.
class ProductGridGeometry {
  final int columns;
  final double spacing;
  final double tileWidth;

  /// Height of the text block under the square image.
  static const double infoHeight = 104;

  const ProductGridGeometry._(this.columns, this.spacing, this.tileWidth);

  factory ProductGridGeometry.of(double width) {
    final double spacing;
    final int columns;
    if (width < AppBreakpoints.tablet) {
      spacing = AppSpacing.md;
      columns = 2;
    } else if (width < AppBreakpoints.desktop) {
      spacing = AppSpacing.xl - 4;
      columns = math.max(2, ((width + spacing) / (220 + spacing)).floor());
    } else {
      spacing = AppSpacing.xl;
      columns = math.max(3, ((width + spacing) / (250 + spacing)).floor());
    }
    return ProductGridGeometry._(columns, spacing, (width - spacing * (columns - 1)) / columns);
  }

  double get tileHeight => tileWidth + infoHeight;
}

extension ResponsiveContext on BuildContext {
  bool get isPhone => MediaQuery.sizeOf(this).width < AppBreakpoints.tablet;
  bool get isTablet {
    final w = MediaQuery.sizeOf(this).width;
    return w >= AppBreakpoints.tablet && w <= AppBreakpoints.desktop;
  }

  bool get isDesktop => MediaQuery.sizeOf(this).width > AppBreakpoints.desktop;

  /// Horizontal page gutter for the current width class.
  double get gutter {
    if (isPhone) return AppSpacing.lg;
    if (isTablet) return AppSpacing.xl;
    return AppSpacing.xxl;
  }

  EdgeInsets get pagePadding {
    if (isPhone) return const EdgeInsets.fromLTRB(16, 20, 16, 32);
    if (isTablet) return const EdgeInsets.fromLTRB(24, 28, 24, 40);
    return const EdgeInsets.fromLTRB(32, 36, 32, 56);
  }
}
