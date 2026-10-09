import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/models/member.dart';
import '../../../data/models/trip.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../../../shared/widgets/effects/grid_backdrop.dart';
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/layout/app_page.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../../shared/widgets/layout/stat_strip.dart';
import '../../expenses/controllers/money_controllers.dart';
import '../../expenses/widgets/bill_form_sheet.dart';
import '../../itinerary/widgets/itinerary_form_sheet.dart';
import '../../itinerary/widgets/itinerary_row.dart';

/// A partir desta largura o roteiro e o acerto ficam lado a lado.
const _twoColumns = 880.0;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? const <Member>[];

    return AppPage(
      title: trip?.name ?? '',
      header: trip == null ? null : _Hero(trip: trip, facts: _facts(trip, members.length)),
      children: [
        const _MoneyStrip(),
        Gap.vXl,
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _twoColumns) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_ItineraryTable(), Gap.vXl, _SettlementPanel()],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _ItineraryTable()),
                Gap.hXl,
                Expanded(flex: 2, child: _SettlementPanel()),
              ],
            );
          },
        ),
      ],
    );
  }

  /// "Florianópolis, SC · 27/12/2026 – 03/01/2027 · 4 participantes"
  static String _facts(Trip trip, int memberCount) => [
        if (trip.destination.isNotEmpty) trip.destination,
        if (trip.hasDates)
          '${Fmt.dateShortWithYear(trip.startDate!)} – ${Fmt.dateShortWithYear(trip.endDate!)}',
        if (memberCount > 0) '$memberCount ${memberCount == 1 ? "participante" : "participantes"}',
      ].join(' · ');
}

/// O topo do Resumo: a contagem, o nome da viagem e a linha de fatos sobre
/// o painel de grade.
class _Hero extends StatelessWidget {
  const _Hero({required this.trip, required this.facts});

  final Trip trip;
  final String facts;

  @override
  Widget build(BuildContext context) {
    return GridBackdrop(
      padding: EdgeInsets.all(context.isMobile ? Gap.xl : Gap.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountdownTag(trip: trip),
          Gap.vLg,
          Text(
            trip.name,
            style: context.isMobile ? context.text.headlineLarge : context.text.displayMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (facts.isNotEmpty) ...[
            Gap.vSm,
            Text(facts, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// A contagem da viagem numa etiqueta mono: "T–79 dias", "Dia 3/8".
class _CountdownTag extends StatelessWidget {
  const _CountdownTag({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final label = switch (trip) {
      _ when !trip.hasDates => null,
      _ when trip.daysUntilStart > 1 => 'T–${trip.daysUntilStart} dias',
      _ when trip.daysUntilStart == 1 => 'T–1 dia',
      _ when trip.isOngoing => 'Dia ${trip.currentDay}/${trip.totalDays}',
      _ => 'Concluída',
    };
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brSm,
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!trip.isFinished) ...[const _PulseDot(), Gap.hSm],
          Text(label, style: AppTypography.mono(size: 12, color: context.colors.onSurface)),
        ],
      ),
    );
  }
}

/// O ponto verde de "em andamento": pulsa devagar enquanto a viagem não
/// acabou. Parado quando o sistema pede menos movimento.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35 * t), blurRadius: 0, spreadRadius: 3 * t),
            ],
          ),
        );
      },
    );
  }
}

/// Total, Pago, Falta e Você deve, numa faixa só.
class _MoneyStrip extends ConsumerWidget {
  const _MoneyStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(moneyOverviewProvider);
    final pending = ref.watch(myPendingSharesProvider);
    final iOwe = pending.fold<int>(0, (sum, s) => sum + s.remainingCents);
    final next = pending.isEmpty ? null : pending.first;

    return StatStrip(
      cells: [
        StatCell.money(
          label: 'Total',
          color: AppColors.sky,
          cents: overview.totalCents,
          footnote: '${overview.billCount} ${overview.billCount == 1 ? "conta" : "contas"}',
        ),
        StatCell.money(
          label: 'Pago',
          color: AppColors.success,
          cents: overview.paidCents,
          footnote: Fmt.percent(overview.progress),
        ),
        StatCell.money(
          label: 'Falta',
          color: AppColors.sunset,
          cents: overview.pendingCents,
          footnote: '${overview.openBillCount} em aberto',
        ),
        StatCell.money(
          label: 'Você deve',
          color: AppColors.coral,
          cents: iOwe,
          highlight: true,
          footnote: next == null
              ? 'nada pendente'
              : [
                  'próx. ${Money.format(next.remainingCents)}',
                  if (next.dueDate != null) 'vence ${Fmt.dateShort(next.dueDate!)}',
                ].join(' · '),
        ),
      ],
    );
  }
}

/// As próximas atividades, em tabela, agrupadas por dia.
class _ItineraryTable extends ConsumerWidget {
  const _ItineraryTable();

  /// Bastante para dar a cara dos próximos dias sem virar o roteiro inteiro.
  static const _maxRows = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = ref.watch(currentTripIdProvider);
    final allDays = ref.watch(itineraryDaysProvider);
    final today = DateTime.now().dateOnly;

    // Do dia de hoje em diante; com a viagem já encerrada, o roteiro todo.
    final upcoming = allDays.where((d) => !d.date.dateOnly.isBefore(today)).toList();
    final source = upcoming.isEmpty ? allDays : upcoming;

    final shown = <ItineraryDay>[];
    var rows = 0;
    for (final day in source) {
      if (rows >= _maxRows) break;
      shown.add(day);
      rows += day.items.length;
    }
    final total = allDays.fold<int>(0, (sum, d) => sum + d.items.length);
    void open() => context.go(Routes.tripSection(tripId, AppDestination.itinerary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Roteiro',
          actionLabel: total == 0 ? null : 'Ver tudo',
          onAction: total == 0 ? null : open,
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: total == 0
              ? _EmptyRow(
                  message: 'Nenhuma atividade no roteiro.',
                  actionLabel: 'Nova atividade',
                  onAction: () => showItineraryForm(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ItineraryTableHeader(detailed: false),
                    for (final (d, day) in shown.indexed) ...[
                      if (d > 0) const Divider(),
                      _DayLabel(day: day),
                      for (final item in day.items) ItineraryRow(item: item, detailed: false),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 6),
      child: Text(
        [
          '${Fmt.weekdayShort(day.date)} ${Fmt.dateShort(day.date)}'.toUpperCase(),
          if (day.isToday) 'hoje',
        ].join(' · '),
        style: AppTypography.mono(
          size: 11,
          weight: FontWeight.w600,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Quanto já foi pago e o saldo de cada um.
class _SettlementPanel extends ConsumerWidget {
  const _SettlementPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(moneyOverviewProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const <Member>[];
    final balances = ref.watch(memberBalancesProvider);
    final uid = ref.watch(currentUidProvider);
    final budget = ref.watch(tripProvider).valueOrNull?.budgetCents ?? 0;
    final muted = context.colors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Acerto'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: overview.billCount == 0
              ? _EmptyRow(
                  message: 'Nenhuma conta cadastrada.',
                  actionLabel: 'Nova conta',
                  onAction: () => showBillForm(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Gap.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProgressLine(
                            label: 'Pago',
                            value: overview.progress,
                            detail: '${Money.format(overview.paidCents)} de '
                                '${Money.format(overview.totalCents)}',
                          ),
                          if (budget > 0) ...[
                            Gap.vLg,
                            _ProgressLine(
                              label: 'Orçamento',
                              value: overview.totalCents / budget,
                              detail: '${Money.format(overview.totalCents)} de '
                                  '${Money.format(budget)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(),
                    for (final (i, member) in members.indexed) ...[
                      if (i > 0) const Divider(),
                      _BalanceRow(
                        member: member,
                        cents: balances[member.id] ?? 0,
                        isMe: member.id == uid,
                      ),
                    ],
                    if (members.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
                        child: Text('+ a receber   − a pagar',
                            style: context.text.labelSmall?.copyWith(color: muted)),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.label, required this.value, required this.detail});

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.titleSmall)),
            Text(
              Fmt.percent(value),
              style: AppTypography.mono(size: 13, color: context.colors.onSurface),
            ),
          ],
        ),
        Gap.vSm,
        AnimatedProgressBar(value: value, height: 8),
        Gap.vSm,
        Text(detail, style: AppTypography.mono(size: 12, color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.member, required this.cents, required this.isMe});

  final Member member;
  final int cents;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = switch (cents) {
      > 0 => ('+${Money.format(cents)}', context.success),
      < 0 => ('−${Money.format(-cents)}', context.colors.onSurface),
      _ => (Money.format(0), context.colors.onSurfaceVariant),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 10),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 24),
          Gap.hMd,
          Expanded(
            child: Text(
              isMe ? '${member.shortName} (você)' : member.shortName,
              style: context.text.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(text, style: AppTypography.money(size: 13, color: color)),
        ],
      ),
    );
  }
}

/// O vazio de um painel: uma linha de texto e o botão para resolver.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.message, required this.actionLabel, required this.onAction});

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
      child: Row(
        children: [
          Expanded(child: Text(message, style: context.text.bodySmall)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
