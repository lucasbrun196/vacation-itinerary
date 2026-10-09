import 'package:flutter/material.dart';

/// Espaçamentos em escala de 4pt.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  static const hXs = SizedBox(width: xs);
  static const hSm = SizedBox(width: sm);
  static const hMd = SizedBox(width: md);
  static const hLg = SizedBox(width: lg);
  static const hXl = SizedBox(width: xl);

  static const vXs = SizedBox(height: xs);
  static const vSm = SizedBox(height: sm);
  static const vMd = SizedBox(height: md);
  static const vLg = SizedBox(height: lg);
  static const vXl = SizedBox(height: xl);
  static const vXxl = SizedBox(height: xxl);
}

/// Cantos arredondados e amigáveis. Botões e campos usam `md`, cartões
/// `lg`, painéis de destaque `xl`.
abstract final class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const pill = 999.0;

  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
  static const brPill = BorderRadius.all(Radius.circular(pill));
}

/// Durações e curvas padronizadas — animação inconsistente parece bug.
///
/// Interação responde rápido; o que entra em cena pode ter um leve
/// "quique" ([spring]), que é o que dá o ar alegre sem cansar.
abstract final class Motion {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 360);
  static const lazy = Duration(milliseconds: 500);

  /// Valores que "contam" até o total e barras que enchem.
  static const reveal = Duration(milliseconds: 900);

  /// Intervalo entre os blocos de uma página que entram em sequência.
  static const stagger = Duration(milliseconds: 55);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// Passa um pouco do alvo e volta: para entradas e seleções.
  static const spring = Curves.easeOutBack;
  static const smooth = Curves.easeInOutCubic;
}
