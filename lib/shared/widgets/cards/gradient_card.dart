import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import 'glass_card.dart';

/// Era o cartão de gradiente do destaque. Virou um cartão branco com
/// borda, igual aos outros: o destaque agora vem do conteúdo.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.xl),
    this.borderRadius = Radii.brLg,
    this.decoration = true,
  });

  final Widget child;

  /// Ignorados — mantidos para não quebrar quem ainda os passa.
  final Gradient? gradient;
  final bool decoration;

  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) =>
      GlassCard(onTap: onTap, padding: padding, borderRadius: borderRadius, child: child);
}
