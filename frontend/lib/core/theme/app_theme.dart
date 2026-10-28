import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'status_colors.dart';

/// ShopKart identity: deep ink type and buttons on a warm linen canvas, one persimmon accent used
/// sparingly (badges, eyebrows, highlights), white "paper" cards. Roboto only (no font assets).
class AppTheme {
  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1A1D29),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE7E8EF),
    onPrimaryContainer: Color(0xFF1A1D29),
    secondary: Color(0xFFD9481F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFE4D8),
    onSecondaryContainer: Color(0xFF5A1A06),
    tertiary: Color(0xFF2E6A5C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD8EEE7),
    onTertiaryContainer: Color(0xFF0C3128),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF7F4EF),
    onSurface: Color(0xFF1A1D29),
    onSurfaceVariant: Color(0xFF5C606D),
    surfaceDim: Color(0xFFE2DCD2),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2EEE8),
    surfaceContainer: Color(0xFFEDE8E0),
    surfaceContainerHigh: Color(0xFFE7E1D8),
    surfaceContainerHighest: Color(0xFFE1DAD0),
    outline: Color(0xFF8B8E99),
    outlineVariant: Color(0xFFE3DDD4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1A1D29),
    onInverseSurface: Color(0xFFF4F1EC),
    inversePrimary: Color(0xFFC9CCDB),
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF1EDE6),
    onPrimary: Color(0xFF16181F),
    primaryContainer: Color(0xFF2B2F3B),
    onPrimaryContainer: Color(0xFFF1EDE6),
    secondary: Color(0xFFFF8A61),
    onSecondary: Color(0xFF3A0F02),
    secondaryContainer: Color(0xFF5A2410),
    onSecondaryContainer: Color(0xFFFFDBCC),
    tertiary: Color(0xFF8ED3C0),
    onTertiary: Color(0xFF00382D),
    tertiaryContainer: Color(0xFF16473C),
    onTertiaryContainer: Color(0xFFB7F0DF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF111318),
    onSurface: Color(0xFFECE8E1),
    onSurfaceVariant: Color(0xFFA9ACB6),
    surfaceDim: Color(0xFF111318),
    surfaceBright: Color(0xFF363943),
    surfaceContainerLowest: Color(0xFF181B22),
    surfaceContainerLow: Color(0xFF16181E),
    surfaceContainer: Color(0xFF1D2028),
    surfaceContainerHigh: Color(0xFF252831),
    surfaceContainerHighest: Color(0xFF2E323C),
    outline: Color(0xFF7D808B),
    outlineVariant: Color(0xFF2C2F38),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFECE8E1),
    onInverseSurface: Color(0xFF1A1D29),
    inversePrimary: Color(0xFF1A1D29),
    surfaceTint: Colors.transparent,
  );

  static TextTheme _text(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness, useMaterial3: true).textTheme;
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.02),
          displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.6, height: 1.04),
          displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.1, height: 1.08),
          headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.9, height: 1.12),
          headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.7, height: 1.15),
          headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.35),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.6, letterSpacing: 0.1),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.5, letterSpacing: 0.1),
          bodySmall: base.bodySmall?.copyWith(height: 1.45, letterSpacing: 0.2),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
          labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
          // Eyebrow / overline style.
          labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.4, height: 1.3),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static ThemeData _build(ColorScheme scheme) {
    final b = scheme.brightness;
    final isDark = b == Brightness.dark;
    final textTheme = _text(scheme);

    final mdShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    const buttonMin = Size(64, AppSizes.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22);
    final buttonText = textTheme.labelLarge?.copyWith(letterSpacing: 0.2);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
    final paper = scheme.surfaceContainerLowest;
    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(paper),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: isDark ? 0.6 : 0.18)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: AppSpacing.sm)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      focusColor: scheme.primary.withValues(alpha: 0.10),
      hoverColor: scheme.primary.withValues(alpha: 0.04),
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [isDark ? StatusColors.dark : StatusColors.light],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMin,
          padding: buttonPadding,
          shape: const StadiumBorder(),
          textStyle: buttonText,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMin,
          padding: buttonPadding,
          shape: const StadiumBorder(),
          textStyle: buttonText,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
          textStyle: buttonText,
          foregroundColor: scheme.onSurface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(AppSizes.minTap, AppSizes.minTap)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        hoverColor: scheme.primary.withValues(alpha: 0.02),
        border: border(scheme.outlineVariant),
        enabledBorder: border(isDark ? scheme.outlineVariant : const Color(0xFFDDD6CC)),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.outlineVariant),
        ),
        color: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : paper),
        checkmarkColor: scheme.onPrimary,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (s) => (textTheme.labelLarge ?? const TextStyle()).copyWith(
            color: s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.secondary,
        textColor: scheme.onSecondary,
        textStyle: textTheme.labelSmall?.copyWith(letterSpacing: 0, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: isDark ? scheme.secondary : const Color(0xFFFFB59A),
        elevation: 6,
        shape: mdShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        constraints: const BoxConstraints(maxWidth: 480),
        titleTextStyle: textTheme.headlineSmall,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSurface),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: paper, surfaceTintColor: Colors.transparent),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(shape: mdShape),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const StadiumBorder(),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      menuTheme: MenuThemeData(style: menuStyle),
      dropdownMenuTheme: DropdownMenuThemeData(menuStyle: menuStyle),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          minimumSize: const Size(200, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: textTheme.bodyMedium,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(AppRadius.xs)),
        textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? 8 : 5),
        radius: const Radius.circular(AppRadius.pill),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => scheme.onSurface.withValues(alpha: s.contains(WidgetState.dragged) ? 0.45 : 0.22),
        ),
        trackVisibility: const WidgetStatePropertyAll(false),
        crossAxisMargin: 3,
        mainAxisMargin: 6,
        interactive: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: AppSizes.headerHeight,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
    );
  }
}

/// Desktop web scrolling without the clutter: a slim auto-hiding scrollbar on vertical page
/// scrolls (drawn at the window edge because pages scroll full-width), none on horizontal strips
/// such as the category pills, and mouse drag allowed so those strips stay reachable.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
  };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (axisDirectionToAxis(details.direction) == Axis.horizontal) return child;
    return super.buildScrollbar(context, child, details);
  }
}
