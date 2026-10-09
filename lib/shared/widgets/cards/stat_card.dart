import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../feedback/animated_counter.dart';
import 'glass_card.dart';

/// Cartão de um número só: rótulo cinza em cima, valor em mono embaixo.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.footnote,
    this.onTap,
    this.isMoney = true,
    this.compact = false,
  });

  final String label;
  final num value;

  /// Mantidos por compatibilidade: o cartão não tem mais ícone nem cor.
  final IconData? icon;
  final Color? accent;

  final String? footnote;
  final VoidCallback? onTap;
  final bool isMoney;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.money(size: compact ? 18 : 22, color: context.colors.onSurface);

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? Gap.md : Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Gap.vSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: isMoney ? AnimatedMoney(value, style: style) : AnimatedCount(value.round(), style: style),
          ),
          if (footnote != null) ...[
            Gap.vXs,
            Text(
              footnote!,
              style: context.text.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
