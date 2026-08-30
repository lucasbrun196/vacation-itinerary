import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Card base do app: cantos generosos, borda sutil, sombra suave e
/// reação ao toque/hover quando é interativo.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.color,
    this.borderRadius = Radii.brLg,
    this.accent,
    this.showShadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;

  /// Quando informado, tinge a sombra e a borda — usado para dar
  /// identidade de categoria aos cards.
  final Color? accent;
  final bool showShadow;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final accent = widget.accent;
    final highlighted = _hovered && interactive;
    final lift = _pressed ? 0.98 : (highlighted ? 1.012 : 1.0);

    Widget content = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.enter,
      decoration: BoxDecoration(
        color: widget.color ?? context.colors.surface,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: highlighted
              ? (accent ?? AppColors.coral).withValues(alpha: 0.45)
              : context.colors.outline,
          width: 1.2,
        ),
        boxShadow: !widget.showShadow
            ? null
            : highlighted
                ? AppColors.glow(accent ?? AppColors.coral, opacity: 0.18, blur: 28, y: 12)
                : AppColors.softShadow,
      ),
      // O respingo do toque é pintado pelo `Material`, que é filho do
      // container: assim ele aparece **por cima** do fundo do card. Com o
      // padding no container, o respingo parava na borda do conteúdo.
      child: interactive
          ? Material(
              type: MaterialType.transparency,
              borderRadius: widget.borderRadius,
              child: InkWell(
                borderRadius: widget.borderRadius,
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            )
          : Padding(padding: widget.padding, child: widget.child),
    );

    content = AnimatedScale(
      scale: context.reduceMotion ? 1.0 : lift,
      duration: Motion.fast,
      curve: Motion.enter,
      child: content,
    );

    if (!interactive) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      // Só mouse de verdade. O Chrome de celular emite eventos de mouse
      // sintéticos ao tocar: o `onEnter` disparava, o `onExit` nunca vinha,
      // e o card ficava destacado para sempre.
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.mouse) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: content,
    );
  }
}
