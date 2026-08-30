import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
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
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/layout/app_page.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../expenses/controllers/money_controllers.dart';
import '../widgets/trip_hero.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final overview = ref.watch(moneyOverviewProvider);
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
    final tripId = ref.watch(currentTripIdProvider);

    final trip = tripAsync.valueOrNull;

    return AppPage(
      title: user == null ? 'Olá!' : 'Olá, ${user.shortName}',
      emoji: '🌴',
      subtitle: 'Aqui está o resumo da viagem',
      children: [
        if (trip == null)
          const ShimmerBox(height: 200, borderRadius: Radii.brXl)
        else
          TripHero(trip: trip, memberCount: members.length),

        Gap.vXl,
        const SectionHeader(title: 'Dinheiro', icon: Icons.savings_rounded),

        if (bills.isEmpty)
          _StartHere(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Nenhuma conta cadastrada',
            message: 'Cadastre o aluguel, a gasolina e os rolês para o app '
                'dividir entre a turma.',
            actionLabel: 'Criar primeira conta',
            accent: AppColors.sunset,
            onAction: () => context.go(Routes.tripSection(tripId, AppDestination.expenses)),
          )
        else ...[
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveValue(context, mobile: 2, tablet: 3, desktop: 3),
              crossAxisSpacing: Gap.md,
              mainAxisSpacing: Gap.md,
              mainAxisExtent:
                  responsiveValue(context, mobile: 152.0, tablet: 148.0, desktop: 148.0),
            ),
            children: [
              StatCard(
                label: 'Total das contas',
                value: overview.totalCents.toReais,
                icon: Icons.receipt_long_rounded,
                accent: AppColors.coral,
                footnote: '${overview.billCount} '
                    '${overview.billCount == 1 ? "conta" : "contas"}',
                onTap: () =>
                    context.go(Routes.tripSection(tripId, AppDestination.expenses)),
              ),
              StatCard(
                label: 'Já quitado',
                value: overview.paidCents.toReais,
                icon: Icons.check_circle_rounded,
                accent: AppColors.success,
                footnote: Fmt.percent(overview.progress),
                onTap: () =>
                    context.go(Routes.tripSection(tripId, AppDestination.expenses)),
              ),
              StatCard(
                label: 'Falta pagar',
                value: overview.pendingCents.toReais,
                icon: Icons.pending_actions_rounded,
                accent: AppColors.sunset,
                footnote: '${overview.openBillCount} em aberto',
                onTap: () =>
                    context.go(Routes.tripSection(tripId, AppDestination.expenses)),
              ),
            ],
          ),
          Gap.vMd,
          _BudgetCard(overview: overview, budgetCents: trip?.budgetCents),
          const _MyPendingSummary(),
        ],

        Gap.vXl,
        SectionHeader(
          title: 'Roteiro',
          icon: Icons.explore_rounded,
          actionLabel: 'Abrir',
          onAction: () => context.go(Routes.tripSection(tripId, AppDestination.itinerary)),
        ),
        const _NextActivity(),

        Gap.vXl,
        SectionHeader(
          title: 'Mural',
          icon: Icons.photo_camera_rounded,
          actionLabel: 'Abrir',
          onAction: () => context.go(Routes.tripSection(tripId, AppDestination.board)),
        ),
        _StartHere(
          icon: Icons.photo_library_rounded,
          title: 'O mural chega em breve',
          message: 'Aqui vão aparecer as últimas fotos da turma.',
          accent: AppColors.grape,
        ),
      ],
    );
  }
}

/// A próxima parada do roteiro que ainda vai acontecer.
class _NextActivity extends ConsumerWidget {
  const _NextActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(currentTripIdProvider);
    final item = ref.watch(nextItineraryItemProvider);
    final total = (ref.watch(itineraryProvider).valueOrNull ?? const []).length;

    if (item == null) {
      return _StartHere(
        icon: Icons.map_rounded,
        title: total == 0 ? 'Roteiro vazio' : 'Nada mais marcado',
        message: total == 0
            ? 'Cadastre o primeiro passeio e ligue à conta dele.'
            : 'Todas as atividades já passaram ou foram concluídas.',
        accent: AppColors.turquoise,
        actionLabel: 'Abrir roteiro',
        onAction: () =>
            context.go(Routes.tripSection(tripId, AppDestination.itinerary)),
      );
    }

    final when = item.startAt ?? item.date;
    final diff = when.difference(DateTime.now());
    final countdown = diff.isNegative
        ? 'acontecendo agora'
        : diff.inHours < 1
            ? 'em ${diff.inMinutes} min'
            : diff.inHours < 24
                ? 'em ${diff.inHours}h'
                : 'em ${diff.inDays} ${diff.inDays == 1 ? "dia" : "dias"}';

    return GlassCard(
      accent: item.category.color,
      onTap: () => context.go(Routes.tripSection(tripId, AppDestination.itinerary)),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: item.category.color.withValues(alpha: 0.14),
              borderRadius: Radii.brMd,
            ),
            child: Icon(item.category.icon, color: item.category.color, size: 24),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.05, duration: 2000.ms, curve: Curves.easeInOut),
          Gap.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.category.color.withValues(alpha: 0.14),
                    borderRadius: Radii.brPill,
                  ),
                  child: Text(
                    countdown,
                    style: context.text.labelSmall?.copyWith(
                      color: item.category.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Gap.vSm,
                Text(
                  item.title,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.vXs,
                Row(
                  children: [
                    Icon(
                      item.hasTime ? Icons.schedule_rounded : Icons.event_rounded,
                      size: 13,
                      color: context.colors.onSurfaceVariant,
                    ),
                    Gap.hXs,
                    Text(
                      item.hasTime
                          ? '${Fmt.dateShort(item.date)} · ${Fmt.time(item.startAt!)}'
                          : Fmt.dateShort(item.date),
                      style: context.text.bodySmall,
                    ),
                    if (item.placeName != null) ...[
                      Gap.hSm,
                      Icon(Icons.place_outlined,
                          size: 13, color: context.colors.onSurfaceVariant),
                      Gap.hXs,
                      Expanded(
                        child: Text(
                          item.placeName!,
                          style: context.text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

/// Progresso do pagamento — e do orçamento, quando a viagem tem um.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.overview, this.budgetCents});

  final MoneyOverview overview;
  final int? budgetCents;

  @override
  Widget build(BuildContext context) {
    final budget = budgetCents ?? 0;
    final usage = budget <= 0 ? null : (overview.totalCents / budget).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (usage != null) ...[
            Row(
              children: [
                Expanded(child: Text('Orçamento da viagem', style: context.text.titleMedium)),
                Text(
                  Fmt.percent(usage),
                  style: AppTypography.money(
                    size: 18,
                    color: AnimatedProgressBar.colorFor(usage),
                  ),
                ),
              ],
            ),
            Gap.vMd,
            AnimatedProgressBar(value: usage, height: 12),
            Gap.vSm,
            Row(
              children: [
                Text('${Money.format(overview.totalCents)} em contas',
                    style: context.text.bodySmall),
                const Spacer(),
                Text('de ${Money.format(budget)}', style: context.text.bodySmall),
              ],
            ),
            Gap.vLg,
            Divider(color: context.colors.outline),
            Gap.vLg,
          ],
          Row(
            children: [
              Expanded(child: Text('Quanto já foi acertado', style: context.text.titleMedium)),
              Text(
                Fmt.percent(overview.progress),
                style: AppTypography.money(size: 18, color: AppColors.success),
              ),
            ],
          ),
          Gap.vMd,
          AnimatedProgressBar(value: overview.progress, height: 12, color: AppColors.success),
          Gap.vSm,
          Text(
            overview.pendingCents == 0
                ? 'Tudo acertado 🎉'
                : 'Faltam ${Money.format(overview.pendingCents)} para acertar tudo',
            style: context.text.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: Motion.slow).slideY(
          begin: 0.05,
          curve: Motion.enter,
        );
  }
}

/// O que você deve, resumido — só aparece quando há pendência sua.
class _MyPendingSummary extends ConsumerWidget {
  const _MyPendingSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(myPendingSharesProvider);
    final owedToMe = ref.watch(owedToMeProvider);
    final iOwe = pending.fold<int>(0, (sum, s) => sum + s.remainingCents);

    if (iOwe == 0 && owedToMe == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: Gap.md),
      child: Row(
        children: [
          if (iOwe > 0)
            Expanded(
              child: _MiniStat(
                label: 'Você deve',
                cents: iOwe,
                color: AppColors.coral,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          if (iOwe > 0 && owedToMe > 0) Gap.hMd,
          if (owedToMe > 0)
            Expanded(
              child: _MiniStat(
                label: 'Devem a você',
                cents: owedToMe,
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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

/// Convite discreto para a próxima ação, no lugar de um bloco vazio.
class _StartHere extends StatelessWidget {
  const _StartHere({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: accent,
      onTap: onAction,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: Radii.brMd,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          Gap.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.text.titleSmall),
                Gap.vXs,
                Text(message, style: context.text.bodySmall),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            Gap.hSm,
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ],
      ),
    );
  }
}
