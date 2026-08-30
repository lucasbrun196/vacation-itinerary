import 'package:intl/intl.dart';

/// Dinheiro é sempre representado em **centavos inteiros** no app.
///
/// Motivo: `double` acumula erro em divisões (9000 / 6 / 4 não fecha em
/// binário), e conta de viagem entre amigos precisa fechar no centavo.
/// A conversão para texto acontece só na hora de exibir.
extension CentsX on int {
  double get toReais => this / 100;
  String get formatted => Money.format(this);
  String get formattedCompact => Money.formatCompact(this);
}

abstract final class Money {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
  static final _compact = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 1);

  static String format(int cents) => _currency.format(cents / 100);

  static String formatCompact(int cents) =>
      cents.abs() >= 1000000 ? _compact.format(cents / 100) : format(cents);

  /// Converte texto digitado pelo usuário em centavos.
  /// Aceita "1.234,56", "1234,56", "1234.56" e "1234".
  static int? parse(String input) {
    var clean = input.replaceAll(RegExp(r'[^\d,.-]'), '').trim();
    if (clean.isEmpty) return null;

    // Formato pt-BR: ponto é milhar, vírgula é decimal.
    if (clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    }

    final value = double.tryParse(clean);
    if (value == null) return null;
    return (value * 100).round();
  }

  /// Divide [totalCents] em [parts] partes iguais **sem perder centavos**.
  ///
  /// O resto é distribuído um centavo por vez, do primeiro em diante.
  /// Ex.: 100 centavos entre 3 → [34, 33, 33], somando exatamente 100.
  static List<int> divide(int totalCents, int parts) {
    if (parts <= 0) return const [];

    final negative = totalCents < 0;
    final total = totalCents.abs();

    final base = total ~/ parts;
    final remainder = total % parts;

    final result = List<int>.generate(
      parts,
      (i) => i < remainder ? base + 1 : base,
    );

    return negative ? result.map((c) => -c).toList() : result;
  }

  /// Divide proporcionalmente a pesos arbitrários, preservando o total.
  static List<int> divideByWeights(int totalCents, List<double> weights) {
    final sum = weights.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return List.filled(weights.length, 0);

    final raw = weights.map((w) => totalCents * w / sum).toList();
    final floored = raw.map((v) => v.floor()).toList();
    var distributed = floored.fold<int>(0, (a, b) => a + b);

    // Sobras vão para quem tem a maior parte fracionária.
    final order = List.generate(raw.length, (i) => i)
      ..sort((a, b) => (raw[b] - floored[b]).compareTo(raw[a] - floored[a]));

    var i = 0;
    while (distributed < totalCents && order.isNotEmpty) {
      floored[order[i % order.length]] += 1;
      distributed += 1;
      i++;
    }

    return floored;
  }
}
