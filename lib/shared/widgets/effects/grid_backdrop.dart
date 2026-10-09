import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Painel de destaque: degradê suave de coral para pêssego, três bolhas de
/// cor que flutuam devagar ao fundo e uma grade fina por cima, que desbota
/// para a direita. Fica no topo do Resumo e no "Você deve" das Contas.
///
/// As bolhas fazem uma volta completa a cada 14 segundos — lento o
/// bastante para ser ambiente, não distração. Com "reduzir movimento"
/// ligado, elas ficam paradas.
class GridBackdrop extends StatefulWidget {
  const GridBackdrop({super.key, required this.child, this.padding = const EdgeInsets.all(Gap.xl)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<GridBackdrop> createState() => _GridBackdropState();
}

class _GridBackdropState extends State<GridBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final colors = context.colors;

    final start = dark ? const Color(0xFF3A2220) : const Color(0xFFFFE4E0);
    final end = dark ? const Color(0xFF2E2219) : const Color(0xFFFFF1E4);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: Radii.brXl,
        border: Border.all(color: dark ? colors.outline : AppColors.coralBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        boxShadow: dark ? null : AppColors.glow(AppColors.coral, opacity: 0.10, blur: 30, y: 12),
      ),
      child: CustomPaint(
        painter: _BlobPainter(
          animation: _controller,
          blobs: [
            (AppColors.coral, dark ? 0.22 : 0.20),
            (AppColors.sunset, dark ? 0.18 : 0.22),
            (AppColors.grape, dark ? 0.14 : 0.12),
          ],
        ),
        child: CustomPaint(
          painter: _GridPainter(
            line: colors.primary.withValues(alpha: dark ? 0.10 : 0.08),
          ),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

/// As bolhas: círculos com borda difusa, cada um numa órbita própria.
class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.animation, required this.blobs}) : super(repaint: animation);

  final Animation<double> animation;
  final List<(Color, double)> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    final base = size.shortestSide;

    // Posição de repouso (fração da largura/altura), raio e fase de cada
    // bolha. Fases diferentes impedem que se movam em bloco.
    const layout = [
      (0.85, 0.15, 0.75, 0.0),
      (0.65, 1.00, 0.65, 2.1),
      (0.10, 0.90, 0.45, 4.2),
    ];

    for (var i = 0; i < blobs.length && i < layout.length; i++) {
      final (fx, fy, r, phase) = layout[i];
      final (color, alpha) = blobs[i];
      final center = Offset(
        size.width * fx + math.cos(t + phase) * base * 0.08,
        size.height * fy + math.sin(t + phase) * base * 0.10,
      );
      final radius = base * r;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.blobs != blobs;
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.line});

  final Color line;
  static const _cell = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    // A grade desbota da esquerda para a direita, para não brigar com o
    // texto que costuma ficar à esquerda e as ações à direita.
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [line, line.withValues(alpha: 0)],
        stops: const [0.15, 0.9],
      ).createShader(Offset.zero & size);

    for (var x = _cell; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = _cell; y < size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.line != line;
}
