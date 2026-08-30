import 'package:flutter/material.dart';

/// Paleta da viagem: pôr do sol encontrando o oceano.
///
/// As cores são pensadas em pares (base + suave) para permitir fundos
/// delicados sem recorrer a opacidade em cima de imagens.
abstract final class AppColors {
  // Cores da marca
  static const coral = Color(0xFFFF6B6B);
  static const coralSoft = Color(0xFFFFE5E3);
  static const sunset = Color(0xFFFFA45B);
  static const sunsetSoft = Color(0xFFFFEEDC);
  static const turquoise = Color(0xFF4ECDC4);
  static const turquoiseSoft = Color(0xFFDFF6F4);
  static const deepSea = Color(0xFF1A535C);
  static const sand = Color(0xFFFFF6EC);
  static const palm = Color(0xFF2EC4A6);
  static const sky = Color(0xFF5AA9E6);
  static const grape = Color(0xFF9B7EDE);

  // Neutros quentes (nunca cinza puro: cinza puro deixa a tela corporativa)
  static const ink = Color(0xFF1B2430);
  static const inkMuted = Color(0xFF5E6B7A);
  static const inkFaint = Color(0xFF95A1AF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFDF8F3);
  static const outline = Color(0xFFEDE4DA);

  // Neutros do tema escuro
  static const darkBackground = Color(0xFF0E1620);
  static const darkSurface = Color(0xFF16212E);
  static const darkOutline = Color(0xFF25323F);

  // Semânticas
  static const success = Color(0xFF2EC4A6);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFF2545B);

  // Gradientes
  static const sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, sunset],
  );

  static const oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [turquoise, sky],
  );

  static const twilightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [grape, coral],
  );

  static const tropicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [palm, turquoise],
  );

  /// Sombra colorida: mais viva que o cinza padrão do Material.
  static List<BoxShadow> glow(Color color, {double opacity = 0.28, double blur = 24, double y = 10}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
