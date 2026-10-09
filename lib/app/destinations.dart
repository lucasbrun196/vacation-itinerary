import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Destinos principais do app. Uma única fonte de verdade alimenta a
/// barra superior (desktop) e a barra inferior (celular).
///
/// O `path` não acompanhou os rótulos novos de propósito: ele está nos
/// links que a turma já trocou.
enum AppDestination {
  dashboard(label: 'Resumo', icon: Icons.space_dashboard_outlined, path: 'dashboard'),
  itinerary(label: 'Roteiro', icon: Icons.view_agenda_outlined, path: 'roteiro'),
  expenses(label: 'Contas', icon: Icons.receipt_long_outlined, path: 'gastos'),
  board(label: 'Mural', icon: Icons.photo_outlined, path: 'mural'),
  settings(label: 'Ajustes', icon: Icons.tune_outlined, path: 'config');

  const AppDestination({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;

  /// O mesmo ícone fino, ativo ou não: quem marca a aba é o peso do texto.
  IconData get activeIcon => icon;

  /// Mantido por compatibilidade: a navegação não colore mais por aba.
  Color get color => AppColors.coral;
}
