import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../feedback/animated_counter.dart';
import 'glass_card.dart';

/// Card de número em destaque (total gasto, pago, pendente...).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.footnote,
    this.onTap,
    this.isMoney = true,
    this.compact = false,
  });

  final String label;
  final num value;
  final IconData icon;
  final Color accent;
  final String? footnote;
  final VoidCallback? onTap;
  final bool isMoney;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      accent: accent,
      padding: EdgeInsets.all(compact ? Gap.md : Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Gap.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: Radii.brSm,
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              Gap.hSm,
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap.vMd,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: isMoney
                ? AnimatedMoney(
                    value,
                    style: AppTypography.money(
                      size: compact ? 20 : 26,
                      color: context.colors.onSurface,
                    ),
                  )
                : AnimatedCount(
                    value.round(),
                    style: AppTypography.money(
                      size: compact ? 20 : 26,
                      color: context.colors.onSurface,
                    ),
                  ),
          ),
          if (footnote != null) ...[
            Gap.vXs,
            Text(
              footnote!,
              style: context.text.labelSmall?.copyWith(color: AppColors.inkFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
