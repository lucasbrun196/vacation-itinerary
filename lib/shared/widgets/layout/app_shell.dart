import 'package:flutter/material.dart';

import '../../../app/destinations.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/member_avatar.dart';
import '../effects/theme_toggle.dart';

/// Casca de navegação adaptativa.
///
/// Mesmo conteúdo em todas as larguras, só a navegação muda de lugar:
/// barra superior com as abas a partir do tablet, barra inferior no
/// celular.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.tripName,
    this.onExit,
    this.userInitials,
    this.onAccount,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? tripName;

  /// Voltar para a lista de viagens.
  final VoidCallback? onExit;

  /// Iniciais da conta logada, no avatar do canto.
  final String? userInitials;
  final VoidCallback? onAccount;

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

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            currentIndex: currentIndex,
            onSelected: onDestinationSelected,
            tripName: tripName,
            onExit: onExit,
            userInitials: userInitials,
            onAccount: onAccount,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Barra inferior do celular: ícone fino e rótulo. A aba ativa ganha uma
/// pílula coral atrás do ícone, que cresce com um leve quique.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final (i, d) in AppDestination.values.indexed)
                Expanded(
                  child: _BottomItem(
                    destination: d,
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.destination, required this.selected, required this.onTap});

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.onSurface : context.colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.enter,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? context.colors.primaryContainer : Colors.transparent,
                borderRadius: Radii.brPill,
              ),
              child: AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: Motion.normal,
                curve: Motion.spring,
                child: Icon(destination.icon, size: 20, color: selected ? context.colors.primary : color),
              ),
            ),
            Gap.vXs,
            AnimatedDefaultTextStyle(
              duration: Motion.fast,
              style: context.text.labelSmall!.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(destination.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superior: a viagem à esquerda, as abas centralizadas numa pílula
/// e, à direita, o tema e a conta.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentIndex,
    required this.onSelected,
    this.tripName,
    this.onExit,
    this.userInitials,
    this.onAccount,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final String? tripName;
  final VoidCallback? onExit;
  final String? userInitials;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Row(
              children: [
                // Os dois lados com o mesmo `flex`: é o que deixa as abas
                // exatamente no centro, seja qual for o nome da viagem.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _TripName(name: tripName ?? 'Viagem', onTap: onExit),
                  ),
                ),
                _TabPill(currentIndex: currentIndex, onSelected: onSelected),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const ThemeToggle(),
                      if (userInitials != null) ...[
                        Gap.hSm,
                        _AccountAvatar(initials: userInitials!, onTap: onAccount),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O selo com a inicial da viagem e o nome dela. Leva de volta à lista de
/// viagens.
class _TripName extends StatefulWidget {
  const _TripName({required this.name, this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  State<_TripName> createState() => _TripNameState();
}

class _TripNameState extends State<_TripName> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.trim().isEmpty ? '?' : widget.name.trim()[0].toUpperCase();

    return Tooltip(
      message: 'Trocar de viagem',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.fromLTRB(6, 6, Gap.md, 6),
            decoration: BoxDecoration(
              color: _hovered ? context.colors.surfaceContainerHigh : Colors.transparent,
              borderRadius: Radii.brPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _hovered ? -0.03 : 0,
                  duration: Motion.normal,
                  curve: Motion.spring,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.sunsetGradient,
                      borderRadius: Radii.brMd,
                      boxShadow: AppColors.glow(AppColors.coral, opacity: 0.3, blur: 10, y: 3),
                    ),
                    child: Text(
                      initial,
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Gap.hMd,
                Flexible(
                  child: Text(
                    widget.name,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Gap.hXs,
                Icon(Icons.unfold_more_rounded, size: 16, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// As abas numa pílula cinza, com um indicador branco que desliza até a
/// ativa. As abas têm largura fixa: é o que permite o indicador saber onde
/// parar sem medir texto.
class _TabPill extends StatelessWidget {
  const _TabPill({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _tabWidth = 100.0;
  static const _height = 40.0;
  static const _inset = 4.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = context.isDark;
    const destinations = AppDestination.values;

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: Radii.brPill,
      ),
      child: SizedBox(
        width: _tabWidth * destinations.length,
        height: _height - _inset * 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPositioned(
              duration: Motion.slow,
              curve: Motion.spring,
              left: _tabWidth * currentIndex,
              top: 0,
              bottom: 0,
              width: _tabWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? colors.surface : Colors.white,
                  borderRadius: Radii.brPill,
                  boxShadow: [
                    BoxShadow(
                      color: (dark ? Colors.black : AppColors.coral).withValues(alpha: dark ? 0.4 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final (i, d) in destinations.indexed)
                  _Tab(
                    destination: d,
                    width: _tabWidth,
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.destination,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;
    final color = selected
        ? colors.primary
        : _hovered
            ? colors.onSurface
            : colors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: Motion.normal,
                curve: Motion.spring,
                child: AnimatedSize(
                  duration: Motion.normal,
                  curve: Motion.enter,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(widget.destination.icon, size: 15, color: color),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: Motion.fast,
                  style: context.text.labelLarge!.copyWith(
                    fontSize: 13.5,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O avatar da conta, com um anel em degradê que gira de leve no hover.
class _AccountAvatar extends StatefulWidget {
  const _AccountAvatar({required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  State<_AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<_AccountAvatar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Minha conta',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.06 : 1,
            duration: Motion.normal,
            curve: Motion.spring,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: const [AppColors.coral, AppColors.sunset, AppColors.grape, AppColors.coral],
                  transform: GradientRotation(_hovered ? 1.2 : 0),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.surface,
                ),
                child: InitialsAvatar(initials: widget.initials, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
