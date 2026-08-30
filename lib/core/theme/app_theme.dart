import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurface = isDark ? const Color(0xFFF1F5F9) : AppColors.ink;
    final muted = isDark ? const Color(0xFF94A3B8) : AppColors.inkMuted;
    final outline = isDark ? AppColors.darkOutline : AppColors.outline;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.coral,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF3D2222) : AppColors.coralSoft,
      onPrimaryContainer: isDark ? AppColors.coralSoft : AppColors.deepSea,
      secondary: AppColors.turquoise,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF17383A) : AppColors.turquoiseSoft,
      onSecondaryContainer: isDark ? AppColors.turquoiseSoft : AppColors.deepSea,
      tertiary: AppColors.sunset,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF3B2A18) : AppColors.sunsetSoft,
      onTertiaryContainer: isDark ? AppColors.sunsetSoft : AppColors.deepSea,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      surfaceContainerLowest: isDark ? const Color(0xFF0B121A) : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF121C26) : const Color(0xFFFFFBF7),
      surfaceContainer: isDark ? AppColors.darkSurface : AppColors.sand,
      surfaceContainerHigh: isDark ? const Color(0xFF1C2836) : const Color(0xFFFDF2E7),
      surfaceContainerHighest: isDark ? const Color(0xFF23303F) : const Color(0xFFF7E9DC),
      outline: outline,
      outlineVariant: outline,
      inverseSurface: onSurface,
      onInverseSurface: surface,
    );

    final textTheme = AppTypography.textTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: onSurface),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.brPill),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.brPill),
          side: BorderSide(color: outline, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: Radii.brPill),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 2,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brLg),
        extendedTextStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF101A24) : const Color(0xFFFFFBF7),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.lg),
        border: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: outline, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: outline, width: 1.4),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: AppColors.coral, width: 1.8),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: AppColors.danger, width: 1.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1C2836) : AppColors.sand,
        selectedColor: AppColors.coral,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brPill),
        labelStyle: textTheme.labelMedium?.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.coralSoft,
        indicatorShape: const RoundedRectangleBorder(borderRadius: Radii.brPill),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? AppColors.coral : muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? AppColors.coral : muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.coralSoft,
        indicatorShape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        selectedIconTheme: const IconThemeData(color: AppColors.coral, size: 24),
        unselectedIconTheme: IconThemeData(color: muted, size: 24),
        selectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: AppColors.coral, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brXl),
        titleTextStyle: textTheme.headlineSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepSea,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        insetPadding: const EdgeInsets.all(Gap.lg),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.deepSea, borderRadius: Radii.brSm),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
        linearTrackColor: AppColors.coralSoft,
        linearMinHeight: 8,
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.xs),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
      ),
    );
  }
}
