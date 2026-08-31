import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../../shared/widgets/cards/stat_card.dart';
import '../../../shared/widgets/feedback/animated_progress_bar.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/layout/app_page.dart';
import '../../../shared/widgets/layout/stat_grid.dart';
import '../controllers/itinerary_controllers.dart';
import '../widgets/itinerary_card.dart';
import '../widgets/itinerary_form_sheet.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider);
    final days = ref.watch(itineraryDaysProvider);
    final summary = ref.watch(itinerarySummaryProvider);

    return AppPage(
      title: 'Roteiro',
      emoji: '🗺️',
      subtitle: 'O que a turma vai fazer, dia a dia',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showItineraryForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova atividade'),
      ),
      children: [
        if (summary.total > 0) ...[
          StatGrid(
            children: [
              StatCard(
                label: 'Atividades',
                value: summary.total,
                icon: Icons.flag_rounded,
                accent: AppColors.turquoise,
                isMoney: false,
                footnote: '${summary.done} já feitas',
              ),
              StatCard(
                label: 'Dias com programa',
                value: summary.days,
                icon: Icons.event_available_rounded,
                accent: AppColors.grape,
                isMoney: false,
                footnote: summary.days == 1 ? 'um dia' : 'dias planejados',
              ),
              StatCard(
                label: 'Contas ligadas',
                value: summary.linkedCents.toReais,
                icon: Icons.receipt_long_rounded,
                accent: AppColors.sunset,
                footnote: '${summary.linkedCount} '
                    '${summary.linkedCount == 1 ? "atividade" : "atividades"}',
              ),
            ],
          ),
          Gap.vMd,
          _Progress(summary: summary),
          const _SpendByCategory(),
          Gap.vXl,
        ],

        itineraryAsync.when(
          loading: () => const ShimmerList(itemCount: 3, itemHeight: 96),
          error: (e, _) => ErrorView(
            message: 'Não deu para carregar o roteiro',
            details: '$e',
            onRetry: () => ref.invalidate(itineraryProvider),
          ),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: Gap.xl),
                  child: EmptyState(
                    icon: Icons.map_rounded,
                    title: 'Roteiro vazio',
                    message: 'Adicione o primeiro passeio, restaurante ou trilha — '
                        'e ligue à conta dele para saber quanto custou.',
                    actionLabel: 'Nova atividade',
                    accent: AppColors.turquoise,
                    onAction: () => showItineraryForm(context),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var d = 0; d < days.length; d++)
                      _DaySection(day: days[d], index: d),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.summary});

  final ItinerarySummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Quanto já rolou', style: context.text.titleMedium)),
              Text(
                Fmt.percent(summary.progress),
                style: AppTypography.money(
                  size: 18,
                  color: AnimatedProgressBar.colorFor(summary.progress),
                ),
              ),
            ],
          ),
          Gap.vMd,
          AnimatedProgressBar(value: summary.progress, height: 12),
          Gap.vSm,
          Text(
            summary.done == summary.total
                ? 'Roteiro completo 🎉'
                : '${summary.done} de ${summary.total} atividades marcadas como feitas',
            style: context.text.bodySmall,
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(top: Gap.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Gasto por tipo de atividade', style: context.text.titleMedium),
            Gap.vMd,
            for (final entry in byCategory.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(entry.key.icon, size: 15, color: entry.key.color),
                        Gap.hSm,
                        Expanded(
                          child: Text(entry.key.label, style: context.text.bodyMedium),
                        ),
                        Text(
                          Money.format(entry.value),
                          style: AppTypography.money(
                            size: 15,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Gap.vXs,
                    AnimatedProgressBar(
                      value: total == 0 ? 0 : entry.value / total,
                      height: 6,
                      color: entry.key.color,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Um dia do roteiro, com cabeçalho e a linha do tempo das atividades.
class _DaySection extends ConsumerWidget {
  const _DaySection({required this.day, required this.index});

  final ItineraryDay day;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(day: day),
          Gap.vMd,
          for (var i = 0; i < day.items.length; i++)
            ItineraryCard(
              item: day.items[i],
              isLast: i == day.items.length - 1,
            ),
        ],
      ),
    ).animate().fadeIn(delay: (60 * index).ms, duration: Motion.normal).slideY(
          begin: 0.06,
          curve: Motion.enter,
        );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: Gap.sm),
          decoration: BoxDecoration(
            color: day.isToday
                ? AppColors.coral.withValues(alpha: 0.14)
                : context.colors.surfaceContainerHigh,
            borderRadius: Radii.brMd,
          ),
          child: Column(
            children: [
              Text(
                Fmt.weekdayShort(day.date).toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  color: day.isToday ? AppColors.coral : context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${day.date.day}'.padLeft(2, '0'),
                style: AppTypography.money(
                  size: 20,
                  color: day.isToday ? AppColors.coral : context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        Gap.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      Fmt.dateFull(day.date),
                      style: context.text.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (day.isToday) ...[
                    Gap.hSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: Radii.brPill,
                      ),
                      child: Text(
                        'hoje',
                        style: context.text.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${day.items.length} '
                '${day.items.length == 1 ? "atividade" : "atividades"}'
                '${day.doneCount > 0 ? " · ${day.doneCount} feitas" : ""}',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Adicionar neste dia',
          onPressed: () => showItineraryForm(context, suggestedDate: day.date),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        ),
      ],
    );
  }
}
