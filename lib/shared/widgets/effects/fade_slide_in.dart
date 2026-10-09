import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// Faz o filho entrar subindo, crescendo de leve e aparecendo — com um
/// pequeno quique no fim —, uma vez só, quando é montado. [index]
/// escalona a entrada dos blocos de uma página: cada um começa
/// [Motion.stagger] depois do anterior, até um teto — numa lista longa os
/// últimos não podem ficar esperando.
///
/// Com "reduzir movimento" ligado no sistema, o filho aparece direto.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
  late final Animation<double> _move = CurvedAnimation(parent: _controller, curve: Motion.spring);
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted || _delay != null) return;

    if (context.reduceMotion) {
      _controller.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, 8);
    _delay = Timer(Motion.stagger * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _move.value)),
          child: Transform.scale(
            scale: 0.97 + 0.03 * _move.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}
