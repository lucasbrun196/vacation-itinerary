import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// Sol no escuro, lua no claro: o ícone mostra para onde o toque leva.
/// A troca gira o ícone um quarto de volta enquanto ele aparece.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDark;

    return IconButton(
      tooltip: dark ? 'Tema claro' : 'Tema escuro',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(Theme.of(context).brightness),
      icon: AnimatedSwitcher(
        duration: Motion.slow,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(dark),
          size: 20,
        ),
      ),
    );
  }
}
