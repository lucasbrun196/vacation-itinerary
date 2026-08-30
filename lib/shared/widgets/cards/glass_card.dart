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
    final lift = _pressed ? 0.98 : (_hovered && interactive ? 1.012 : 1.0);

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: context.reduceMotion ? 1.0 : lift,
          duration: Motion.fast,
          curve: Motion.enter,
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.enter,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? context.colors.surface,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _hovered && interactive
                    ? (accent ?? AppColors.coral).withValues(alpha: 0.45)
                    : context.colors.outline,
                width: 1.2,
              ),
              boxShadow: !widget.showShadow
                  ? null
                  : _hovered && interactive
                      ? AppColors.glow(accent ?? AppColors.coral, opacity: 0.18, blur: 28, y: 12)
                      : AppColors.softShadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
