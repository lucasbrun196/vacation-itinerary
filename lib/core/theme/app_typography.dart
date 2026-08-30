import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Duas famílias: Outfit dá personalidade nos títulos, Inter garante
/// legibilidade em tabelas de valores e textos longos.
abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface, Color muted) {
    final display = GoogleFonts.outfitTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
          fontSize: 52, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: -1.4, color: onSurface),
      displayMedium: display.displayMedium?.copyWith(
          fontSize: 40, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1.0, color: onSurface),
      displaySmall: display.displaySmall?.copyWith(
          fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6, color: onSurface),
      headlineLarge: display.headlineLarge?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5, color: onSurface),
      headlineMedium: display.headlineMedium?.copyWith(
          fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3, color: onSurface),
      headlineSmall: display.headlineSmall?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.2, color: onSurface),
      titleLarge: display.titleLarge?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, color: onSurface),
      titleMedium: display.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: onSurface),
      titleSmall: display.titleSmall?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: onSurface),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.55, color: onSurface),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, height: 1.55, color: onSurface),
      bodySmall: body.bodySmall?.copyWith(fontSize: 13, height: 1.5, color: muted),
      labelLarge: body.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: body.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
      labelSmall: body.labelSmall?.copyWith(
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: muted),
    );
  }

  /// Números de valores monetários: tabular para as colunas não "dançarem".
  static TextStyle money({double size = 24, FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
