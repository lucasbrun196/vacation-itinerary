import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../controllers/money_controllers.dart';

class BillCard extends ConsumerWidget {
  const BillCard({super.key, required this.bill, this.onTap});

  final Bill bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(billSummaryProvider(bill));
    final owner = bill.paidByMemberId == null
        ? null
        : ref.watch(membersByIdProvider)[bill.paidByMemberId];
    final accent = bill.category.color;

    return GlassCard(
      onTap: onTap,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: Radii.brMd,
                ),
                child: Icon(bill.category.icon, color: accent, size: 22),
              ),
              Gap.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: context.text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.vXs,
                    Wrap(
                      spacing: Gap.xs,
                      runSpacing: Gap.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Tag(label: bill.category.label, color: accent),
                        if (bill.isAccumulating)
                          _Tag(
                            label: bill.status == BillStatus.settled
                                ? 'fechada'
                                : '${bill.entriesCount} ${bill.entriesCount == 1 ? "lançamento" : "lançamentos"}',
                            color: AppColors.sky,
                            icon: Icons.add_chart_rounded,
                          )
                        else if (bill.isInstallment)
                          _Tag(
                            label: '${bill.installmentCount}x de ${Money.format(bill.perPersonPerInstallmentCents)}',
                            color: AppColors.grape,
                            icon: Icons.calendar_month_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap.hSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(summary.totalCents),
                    style: AppTypography.money(size: 18, color: context.colors.onSurface),
                  ),
                  if (owner != null) ...[
                    Gap.vXs,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MemberAvatar(member: owner, size: 20, showBorder: false),
                        Gap.hXs,
                        Text('bancou', style: context.text.labelSmall),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (summary.shareCount > 0) ...[
            Gap.vLg,
            AnimatedProgressBar(value: summary.progress, height: 8),
            Gap.vSm,
            Row(
              children: [
                Icon(
                  summary.isSettled ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 13,
                  color: summary.isSettled ? AppColors.success : context.colors.onSurfaceVariant,
                ),
                Gap.hXs,
                Text(
                  summary.isSettled
                      ? 'Tudo quitado'
                      : 'Falta ${Money.format(summary.pendingCents)}',
                  style: context.text.bodySmall?.copyWith(
                    color: summary.isSettled ? AppColors.success : null,
                    fontWeight: summary.isSettled ? FontWeight.w600 : null,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.paidCount}/${summary.shareCount} cotas',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ] else if (bill.isAccumulating) ...[
            Gap.vMd,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
              decoration: BoxDecoration(
                color: AppColors.sky.withValues(alpha: 0.10),
                borderRadius: Radii.brSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 15, color: AppColors.sky),
                  Gap.hSm,
                  Expanded(
                    child: Text(
                      'Ainda somando — divide no fechamento',
                      style: context.text.labelSmall?.copyWith(color: AppColors.sky),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), Gap.hXs],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
