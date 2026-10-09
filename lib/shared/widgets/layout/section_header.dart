import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// Cabeçalho de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Mantido por compatibilidade: título de seção é só texto.
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final action = actionLabel != null && onAction != null
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
            ),
            child: Text(actionLabel!, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : null;

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: context.text.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    // Em tela estreita o botão come a largura do título e o subtítulo quebra
    // em quatro linhas. Melhor a ação embaixo, alinhada à direita.
    final stacked = context.isNarrow && (action != null || trailing != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: label),
              if (!stacked) ...[
                ?trailing,
                ?action,
              ],
            ],
          ),
          if (stacked)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ?trailing,
                  ?action,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
