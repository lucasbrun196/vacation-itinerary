import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Chips de escolha múltipla. [selected] guarda a ordem em que foram
/// marcados: quem chama costuma tratar o primeiro como o principal (é ele
/// que dá ícone e cor ao card).
///
/// Com [required] o último marcado não desmarca — serve para categoria,
/// que nunca fica vazia.
class MultiChoiceChips<T> extends StatelessWidget {
  const MultiChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.required = false,
  });

  final List<T> options;
  final List<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<List<T>> onChanged;
  final bool required;

  void _toggle(T option) {
    final next = List.of(selected);
    if (next.contains(option)) {
      if (required && next.length == 1) return;
      next.remove(option);
    } else {
      next.add(option);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: (_) => _toggle(option),
          ),
      ],
    );
  }
}
