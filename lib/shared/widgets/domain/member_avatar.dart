import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/member.dart';

/// Avatar do participante: emoji sobre a cor dele.
/// Sem foto, sem upload — identidade instantânea e sem burocracia.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 40,
    this.selected = false,
    this.showBorder = true,
  });

  final Member member;
  final double size;
  final bool selected;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.enter,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.color.withValues(alpha: selected ? 0.24 : 0.14),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: selected ? member.color : member.color.withValues(alpha: 0.3),
                width: selected ? 2.2 : 1.2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        member.emoji,
        style: TextStyle(fontSize: size * 0.46),
      ),
    );
  }
}

/// Avatar + nome, na horizontal.
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  final Member member;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: Radii.brPill,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.sm),
          decoration: BoxDecoration(
            color: selected ? member.color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: Radii.brPill,
            border: Border.all(
              color: selected ? member.color.withValues(alpha: 0.5) : context.colors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(member: member, size: 32, selected: selected, showBorder: false),
              Gap.hSm,
              // `Flexible` porque o chip vive dentro de `Wrap`/`Row`: sem
              // isso um nome longo empurra o chip para fora da tela.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.shortName,
                      style: context.text.labelLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.text.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[Gap.hSm, trailing!],
              Gap.hXs,
            ],
          ),
        ),
      ),
    );
  }
}
