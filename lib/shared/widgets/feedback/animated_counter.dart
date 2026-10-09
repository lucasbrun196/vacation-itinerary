import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';

/// Valor monetário que conta até o total quando aparece e desliza até o
/// novo valor quando muda. A curva desacelera no fim, então os últimos
/// centavos assentam devagar em vez de "pularem".
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(
    this.value, {
    super.key,
    this.style,
    this.duration = Motion.reveal,
    this.compact = false,
  });

  final num value;
  final TextStyle? style;
  final Duration duration;
  final bool compact;

  String _format(num v) => compact ? Fmt.moneyCompact(v) : Fmt.money(v);

  @override
  Widget build(BuildContext context) {
    final effective = style ?? context.text.headlineMedium;
    if (context.reduceMotion) return Text(_format(value), style: effective);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(_format(v), style: effective),
    );
  }
}

/// Contador inteiro (nº de fotos, dias, itens...), com a mesma entrada.
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
      duration: Motion.reveal,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
