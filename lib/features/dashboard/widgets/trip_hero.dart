import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/trip.dart';
import '../../../shared/widgets/cards/gradient_card.dart';

/// Herói do painel: dá o clima da viagem em um relance.
/// Antes da viagem mostra contagem regressiva; durante, o dia atual.
class TripHero extends StatelessWidget {
  const TripHero({super.key, required this.trip, this.memberCount = 0});

  final Trip trip;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final (String badge, String headline) = switch (trip) {
      _ when !trip.hasDates => ('Sem datas ainda', 'Defina as datas em Viagem'),
      _ when trip.daysUntilStart > 1 =>
        ('Faltam ${trip.daysUntilStart} dias', 'A contagem já começou'),
      _ when trip.daysUntilStart == 1 => ('É amanhã!', 'Prepare a mala'),
      _ when trip.isOngoing && trip.currentDay == 1 => ('Começa hoje', 'Boa viagem!'),
      _ when trip.isOngoing =>
        ('Dia ${trip.currentDay} de ${trip.totalDays}', 'Aproveite cada momento'),
      _ => ('Viagem concluída', 'Que memórias, hein?'),
    };

    return GradientCard(
      gradient: AppColors.sunsetGradient,
      padding: EdgeInsets.all(context.isMobile ? Gap.xl : Gap.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: Radii.brPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny_rounded, size: 15, color: Colors.white),
                Gap.hSm,
                Text(
                  badge,
                  style: context.text.labelMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2400.ms, color: Colors.white.withValues(alpha: 0.35)),
          Gap.vLg,
          Text(
            trip.name,
            style: (context.isMobile ? context.text.displaySmall : context.text.displayMedium)
                ?.copyWith(color: Colors.white),
          ),
          if (trip.destination.isNotEmpty) ...[
            Gap.vXs,
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 17, color: Colors.white70),
                Gap.hXs,
                Flexible(
                  child: Text(
                    trip.destination,
                    style: context.text.titleMedium?.copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          Gap.vLg,
          Wrap(
            spacing: Gap.lg,
            runSpacing: Gap.sm,
            children: [
              if (trip.hasDates)
                _Fact(
                  icon: Icons.calendar_today_rounded,
                  label: '${Fmt.dateShort(trip.startDate!)} — '
                      '${Fmt.dateWithYear(trip.endDate!)}',
                ),
              if (memberCount > 0)
                _Fact(
                  icon: Icons.group_rounded,
                  label: '$memberCount ${memberCount == 1 ? "participante" : "participantes"}',
                ),
            ],
          ),
          Gap.vSm,
          Text(headline, style: context.text.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.06, curve: Motion.enter);
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        Gap.hSm,
        Text(label, style: context.text.bodyMedium?.copyWith(color: Colors.white)),
      ],
    );
  }
}
