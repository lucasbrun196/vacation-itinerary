import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Geist no texto inteiro; Geist Mono em tudo que é número para comparar
/// — dinheiro, horário, data curta, contador.
abstract final class AppTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Título: peso 600 com espaçamento negativo de 2% do tamanho.
  static TextStyle _heading(double size, Color color, {double height = 1.2}) => GoogleFonts.geist(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: height,
        letterSpacing: -0.02 * size,
        color: color,
      );

  static TextStyle _body(double size, Color color,
          {FontWeight weight = FontWeight.w400, double height = 1.5}) =>
      GoogleFonts.geist(fontSize: size, fontWeight: weight, height: height, color: color);

  static TextTheme textTheme(Color onSurface, Color muted) {
    return TextTheme(
      displayLarge: _heading(48, onSurface, height: 1.05),
      displayMedium: _heading(40, onSurface, height: 1.1),
      displaySmall: _heading(32, onSurface, height: 1.15),
      headlineLarge: _heading(28, onSurface),
      headlineMedium: _heading(24, onSurface),
      headlineSmall: _heading(20, onSurface, height: 1.3),
      titleLarge: _heading(16, onSurface, height: 1.35),
      titleMedium: _heading(15, onSurface, height: 1.4),
      titleSmall: _heading(14, onSurface, height: 1.4),
      bodyLarge: _body(15, onSurface),
      bodyMedium: _body(14, onSurface),
      bodySmall: _body(13, muted),
      labelLarge: _body(14, onSurface, weight: FontWeight.w500, height: 1.3),
      labelMedium: _body(12, muted, height: 1.3),
      labelSmall: _body(12, muted, height: 1.3),
    );
  }

  /// Valores monetários: mono e tabular, para as colunas não "dançarem".
  static TextStyle money({double size = 24, FontWeight weight = FontWeight.w500, Color? color}) =>
      mono(size: size, weight: weight, color: color);

  /// Horários, datas curtas, contadores — qualquer número em coluna.
  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.geistMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: size >= 24 ? -0.02 * size : 0,
        fontFeatures: _tabular,
      );
}
