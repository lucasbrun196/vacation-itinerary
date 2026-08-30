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

/// Cantos generosos: a diferença principal entre "app de viagem" e "sistema".
abstract final class Radii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
  static const brPill = BorderRadius.all(Radius.circular(pill));
}

/// Durações e curvas padronizadas — animação inconsistente parece bug.
abstract final class Motion {
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 220);
  static const normal = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 550);
  static const lazy = Duration(milliseconds: 800);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const spring = Curves.easeOutBack;
  static const smooth = Curves.easeInOutCubic;
}
