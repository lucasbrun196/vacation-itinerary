import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';

/// A marca do app: "WeGoTravel" em Geist, num degradê de coral para
/// pêssego. Fica na splash, no login e na página de erro.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.color});

  final double size;

  /// Cor chapada no lugar do degradê, para fundos coloridos.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'WeGoTravel',
      style: context.text.displaySmall?.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03 * size,
        color: color ?? Colors.white,
      ),
    );
    if (color != null) return text;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.sunsetGradient.createShader(bounds),
      child: text,
    );
  }
}
