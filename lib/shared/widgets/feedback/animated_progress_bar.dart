import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Barra de progresso: enche com uma curva suave, num degradê da cor para
/// um tom mais claro, e quando termina de encher passa um brilho por ela.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.duration = Motion.reveal,
  });

  /// Fração de 0 a 1.
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final Duration duration;

  /// Cor conforme a barra se aproxima de 100%: coral no começo, pêssego no
  /// meio, verde quando completa.
  static Color colorFor(double fraction) {
    if (fraction >= 0.999) return AppColors.success;
    if (fraction >= 0.5) return AppColors.sunset;
    return AppColors.coral;
  }

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    final base = widget.color ?? context.colors.primary;
    final light = Color.lerp(base, Colors.white, context.isDark ? 0.15 : 0.35)!;
    final radius = BorderRadius.circular(widget.height);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Container(color: widget.backgroundColor ?? context.colors.surfaceContainerHigh),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: context.reduceMotion ? Duration.zero : widget.duration,
              curve: Curves.easeOutCubic,
              onEnd: () {
                if (mounted && !context.reduceMotion && target > 0) _shine.forward(from: 0);
              },
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(colors: [base, light]),
                  ),
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) => _shine.isAnimating
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.5 + 3 * _shine.value, 0),
                                end: Alignment(-0.5 + 3 * _shine.value, 0),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
