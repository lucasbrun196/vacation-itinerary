import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/cards/stat_card.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/layout/app_page.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../controllers/money_controllers.dart';
import '../widgets/bill_card.dart';
import '../widgets/bill_form_sheet.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final overview = ref.watch(moneyOverviewProvider);
    final currentMember = ref.watch(currentMemberProvider);

    return AppPage(
      title: 'Gastos',
      emoji: '💸',
      subtitle: 'As contas da viagem, divididas entre a turma',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBillForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova conta'),
      ),
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: responsiveValue(context, mobile: 2, tablet: 3, desktop: 3),
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
            mainAxisExtent: responsiveValue(context, mobile: 152.0, tablet: 148.0, desktop: 148.0),
          ),
          children: [
            StatCard(
              label: 'Total das contas',
              value: overview.totalCents.toReais,
              icon: Icons.receipt_long_rounded,
              accent: AppColors.coral,
              footnote: '${overview.billCount} ${overview.billCount == 1 ? "conta" : "contas"}',
            ),
            StatCard(
              label: 'Já quitado',
              value: overview.paidCents.toReais,
              icon: Icons.check_circle_rounded,
              accent: AppColors.success,
              footnote: Fmt.percent(overview.progress),
            ),
            StatCard(
              label: 'Falta pagar',
              value: overview.pendingCents.toReais,
              icon: Icons.pending_actions_rounded,
              accent: AppColors.sunset,
              footnote: '${overview.openBillCount} em aberto',
            ),
          ],
        ),

        if (overview.totalCents > 0) ...[
          Gap.vMd,
          _OverallProgress(overview: overview),
        ],

        if (currentMember != null) ...[
          Gap.vXl,
          const _MyMoney(),
        ],

        Gap.vXl,
        SectionHeader(
          title: 'Contas',
          icon: Icons.folder_rounded,
          trailing: billsAsync.valueOrNull == null
              ? null
              : Text('${billsAsync.value!.length}', style: context.text.labelMedium),
        ),
        billsAsync.when(
          loading: () => const ShimmerList(itemCount: 3, itemHeight: 128),
          error: (e, _) => ErrorView(message: 'Não deu para carregar as contas', details: '$e'),
          data: (bills) => bills.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: Gap.xl),
                  child: EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Nenhuma conta ainda',
                    message: 'Cadastre o aluguel, a gasolina, os rolês — '
                        'e o app divide entre a turma.',
                    accent: AppColors.sunset,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < bills.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.md),
                        child: BillCard(
                          bill: bills[i],
                          onTap: () => context.go(
                            '/viagem/${ref.read(currentTripIdProvider)}/gastos/${bills[i].id}',
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (60 * i).ms, duration: Motion.normal)
                            .slideY(begin: 0.08, curve: Motion.enter),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Progresso geral do pagamento da viagem.
class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.overview});

  final MoneyOverview overview;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Quanto já foi acertado', style: context.text.titleMedium)),
              Text(
                Fmt.percent(overview.progress),
                style: AppTypography.money(
                  size: 18,
                  color: AnimatedProgressBar.colorFor(overview.progress),
                ),
              ),
            ],
          ),
          Gap.vMd,
          AnimatedProgressBar(value: overview.progress, height: 12),
          Gap.vSm,
          Row(
            children: [
              Text(Money.format(overview.paidCents), style: context.text.bodySmall),
              const Spacer(),
              Text('de ${Money.format(overview.totalCents)}', style: context.text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// O resumo pessoal: o que você deve e o que têm a te pagar.
class _MyMoney extends ConsumerWidget {
  const _MyMoney();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider)!;
    final pending = ref.watch(myPendingSharesProvider);
    final owedToMe = ref.watch(owedToMeProvider);
    final iOwe = pending.fold<int>(0, (sum, s) => sum + s.remainingCents);
    final membersById = ref.watch(membersByIdProvider);
    final bills = {
      for (final b in ref.watch(billsProvider).valueOrNull ?? const <Bill>[]) b.id: b
    };

    if (iOwe == 0 && owedToMe == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Você, ${member.shortName}',
          icon: Icons.person_rounded,
        ),
        Row(
          children: [
            if (iOwe > 0)
              Expanded(
                child: _MyMoneyTile(
                  label: 'Você deve',
                  cents: iOwe,
                  color: AppColors.coral,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            if (iOwe > 0 && owedToMe > 0) Gap.hMd,
            if (owedToMe > 0)
              Expanded(
                child: _MyMoneyTile(
                  label: 'Devem a você',
                  cents: owedToMe,
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
          ],
        ),
        if (pending.isNotEmpty) ...[
          Gap.vMd,
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: Gap.md),
            child: Column(
              children: [
                for (final share in pending.take(3))
                  ListTile(
                    dense: true,
                    leading: MemberAvatar(
                      member: membersById[bills[share.billId]?.paidByMemberId] ?? member,
                      size: 34,
                    ),
                    title: Text(
                      bills[share.billId]?.title ?? 'Conta',
                      style: context.text.titleSmall,
                    ),
                    subtitle: Text(
                      [
                        if (share.installmentNumber != null) 'parcela ${share.installmentNumber}',
                        if (share.dueDate != null) 'vence ${Fmt.dateShort(share.dueDate!)}',
                      ].join(' · '),
                      style: context.text.bodySmall?.copyWith(
                        color: share.isOverdue ? AppColors.danger : null,
                      ),
                    ),
                    trailing: Text(
                      Money.format(share.remainingCents),
                      style: AppTypography.money(size: 15, color: context.colors.onSurface),
                    ),
                  ),
                if (pending.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.xs),
                    child: Text(
                      '+ ${pending.length - 3} pendentes',
                      style: context.text.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MyMoneyTile extends StatelessWidget {
  const _MyMoneyTile({
    required this.label,
    required this.cents,
    required this.color,
    required this.icon,
  });

  final String label;
  final int cents;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: color,
      padding: const EdgeInsets.all(Gap.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Gap.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: context.text.labelSmall),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Money.format(cents),
                    style: AppTypography.money(size: 19, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
