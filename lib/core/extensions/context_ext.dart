import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  ScreenSize get breakpoint => Breakpoints.of(this);
  bool get isMobile => breakpoint == ScreenSize.mobile;
  bool get isTablet => breakpoint == ScreenSize.tablet;
  bool get isDesktop => breakpoint == ScreenSize.desktop || breakpoint == ScreenSize.wide;
  bool get isCompact => breakpoint == ScreenSize.mobile || breakpoint == ScreenSize.tablet;

  /// Mais estreito que [isMobile]: o celular onde nada cabe lado a lado.
  /// É o gatilho para empilhar campos, botões e ações de cabeçalho.
  bool get isNarrow => Breakpoints.isNarrow(this);

  /// Respeita a preferência de acessibilidade de reduzir animações.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  void showSnack(String message, {bool isError = false, IconData? icon}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12)],
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
