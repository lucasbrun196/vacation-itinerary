import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_tokens.dart';
import '../feedback/empty_state.dart';
import '../feedback/loading_shimmer.dart';
import 'app_shell.dart';

/// Define qual viagem está aberta para toda a árvore abaixo.
///
/// Sobrescrever [currentTripIdProvider] aqui evita passar o `tripId`
/// por parâmetro em cada tela, cada sheet e cada repositório — e garante
/// que ninguém leia dados da viagem errada.
class TripScope extends StatelessWidget {
  const TripScope({
    super.key,
    required this.tripId,
    required this.child,
  });

  final String tripId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [currentTripIdProvider.overrideWithValue(tripId)],
      child: _TripGate(child: child),
    );
  }
}

/// Confere se a viagem existe e se a pessoa participa dela antes de
/// mostrar qualquer conteúdo.
class _TripGate extends ConsumerWidget {
  const _TripGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider);
    final uid = ref.watch(currentUidProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return tripAsync.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(Gap.xl),
          child: SafeArea(child: ShimmerList(itemCount: 4, itemHeight: 96)),
        ),
      ),
      error: (e, _) => Scaffold(
        body: ErrorView(
          message: 'Não deu para abrir a viagem',
          details: '$e',
          onRetry: () => ref.invalidate(tripProvider),
        ),
      ),
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Viagem não encontrada',
              message: 'Ela pode ter sido apagada pelo administrador.',
              actionLabel: 'Ver minhas viagens',
              onAction: () => context.go(Routes.trips),
            ),
          );
        }

        if (!trip.hasMember(uid)) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Você não participa desta viagem',
              message: 'Peça para o administrador te adicionar pelo seu e-mail.',
              actionLabel: 'Ver minhas viagens',
              onAction: () => context.go(Routes.trips),
            ),
          );
        }

        // A aba ativa sai da própria URL — sem estado paralelo para
        // sincronizar, e um link colado no navegador já abre certo.
        final path = GoRouterState.of(context).uri.path;
        final index = AppDestination.values.indexWhere(
          (d) => path.startsWith('/viagem/${trip.id}/${d.path}'),
        );

        return AppShell(
          currentIndex: index < 0 ? 0 : index,
          onDestinationSelected: (i) =>
              context.go(Routes.tripSection(trip.id, AppDestination.values[i])),
          tripName: trip.name,
          onExit: () => context.go(Routes.trips),
          userInitials: user?.initials,
          onAccount: () => context.push(Routes.account),
          child: child,
        );
      },
    );
  }
}
