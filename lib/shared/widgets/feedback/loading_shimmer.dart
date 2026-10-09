import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// Esqueleto de carregamento — sempre preferível a um spinner: mostra
/// a forma do conteúdo que está por vir.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = Radii.brSm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surfaceContainerHigh,
      highlightColor: context.colors.surfaceContainerLow,
      period: const Duration(milliseconds: 1600),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
      ),
    );
  }
}

/// Lista de cards fantasma.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 4, this.itemHeight = 92});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Numa `Column` de altura rígida, quatro cards de 96px estouram a
        // viewport do Chrome de celular — e isso é a primeira tela de toda
        // viagem. Quando há altura conhecida, o esqueleto mostra só o que cabe.
        var count = itemCount;
        if (constraints.hasBoundedHeight) {
          final fits = (constraints.maxHeight / (itemHeight + Gap.md)).floor();
          count = fits.clamp(1, itemCount);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: ShimmerBox(height: itemHeight, borderRadius: Radii.brLg),
            ),
          ),
        );
      },
    );
  }
}
