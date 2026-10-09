
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/screens/account_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/board/screens/board_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/expenses/screens/bill_detail_screen.dart';
import '../features/expenses/screens/expenses_screen.dart';
import '../features/itinerary/screens/itinerary_screen.dart';
import '../features/trip/screens/trip_settings_screen.dart';
import '../features/trips/screens/trips_screen.dart';
import '../shared/widgets/domain/brand_mark.dart';
import '../shared/widgets/layout/trip_scope.dart';
import 'auth_action_link.dart';
import 'destinations.dart';
import 'providers.dart';

abstract final class Routes {
  static const splash = '/carregando';
  static const auth = '/entrar';
  static const trips = '/viagens';
  static const account = '/conta';
  static const resetPassword = '/redefinir-senha';

  static String trip(String tripId) => '/viagem/$tripId';
  static String tripSection(String tripId, AppDestination d) => '/viagem/$tripId/${d.path}';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// O router observa o Firebase Auth: entrar e sair já navegam sozinhos,
/// sem nenhuma tela precisar chamar `go` depois do login.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  // O link do e-mail de "esqueci minha senha" abre o app direto na tela
  // de nova senha. Ver AuthActionLink.
  final link = AuthActionLink.fromLaunch();

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: link != null && link.isPasswordReset
        ? Uri(path: Routes.resetPassword, queryParameters: {'oobCode': link.code}).toString()
        : Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Vale com ou sem sessão, e não espera o Firebase dizer se há uma:
      // passar pela splash perderia o código que veio no link.
      if (state.matchedLocation == Routes.resetPassword) return null;

      final auth = ref.read(authStateProvider);

      final atSplash = state.matchedLocation == Routes.splash;

      // O Firebase leva um instante para dizer se existe sessão salva.
      // Segurar na splash evita o pisca de mostrar o login para quem já
      // estava logado.
      if (auth.isLoading) return atSplash ? null : Routes.splash;

      final signedIn = auth.valueOrNull != null;
      final goingToAuth = state.matchedLocation == Routes.auth;

      if (!signedIn) return goingToAuth ? null : Routes.auth;
      if (goingToAuth || atSplash) return Routes.trips;
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) => Routes.trips,
      ),
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: Routes.auth,
        pageBuilder: (context, state) => const NoTransitionPage(child: AuthScreen()),
      ),
      GoRoute(
        path: Routes.trips,
        pageBuilder: (context, state) => const NoTransitionPage(child: TripsScreen()),
      ),
      GoRoute(
        path: Routes.resetPassword,
        pageBuilder: (context, state) => NoTransitionPage(
          child: ResetPasswordScreen(code: state.uri.queryParameters['oobCode'] ?? ''),
        ),
      ),
      // Fora do ShellRoute: a conta não pertence a viagem nenhuma.
      GoRoute(
        path: Routes.account,
        pageBuilder: (context, state) => const NoTransitionPage(child: AccountScreen()),
      ),
      // ShellRoute, e não StatefulShellRoute: o go_router não aceita
      // parâmetro de rota na raiz de um branch, e aqui o `tripId` é
      // necessariamente dinâmico. Cada aba relê de streams já em cache
      // no Riverpod, então a troca continua instantânea.
      ShellRoute(
        builder: (context, state, child) => TripScope(
          tripId: state.pathParameters['tripId'] ?? '',
          child: child,
        ),
        routes: [
          for (final destination in AppDestination.values)
            GoRoute(
              path: '/viagem/:tripId/${destination.path}',
              pageBuilder: (context, state) => NoTransitionPage(
                key: ValueKey('${state.pathParameters['tripId']}/${destination.path}'),
                child: _screenFor(destination),
              ),
              routes: [
                if (destination == AppDestination.expenses)
                  GoRoute(
                    path: ':billId',
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      transitionDuration: const Duration(milliseconds: 200),
                      reverseTransitionDuration: const Duration(milliseconds: 160),
                      child: BillDetailScreen(billId: state.pathParameters['billId']!),
                      transitionsBuilder: (context, animation, _, child) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(),
            const SizedBox(height: 16),
            Text('Essa página não existe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.trips),
              child: const Text('Ver minhas viagens'),
            ),
          ],
        ),
      ),
    ),
  );
});

Widget _screenFor(AppDestination destination) => switch (destination) {
      AppDestination.dashboard => const DashboardScreen(),
      AppDestination.itinerary => const ItineraryScreen(),
      AppDestination.expenses => const ExpensesScreen(),
      AppDestination.board => const BoardScreen(),
      AppDestination.settings => const TripSettingsScreen(),
    };

/// Ponte entre o stream de autenticação e o `refreshListenable` do
/// go_router, que só entende `Listenable`.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen(
      authStateProvider,
      (_, _) => notifyListeners(),
      fireImmediately: true,
    );
  }

  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
