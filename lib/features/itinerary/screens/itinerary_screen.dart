import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/effects/fade_slide_in.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/inputs/add_button.dart';
import '../../../shared/widgets/layout/app_page.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../../shared/widgets/layout/stat_strip.dart';
import '../controllers/itinerary_controllers.dart';
import '../widgets/itinerary_form_sheet.dart';
import '../widgets/itinerary_row.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider);
    final days = ref.watch(itineraryDaysProvider);
    final summary = ref.watch(itinerarySummaryProvider);

    return AppPage(
      title: 'Roteiro',
      action: AddButton(label: 'Nova atividade', onPressed: () => showItineraryForm(context)),
      children: [
        if (summary.total > 0) ...[
          StatStrip(
            cells: [
              StatCell(label: 'Atividades', value: '${summary.total}', color: AppColors.turquoise),
              StatCell(
                label: 'Feitas',
                color: AppColors.success,
                value: '${summary.done}/${summary.total}',
                footnote: Fmt.percent(summary.progress),
              ),
              StatCell(label: 'Dias', value: '${summary.days}', color: AppColors.grape),
              StatCell.money(
                label: 'Contas ligadas',
                color: AppColors.sunset,
                cents: summary.linkedCents,
                footnote: '${summary.linkedCount} '
                    '${summary.linkedCount == 1 ? "atividade" : "atividades"}',
              ),
            ],
          ),
          const _SpendByCategory(),
          Gap.vXl,
        ],

        itineraryAsync.when(
          loading: () => const ShimmerList(itemCount: 3, itemHeight: 64),
          error: (e, _) => ErrorView(
            message: 'Não deu para carregar o roteiro',
            details: '$e',
            onRetry: () => ref.invalidate(itineraryProvider),
          ),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: Gap.xl),
                  child: EmptyState(
                    icon: Icons.view_agenda_outlined,
                    title: 'Roteiro vazio',
                    message: 'Adicione um passeio, restaurante ou trilha e ligue à conta dele.',
                    actionLabel: 'Nova atividade',
                    onAction: () => showItineraryForm(context),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final day in days) _DaySection(day: day),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Onde o dinheiro do roteiro está indo, por tipo de atividade.
class _SpendByCategory extends ConsumerWidget {
  const _SpendByCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byCategory = ref.watch(itinerarySpendByCategoryProvider);
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final total = byCategory.values.fold<int>(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Gasto por categoria'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, entry) in byCategory.entries.indexed) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key.label,
                            style: context.text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: AnimatedProgressBar(
                            value: total == 0 ? 0 : entry.value / total,
                          ),
                        ),
                        Gap.hLg,
                        Text(
                          Money.format(entry.value),
                          style: AppTypography.money(size: 13, color: context.colors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Um dia do roteiro: cabeçalho e as atividades em linhas de tabela.
class _DaySection extends StatelessWidget {
  const _DaySection({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(day: day),
          Gap.vSm,
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ItineraryTableHeader(),
                for (var i = 0; i < day.items.length; i++) ...[
                  if (i > 0) const Divider(),
                  FadeSlideIn(index: i, child: ItineraryRow(item: day.items[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    final count = day.items.length;

    return Row(
      children: [
        Text(
          '${Fmt.weekdayShort(day.date)} ${Fmt.dateShort(day.date)}'.toUpperCase(),
          style: AppTypography.mono(
            size: 13,
            weight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        if (day.isToday) ...[
          Gap.hSm,
          Text(
            'hoje',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        Gap.hMd,
        Expanded(
          child: Text(
            '$count ${count == 1 ? "atividade" : "atividades"}'
            '${day.doneCount > 0 ? " · ${day.doneCount} feitas" : ""}',
            style: context.text.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Adicionar neste dia',
          visualDensity: VisualDensity.compact,
          onPressed: () => showItineraryForm(context, suggestedDate: day.date),
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
