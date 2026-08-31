import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';

/// Formata enquanto digita: cada tecla empurra os centavos.
/// Digitar "9000000" vira "R$ 90.000,00" naturalmente.
class _CentsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final cents = int.parse(digits.substring(0, digits.length.clamp(0, 15)));
    final text = Money.format(cents);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Campo de valor em reais. Devolve **centavos**, nunca double.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.helper,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.big = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? helper;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<int?>? onChanged;
  final String? Function(String?)? validator;

  /// Versão grande, para o campo principal de um formulário.
  final bool big;

  static int? centsOf(TextEditingController controller) => Money.parse(controller.text);

  static void setCents(TextEditingController controller, int? cents) {
    controller.text = cents == null ? '' : Money.format(cents);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_CentsInputFormatter()],
      // 30px no celular estoura o campo já em sete dígitos, e o `R$` some
      // rolando para fora. Em tela estreita o número entra menor.
      style: big
          ? AppTypography.money(
              size: context.isNarrow ? 24 : 30,
              color: context.colors.onSurface,
            )
          : AppTypography.money(size: 17, color: context.colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? r'R$ 0,00',
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: big ? null : const Icon(Icons.payments_outlined, size: 20),
      ),
      validator: validator,
      onChanged: (_) => onChanged?.call(Money.parse(controller.text)),
    );
  }
}

/// Campo numérico simples (nº de parcelas, por exemplo).
class IntField extends StatelessWidget {
  const IntField({
    super.key,
    required this.controller,
    this.label,
    this.suffix,
    this.min = 1,
    this.max = 60,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? suffix;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      onChanged: (v) {
        final parsed = int.tryParse(v) ?? min;
        onChanged?.call(parsed.clamp(min, max));
      },
    );
  }
}
