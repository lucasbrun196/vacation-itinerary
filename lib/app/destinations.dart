import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Destinos principais do app. Uma única fonte de verdade alimenta a
/// barra inferior (mobile), o rail (tablet) e a sidebar (desktop).
enum AppDestination {
  dashboard(
    label: 'Início',
    icon: Icons.beach_access_outlined,
    activeIcon: Icons.beach_access_rounded,
    path: 'dashboard',
    color: AppColors.coral,
  ),
  itinerary(
    label: 'Roteiro',
    icon: Icons.map_outlined,
    activeIcon: Icons.map_rounded,
    path: 'roteiro',
    color: AppColors.turquoise,
  ),
  expenses(
    label: 'Gastos',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    path: 'gastos',
    color: AppColors.sunset,
  ),
  board(
    label: 'Mural',
    icon: Icons.photo_library_outlined,
    activeIcon: Icons.photo_library_rounded,
    path: 'mural',
    color: AppColors.grape,
  ),
  settings(
    label: 'Viagem',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    path: 'config',
    color: AppColors.sky,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  final Color color;
}
