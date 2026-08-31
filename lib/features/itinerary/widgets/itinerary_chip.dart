import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// A pílula de informação do card do roteiro: categoria, transporte,
/// conta ligada, link, previsão do tempo.
class ItineraryChip extends StatelessWidget {
  const ItineraryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          Gap.hXs,
          // O `Wrap` não encolhe os filhos: sem o `Flexible`, um chip mais
          // largo que a linha estoura em vez de quebrar. O rótulo com o nome
          // da conta é justamente o que passa da faixa de ~230px do card.
          Flexible(
            child: Text(
              label,
              style: context.text.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
