import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/destinations.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Casca de navegação adaptativa.
///
/// Mesmo conteúdo em todas as larguras, apenas a navegação muda de forma:
/// barra inferior no celular, rail no tablet, sidebar completa no desktop.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.tripName,
    this.onExit,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? tripName;

  /// Voltar para a lista de viagens.
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: _BottomBar(
          currentIndex: currentIndex,
          onSelected: onDestinationSelected,
        ),
      );
    }

    final extended = context.breakpoint.index >= 2; // desktop / wide

    return Scaffold(
      body: Row(
        children: [
          _SideNav(
            currentIndex: currentIndex,
            onSelected: onDestinationSelected,
            extended: extended,
            tripName: tripName,
            onExit: onExit,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          destinations: [
            for (final d in AppDestination.values)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon, color: d.color),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.currentIndex,
    required this.onSelected,
    required this.extended,
    this.tripName,
    this.onExit,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;
  final String? tripName;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.smooth,
      width: extended ? 248 : 88,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(right: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, Gap.lg),
              child: _Logo(extended: extended, tripName: tripName, onExit: onExit),
            ),
            Gap.vSm,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                children: [
                  for (var i = 0; i < AppDestination.values.length; i++)
                    _NavItem(
                      destination: AppDestination.values[i],
                      selected: currentIndex == i,
                      extended: extended,
                      onTap: () => onSelected(i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: extended
                  ? Text(
                      'Boa viagem ✈️',
                      style: context.text.labelSmall?.copyWith(color: AppColors.inkFaint),
                    )
                  : const Text('✈️', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.extended, this.tripName, this.onExit});

  final bool extended;
  final String? tripName;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: AppColors.sunsetGradient,
        borderRadius: Radii.brMd,
        boxShadow: AppColors.glow(AppColors.coral, opacity: 0.35, blur: 16, y: 6),
      ),
      child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 24),
    );

    if (!extended) {
      return Center(
        child: Tooltip(
          message: 'Minhas viagens',
          child: InkWell(borderRadius: Radii.brMd, onTap: onExit, child: mark),
        ),
      );
    }

    return InkWell(
      borderRadius: Radii.brMd,
      onTap: onExit,
      child: Padding(
        padding: const EdgeInsets.all(Gap.xs),
        child: Row(
          children: [
            mark,
            Gap.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tripName ?? 'Viagem',
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.inkFaint),
                      Gap.hXs,
                      Text('trocar de viagem', style: context.text.labelSmall),
                    ],
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

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final selected = widget.selected;

    final content = Row(
      mainAxisAlignment: widget.extended ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(
          selected ? d.activeIcon : d.icon,
          size: 22,
          color: selected ? d.color : context.colors.onSurfaceVariant,
        ),
        if (widget.extended) ...[
          Gap.hMd,
          Flexible(
            child: Text(
              d.label,
              style: context.text.labelLarge?.copyWith(
                color: selected ? d.color : context.colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.enter,
            padding: EdgeInsets.symmetric(
              horizontal: widget.extended ? Gap.md : Gap.sm,
              vertical: Gap.md,
            ),
            decoration: BoxDecoration(
              // O hover é a mesma cor do destino, só que mais fraca. Com
              // um cinza neutro aqui, passar o mouse e clicar davam duas
              // cores diferentes, e a troca parecia um defeito.
              color: selected
                  ? d.color.withValues(alpha: 0.12)
                  : _hovered
                      ? d.color.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: Radii.brMd,
            ),
            child: widget.extended
                ? content
                : Tooltip(message: d.label, child: content),
          ),
        ),
      ),
    ).animate(target: selected ? 1 : 0).scaleXY(begin: 1, end: 1.02, duration: Motion.fast);
  }
}
