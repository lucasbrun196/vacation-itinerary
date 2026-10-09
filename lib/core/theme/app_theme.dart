import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
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
    final onSurface = isDark ? AppColors.darkInk : AppColors.ink;
    final muted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final faint = isDark ? AppColors.darkInkMuted : AppColors.inkFaint;
    final outline = isDark ? AppColors.darkOutline : AppColors.outline;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;
    final chip = isDark ? AppColors.darkChip : AppColors.chip;
    final accent = isDark ? AppColors.darkAccent : AppColors.coral;
    final accentSoft = isDark ? AppColors.darkAccentSoft : AppColors.coralSoft;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isDark ? AppColors.darkBackground : Colors.white,
      primaryContainer: accentSoft,
      onPrimaryContainer: accent,
      secondary: onSurface,
      onSecondary: surface,
      secondaryContainer: chip,
      onSecondaryContainer: onSurface,
      tertiary: AppColors.warning,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF2A2219) : AppColors.sunsetSoft,
      onTertiaryContainer: isDark ? const Color(0xFFE0B98C) : AppColors.warning,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      surfaceContainerLowest: surface,
      surfaceContainerLow: background,
      surfaceContainer: background,
      surfaceContainerHigh: chip,
      surfaceContainerHighest: chip,
      outline: outline,
      outlineVariant: divider,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      shadow: Colors.black,
      scrim: Colors.black54,
    );

    final textTheme = AppTypography.textTheme(onSurface, muted);

    const buttonShape = RoundedRectangleBorder(borderRadius: Radii.brMd);
    const buttonSize = Size(0, 44);
    const buttonPadding = EdgeInsets.symmetric(horizontal: Gap.lg);
    final buttonText = textTheme.labelLarge;

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: muted, size: 20),
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
        iconTheme: IconThemeData(color: onSurface, size: 20),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          shadowColor: accent.withValues(alpha: 0.6),
        ).copyWith(
          // Em repouso, chapado; no hover, um halo da própria cor.
          elevation: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.hovered) && !s.contains(WidgetState.disabled) ? 6 : 0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          foregroundColor: accent,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: buttonShape, foregroundColor: muted),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(buttonShape),
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? colorScheme.onPrimary : onSurface,
          ),
        ),
        selectedIcon: const SizedBox.shrink(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: buttonShape,
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 14),
        border: inputBorder(outline),
        enabledBorder: inputBorder(outline),
        disabledBorder: inputBorder(divider),
        focusedBorder: inputBorder(accent, 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
        hintStyle: textTheme.bodyMedium?.copyWith(color: faint),
        helperStyle: textTheme.labelSmall,
        prefixIconColor: faint,
        suffixIconColor: faint,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentSoft : surface,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? accent : outline),
        ),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 13,
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: muted, size: 16),
        showCheckmark: false,
        checkmarkColor: surface,
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
        elevation: 0,
        pressElevation: 0,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 60,
        indicatorColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: s.contains(WidgetState.selected) ? onSurface : faint,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 20,
            color: s.contains(WidgetState.selected) ? onSurface : faint,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: chip,
        indicatorShape: const RoundedRectangleBorder(borderRadius: Radii.brSm),
        selectedIconTheme: IconThemeData(color: onSurface, size: 20),
        unselectedIconTheme: IconThemeData(color: faint, size: 20),
        selectedLabelTextStyle:
            textTheme.labelSmall!.copyWith(color: onSurface, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: textTheme.labelSmall!.copyWith(color: faint),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: outline,
        dragHandleSize: const Size(32, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: outline),
        ),
        titleTextStyle: textTheme.titleLarge,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: outline),
        ),
        dayShape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Radii.brSm),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: outline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brMd,
          side: BorderSide(color: outline),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.brMd, side: BorderSide(color: outline)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        elevation: 0,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        insetPadding: const EdgeInsets.all(Gap.lg),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: onSurface, borderRadius: Radii.brSm),
        textStyle: textTheme.labelSmall?.copyWith(color: surface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: chip,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : outline,
        ),
      ),
      checkboxTheme: const CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: muted,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: onSurface,
        dividerColor: divider,
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Radii.brSm),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        titleTextStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: muted,
      ),
    );
  }
}
