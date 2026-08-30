import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Barra de progresso de pagamento: preenche com curva suave e muda de
/// cor conforme se aproxima de 100%.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.backgroundColor,
    this.duration = Motion.lazy,
  });

  /// Fração de 0 a 1.
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final Duration duration;

  static Color colorFor(double fraction) {
    if (fraction >= 0.999) return AppColors.success;
    if (fraction >= 0.6) return AppColors.turquoise;
    if (fraction >= 0.3) return AppColors.sunset;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final barColor = color ?? colorFor(target);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: backgroundColor ?? context.colors.surfaceContainerHighest),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: context.reduceMotion ? Duration.zero : duration,
              curve: Motion.smooth,
              builder: (context, v, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withValues(alpha: 0.75), barColor],
                      ),
                      borderRadius: BorderRadius.circular(height),
                    ),
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
