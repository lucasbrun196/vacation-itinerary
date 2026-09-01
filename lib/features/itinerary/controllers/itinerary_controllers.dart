import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/itinerary_enums.dart';
import '../../../data/models/itinerary_item.dart';

/// Números do roteiro, incluindo o dinheiro que ele já compromete.
class ItinerarySummary {
  const ItinerarySummary({
    required this.total,
    required this.done,
    required this.days,
    required this.linkedCount,
    required this.linkedCents,
  });

  final int total;
  final int done;
  final int days;

  /// Atividades ligadas a alguma conta.
  final int linkedCount;

  /// Soma das contas ligadas ao roteiro. Cada conta conta uma vez, mesmo
  /// que várias atividades apontem para ela — senão o total inflaria.
  final int linkedCents;

  double get progress => total == 0 ? 0 : done / total;

  static const empty =
      ItinerarySummary(total: 0, done: 0, days: 0, linkedCount: 0, linkedCents: 0);
}

final itinerarySummaryProvider = Provider<ItinerarySummary>(
  (ref) {
    final items = ref.watch(itineraryProvider).valueOrNull ?? const <ItineraryItem>[];
    if (items.isEmpty) return ItinerarySummary.empty;

    final bills = {
      for (final b in ref.watch(billsProvider).valueOrNull ?? const <Bill>[]) b.id: b
    };

    final linkedBillIds = <String>{};
    var linkedCount = 0;
    for (final item in items) {
      if (!item.isLinkedToBill) continue;
      linkedCount++;
      linkedBillIds.addAll(item.billIds);
    }

    final linkedCents = linkedBillIds.fold<int>(
      0,
      (sum, id) => sum + (bills[id]?.chargedTotalCents ?? 0),
    );

    return ItinerarySummary(
      total: items.length,
      done: items.where((i) => i.status == ItineraryStatus.done).length,
      days: items.map((i) => i.dayKey).toSet().length,
      linkedCount: linkedCount,
      linkedCents: linkedCents,
    );
  },
  dependencies: [itineraryProvider, billsProvider],
);

/// Quanto cada categoria do roteiro custa, para a visão de estatísticas.
final itinerarySpendByCategoryProvider = Provider<Map<ItineraryCategory, int>>(
  (ref) {
    final items = ref.watch(itineraryProvider).valueOrNull ?? const <ItineraryItem>[];
    final bills = {
      for (final b in ref.watch(billsProvider).valueOrNull ?? const <Bill>[]) b.id: b
    };

    final result = <ItineraryCategory, int>{};
    final counted = <String>{};

    for (final item in items) {
      for (final billId in item.billIds) {
        // A mesma conta ligada a duas atividades entra uma vez só, na
        // categoria da primeira — senão o gasto apareceria dobrado.
        if (!counted.add(billId)) continue;
        final cents = bills[billId]?.chargedTotalCents ?? 0;
        if (cents <= 0) continue;
        result[item.category] = (result[item.category] ?? 0) + cents;
      }
    }

    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  },
  dependencies: [itineraryProvider, billsProvider],
);
