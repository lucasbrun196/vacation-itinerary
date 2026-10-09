import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/trip.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../../../shared/widgets/effects/theme_toggle.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/inputs/add_button.dart';
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentContainer(
                maxWidth: 880,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: context.isMobile ? Gap.xl : Gap.xxl,
                    bottom: Gap.xl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user == null ? 'Suas viagens' : 'Olá, ${user.shortName}',
                              style: context.isMobile
                                  ? context.text.headlineMedium
                                  : context.text.displaySmall,
                            ),
                            Gap.vXs,
                            Text('Escolha uma viagem ou crie uma nova.',
                                style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      const ThemeToggle(),
                      Gap.hSm,
                      AddButton(label: 'Nova viagem', onPressed: () => _createTrip(context, ref)),
                      Gap.hMd,
                      const _AccountButton(),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentContainer(
                maxWidth: 880,
                child: tripsAsync.when(
                  loading: () => const ShimmerList(itemCount: 3, itemHeight: 64),
                  error: (e, _) => ErrorView(
                    message: 'Não deu para carregar suas viagens',
                    details: '$e',
                    onRetry: () => ref.invalidate(myTripsProvider),
                  ),
                  data: (trips) => trips.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: Gap.xxl),
                          child: EmptyState(
                            icon: Icons.luggage_outlined,
                            title: 'Nenhuma viagem ainda',
                            message: 'Crie a primeira e adicione as pessoas pelo e-mail.',
                            actionLabel: 'Criar viagem',
                            onAction: () => _createTrip(context, ref),
                          ),
                        )
                      : GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, trip) in trips.indexed) ...[
                                if (i > 0) const Divider(),
                                _TripRow(trip: trip),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
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

class _TripRow extends ConsumerWidget {
  const _TripRow({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = trip.isAdmin(ref.watch(currentUidProvider));
    final muted = context.colors.onSurfaceVariant;

    final status = switch (trip) {
      _ when !trip.hasDates => 'sem datas',
      _ when trip.isUpcoming => 'T–${trip.daysUntilStart} ${trip.daysUntilStart == 1 ? "dia" : "dias"}',
      _ when trip.isOngoing => 'Dia ${trip.currentDay}/${trip.totalDays}',
      _ => 'concluída',
    };

    final details = [
      if (trip.destination.isNotEmpty) trip.destination,
      '${trip.memberIds.length} ${trip.memberIds.length == 1 ? "participante" : "participantes"}',
      if (isAdmin) 'admin',
    ].join(' · ');

    return InkWell(
      onTap: () => context.go('/viagem/${trip.id}/dashboard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    details,
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.hMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(status, style: AppTypography.mono(size: 12, color: context.colors.onSurface)),
                if (trip.hasDates && !context.isNarrow)
                  Text(
                    '${Fmt.dateShort(trip.startDate!)} – ${Fmt.dateShort(trip.endDate!)}',
                    style: AppTypography.mono(size: 11, color: muted),
                  ),
              ],
            ),
            Gap.hSm,
            Icon(Icons.chevron_right, size: 18, color: muted),
          ],
        ),
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
      offset: const Offset(0, 44),
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
              Icon(Icons.logout, size: 18),
              SizedBox(width: Gap.md),
              Text('Sair'),
            ],
          ),
        ),
      ],
      // O `PopupMenuButton` embrulha o filho em um `InkWell`, que sem isto
      // desenha um quadrado atrás do avatar redondo.
      borderRadius: Radii.brPill,
      child: InitialsAvatar(initials: user?.initials ?? '?', size: 32),
    );
  }
}
