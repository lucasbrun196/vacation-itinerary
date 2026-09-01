import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/itinerary_item.dart';
import '../services/firestore_refs.dart';

class ItineraryRepository {
  ItineraryRepository(this._refs);

  final FirestoreRefs _refs;

  /// Roteiro inteiro da viagem, já ordenado por dia e horário.
  ///
  /// A ordenação é feita aqui e não no Firestore porque "sem horário vai
  /// para o fim do dia" não é expressável em `orderBy` — e uma viagem tem
  /// dezenas de itens, não milhares.
  Stream<List<ItineraryItem>> watchItinerary(String tripId) =>
      _refs.itinerary(tripId).snapshots().map((snap) {
        final items = snap.docs.map(ItineraryItem.fromDoc).toList();
        items.sort((a, b) {
          final byDay = a.date.compareTo(b.date);
          return byDay != 0 ? byDay : a.compareForDay(b);
        });
        return items;
      });

  Future<String> saveItem(String tripId, ItineraryItem item) async {
    final id = item.id.isEmpty ? _refs.itinerary(tripId).doc().id : item.id;
    await _refs.itinerary(tripId).doc(id).set(item.toMap(), SetOptions(merge: true));
    return id;
  }

  Future<void> deleteItem(String tripId, String itemId) =>
      _refs.itinerary(tripId).doc(itemId).delete();

  Future<void> setStatus(String tripId, String itemId, String status) =>
      _refs.itinerary(tripId).doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Desfaz o vínculo de todas as atividades ligadas a uma conta que
  /// deixou de existir, para o roteiro não apontar para o vazio.
  /// As outras contas da atividade continuam ligadas — some só a que
  /// deixou de existir.
  ///
  /// A consulta é feita duas vezes porque itens salvos antes da lista
  /// ainda guardam a conta em `billId`, e o Firestore não casa os dois
  /// formatos em um filtro só.
  Future<void> unlinkBill(String tripId, String billId) async {
    final results = await Future.wait([
      _refs.itinerary(tripId).where('billIds', arrayContains: billId).get(),
      _refs.itinerary(tripId).where('billId', isEqualTo: billId).get(),
    ]);

    final batch = _refs.db.batch();
    final touched = <String>{};

    for (final doc in results.first.docs) {
      touched.add(doc.id);
      batch.update(doc.reference, {
        'billIds': FieldValue.arrayRemove([billId]),
      });
    }
    for (final doc in results.last.docs) {
      if (!touched.add(doc.id)) continue;
      batch.update(doc.reference, {'billId': FieldValue.delete()});
    }

    if (touched.isEmpty) return;
    await batch.commit();
  }
}
