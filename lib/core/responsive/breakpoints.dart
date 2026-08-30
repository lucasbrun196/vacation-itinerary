import 'package:flutter/widgets.dart';

enum ScreenSize { mobile, tablet, desktop, wide }

/// Nunca perguntamos "é web ou mobile?", apenas "qual a largura?".
/// Assim uma janela estreita no desktop se comporta como celular.
abstract final class Breakpoints {
  /// Abaixo disso não cabem duas colunas de nada: campos, botões e cartões
  /// lado a lado precisam empilhar. É o celular pequeno de verdade.
  static const compact = 380.0;

  static const tablet = 700.0;
  static const desktop = 1100.0;
  static const wide = 1500.0;

  /// Largura máxima do conteúdo: texto em linha muito longa cansa a leitura.
  static const contentMaxWidth = 1240.0;

  static ScreenSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  /// Tela estreita demais para qualquer arranjo horizontal.
  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static ScreenSize fromWidth(double width) {
    if (width >= wide) return ScreenSize.wide;
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}
