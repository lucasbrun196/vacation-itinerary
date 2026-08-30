import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';

/// Valor monetário que "conta" de 0 até o total ao aparecer, e anima
/// suavemente sempre que o valor muda.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.value, {
    super.key,
    this.style,
    this.duration = Motion.lazy,
    this.compact = false,
  });

  final num value;
  final TextStyle? style;
  final Duration duration;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effective = style ?? context.text.headlineMedium;
    if (context.reduceMotion) {
      return Text(compact ? Fmt.moneyCompact(value) : Fmt.money(value), style: effective);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Motion.smooth,
      builder: (context, v, _) => Text(
        compact ? Fmt.moneyCompact(v) : Fmt.money(v),
        style: effective,
      ),
    );
  }
}

/// Contador inteiro animado (nº de fotos, dias, itens...).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(this.value, {super.key, this.style, this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.slow,
      curve: Motion.smooth,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
