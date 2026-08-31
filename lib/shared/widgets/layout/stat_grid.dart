import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_tokens.dart';

/// Grade dos cartões de número, usada no painel, nos gastos e no roteiro.
///
/// Duas coisas que a grade solta não fazia:
///
/// - abaixo de [Breakpoints.compact] cada célula ficava com ~150px, estreita
///   demais para "Dias com programa" e o valor em reais na mesma coluna;
/// - a altura era uma constante, então aumentar a fonte no navegador estourava
///   o cartão por baixo. Aqui ela cresce junto com a escala do texto.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.itemHeight = 152});

  final List<Widget> children;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = switch (width) {
          _ when width >= Breakpoints.tablet => 3,
          _ when width >= Breakpoints.compact => 2,
          _ => 1,
        };
        // Em coluna única não há grade: empilhados, os cartões tomam a altura
        // do próprio conteúdo. Qualquer altura fixa aqui é um chute que a
        // primeira fonte maior — ou um valor de sete dígitos — estoura.
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Gap.vMd,
                children[i],
              ],
            ],
          );
        }

        final scale = MediaQuery.textScalerOf(context).scale(1);

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
            mainAxisExtent: itemHeight * scale.clamp(1.0, 1.6),
          ),
          children: children,
        );
      },
    );
  }
}
