import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Card de destaque com gradiente — usado no herói do dashboard e nos
/// blocos que precisam "puxar" o olhar.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.xl),
    this.borderRadius = Radii.brXl,
    this.decoration = true,
  });

  final Widget child;
  final Gradient gradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Círculos decorativos de fundo, sugerindo sol/bolhas.
  final bool decoration;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            if (decoration) ...[
              Positioned(
                top: -50,
                right: -30,
                child: _bubble(120, 0.16),
              ),
              Positioned(
                bottom: -60,
                right: 60,
                child: _bubble(140, 0.10),
              ),
              Positioned(
                top: 30,
                left: -40,
                child: _bubble(90, 0.08),
              ),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap == null) return base;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: base),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
