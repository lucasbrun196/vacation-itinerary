import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Aviso de erro dentro de um formulário, para o que não cabe embaixo de
/// um campo — falha de autenticação, de rede, de permissão.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: Radii.brMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          Gap.hMd,
          Expanded(
            child: Text(
              message,
              style: context.text.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.fast).shakeX(hz: 3, amount: 2);
  }
}
