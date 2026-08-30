import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/trip.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../widgets/trip_form_sheet.dart';

/// Lista das viagens em que a pessoa participa — a casa do app depois
/// do login.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTrip(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova viagem'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentContainer(
                child: Padding(
                  padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user == null ? 'Suas viagens' : 'Olá, ${user.shortName} 👋',
                              style: context.isMobile
                                  ? context.text.headlineMedium
                                  : context.text.displaySmall,
                            ),
                            Gap.vXs,
                            Text(
                              'Escolha uma viagem ou crie uma nova',
                              style: context.text.bodyMedium
                                  ?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const _AccountButton(),
                    ],
                  ),
                ).animate().fadeIn(duration: Motion.normal).slideY(begin: -0.12),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentContainer(
                child: tripsAsync.when(
                  loading: () => const ShimmerList(itemCount: 3, itemHeight: 132),
                  error: (e, _) => ErrorView(
                    message: 'Não deu para carregar suas viagens',
                    details: '$e',
                    onRetry: () => ref.invalidate(myTripsProvider),
                  ),
                  data: (trips) => trips.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: Gap.xxl),
                          child: EmptyState(
                            icon: Icons.luggage_rounded,
                            title: 'Nenhuma viagem ainda',
                            message: 'Crie a primeira e convide a turma pelo e-mail.',
                            actionLabel: 'Criar viagem',
                            onAction: () => _createTrip(context, ref),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < trips.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: Gap.md),
                                child: _TripCard(trip: trips[i])
                                    .animate()
                                    .fadeIn(delay: (70 * i).ms, duration: Motion.normal)
                                    .slideY(begin: 0.1, curve: Motion.enter),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Future<void> _createTrip(BuildContext context, WidgetRef ref) async {
    final id = await showTripForm(context);
    if (id != null && context.mounted) context.go('/viagem/$id/dashboard');
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = trip.isAdmin(ref.watch(currentUidProvider));

    final (String label, Color color) = switch (trip) {
      _ when !trip.hasDates => ('sem datas', AppColors.inkFaint),
      _ when trip.isUpcoming => ('faltam ${trip.daysUntilStart} dias', AppColors.sunset),
      _ when trip.isOngoing => ('dia ${trip.currentDay} de ${trip.totalDays}', AppColors.success),
      _ => ('concluída', AppColors.inkFaint),
    };

    return GlassCard(
      accent: AppColors.coral,
      onTap: () => context.go('/viagem/${trip.id}/dashboard'),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.sunsetGradient,
              borderRadius: Radii.brMd,
            ),
            child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 26),
          ),
          Gap.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        trip.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      Gap.hSm,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.16),
                          borderRadius: Radii.brPill,
                        ),
                        child: Text(
                          'admin',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Gap.vXs,
                if (trip.destination.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 13, color: context.colors.onSurfaceVariant),
                      Gap.hXs,
                      Flexible(
                        child: Text(
                          trip.destination,
                          style: context.text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                Gap.vXs,
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: Radii.brPill,
                      ),
                      child: Text(
                        label,
                        style: context.text.labelSmall
                            ?.copyWith(color: color, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (trip.hasDates)
                      Text(
                        '${Fmt.dateShort(trip.startDate!)} — ${Fmt.dateShort(trip.endDate!)}',
                        style: context.text.labelSmall,
                      ),
                    Text(
                      '${trip.memberIds.length} '
                      '${trip.memberIds.length == 1 ? "participante" : "participantes"}',
                      style: context.text.labelSmall,
                    ),
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

/// Avatar com menu de conta e sair.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return PopupMenuButton<String>(
      tooltip: 'Sua conta',
      offset: const Offset(0, 48),
      shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
      onSelected: (value) async {
        if (value == 'conta') {
          context.push(Routes.account);
        } else if (value == 'sair') {
          await ref.read(authServiceProvider).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user?.displayName ?? '', style: context.text.titleSmall),
              Text(user?.email ?? '', style: context.text.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'conta',
          child: Row(
            children: [
              Icon(Icons.manage_accounts_outlined, size: 18),
              SizedBox(width: Gap.md),
              Text('Minha conta'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: Gap.md),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.turquoise.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(user?.emoji ?? '🙂', style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
