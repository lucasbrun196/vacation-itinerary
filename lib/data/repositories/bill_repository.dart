import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';
import '../models/bill.dart';
import '../models/bill_entry.dart';
import '../models/bill_settlement.dart';
import '../models/bill_share.dart';
import '../models/enums.dart';
import '../services/firestore_refs.dart';
import 'itinerary_repository.dart';
import '../services/storage_service.dart';

class BillRepository {
  BillRepository(this._refs, this._storage);

  final FirestoreRefs _refs;
  final StorageService _storage;
  static const _uuid = Uuid();

  // ---------------------------------------------------------------
  // Contas
  // ---------------------------------------------------------------

  Stream<List<Bill>> watchBills(String tripId) => _refs
      .bills(tripId)
      .snapshots()
      .map((snap) => snap.docs.map(Bill.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  Stream<Bill?> watchBill(String tripId, String billId) => _refs
      .bill(tripId, billId)
      .snapshots()
      .map((doc) => doc.exists ? Bill.fromDoc(doc) : null);

  /// Cria a conta e, quando o valor já é conhecido, as cotas de cada um.
  ///
  /// Conta aberta nasce sem cotas: elas só existem depois do fechamento,
  /// quando o total finalmente é conhecido.
  Future<String> createBill(String tripId, Bill bill) async {
    final id = bill.id.isEmpty ? _refs.bills(tripId).doc().id : bill.id;
    final batch = _refs.db.batch();

    // Documento novo não tem campo antigo para apagar — e um `set` sem
    // `merge` recusa o `FieldValue.delete()` que o `toMap` manda.
    final data = bill.toMap()..remove('category');
    batch.set(
      _refs.bill(tripId, id),
      {...data, 'createdAt': FieldValue.serverTimestamp()},
    );

    if (!bill.isAccumulating) {
      for (final share in bill.generateShares(tripId: tripId, billId: id)) {
        batch.set(_refs.shares(tripId, id).doc(share.id), share.toMap());
      }
    }

    await batch.commit();
    return id;
  }

  /// Regrava a conta e recalcula as cotas **preservando os pagamentos**.
  ///
  /// Os ids das cotas são determinísticos (`parcela_pessoa`), então uma
  /// cota já paga mantém comprovante e data mesmo se o valor mudar.
  Future<void> updateBill(String tripId, Bill bill) async {
    final regenerated = !bill.isAccumulating
        ? bill.generateShares(tripId: tripId)
        : bill.status == BillStatus.open
            ? <BillShare>[]
            : await _settlementShares(tripId, bill);

    final batch = _refs.db.batch();
    batch.set(_refs.bill(tripId, bill.id), bill.toMap(), SetOptions(merge: true));
    await _replaceShares(batch, tripId, bill, regenerated);
    await batch.commit();
  }

  /// As cotas do acerto de uma conta aberta, a partir dos lançamentos.
  Future<List<BillShare>> _settlementShares(String tripId, Bill bill) async {
    final entries = await _refs.entries(tripId, bill.id).get();
    return BillSettlement.of(bill, entries.docs.map(BillEntry.fromDoc).toList())
        .toShares(tripId: tripId, billId: bill.id);
  }

  /// Troca as cotas da conta por [regenerated], levando o pagamento de
  /// cada cota antiga para a nova equivalente e apagando as que sumiram
  /// (participante removido, menos parcelas, transferência que deixou de
  /// existir).
  ///
  /// "Equivalente" é a mesma parcela, do mesmo devedor, para o mesmo
  /// credor — e não o mesmo id: no acerto de conta aberta, a cota antiga
  /// `1_{uid}` (de quando só quem bancou a conta recebia) vira
  /// `1_{uid}_{credor}`, e o pagamento dela não pode se perder.
  Future<void> _replaceShares(
    WriteBatch batch,
    String tripId,
    Bill bill,
    List<BillShare> regenerated,
  ) async {
    final existing = await _refs.shares(tripId, bill.id).get();

    String key(BillShare s) => [
          s.installmentNumber ?? 1,
          s.memberId,
          s.isOwnerShare ? '' : s.creditorId ?? bill.paidByMemberId,
        ].join('_');

    final byKey = {
      for (final doc in existing.docs) key(BillShare.fromDoc(doc)): BillShare.fromDoc(doc),
    };

    final keep = <String>{};
    for (final share in regenerated) {
      keep.add(share.id);
      final old = byKey[key(share)];
      final merged = old == null
          ? share
          : share.copyWith(
              isPaid: old.isPaid,
              paidAt: old.paidAt,
              paidAmountCents: old.paidAmountCents,
              paymentGroupId: old.paymentGroupId,
              receipts: old.receipts,
              notes: old.notes,
            );
      batch.set(_refs.shares(tripId, bill.id).doc(share.id), merged.toMap());
    }

    for (final doc in existing.docs) {
      if (!keep.contains(doc.id)) batch.delete(doc.reference);
    }
  }

  /// Apaga a conta, suas subcoleções e os arquivos no Storage.
  ///
  /// Também desfaz o vínculo das atividades do roteiro que apontavam
  /// para ela — senão o roteiro exibiria uma conta fantasma.
  Future<void> deleteBill(String tripId, String billId) async {
    final entries = await _refs.entries(tripId, billId).get();
    final shares = await _refs.shares(tripId, billId).get();

    for (final doc in entries.docs) {
      for (final r in BillEntry.fromDoc(doc).receipts) {
        await _storage.delete(r.storagePath);
      }
    }
    for (final doc in shares.docs) {
      for (final r in BillShare.fromDoc(doc).receipts) {
        await _storage.delete(r.storagePath);
      }
    }

    final batch = _refs.db.batch();
    for (final doc in entries.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in shares.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_refs.bill(tripId, billId));
    await batch.commit();

    await ItineraryRepository(_refs).unlinkBill(tripId, billId);
  }

  // ---------------------------------------------------------------
  // Lançamentos (conta aberta)
  // ---------------------------------------------------------------

  Stream<List<BillEntry>> watchEntries(String tripId, String billId) => _refs
      .entries(tripId, billId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(BillEntry.fromDoc).toList());

  /// Grava o lançamento e atualiza o total da conta na mesma transação,
  /// para o total nunca divergir da soma dos lançamentos.
  Future<void> saveEntry(String tripId, BillEntry entry) async {
    final id = entry.id.isEmpty ? _refs.entries(tripId, entry.billId).doc().id : entry.id;
    final ref = _refs.entries(tripId, entry.billId).doc(id);

    await _refs.db.runTransaction((tx) async {
      final billSnap = await tx.get(_refs.bill(tripId, entry.billId));
      final previous = (await ref.get()).data();
      final previousCents = (previous?['amountCents'] as num?)?.toInt() ?? 0;
      final isNew = previous == null;

      final currentTotal = (billSnap.data()?['entriesTotalCents'] as num?)?.toInt() ?? 0;
      final currentCount = (billSnap.data()?['entriesCount'] as num?)?.toInt() ?? 0;

      tx.set(ref, entry.toMap(), SetOptions(merge: true));
      tx.update(_refs.bill(tripId, entry.billId), {
        'entriesTotalCents': currentTotal - previousCents + entry.amountCents,
        'entriesCount': isNew ? currentCount + 1 : currentCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteEntry(String tripId, BillEntry entry) async {
    for (final r in entry.receipts) {
      await _storage.delete(r.storagePath);
    }

    await _refs.db.runTransaction((tx) async {
      final billSnap = await tx.get(_refs.bill(tripId, entry.billId));
      final currentTotal = (billSnap.data()?['entriesTotalCents'] as num?)?.toInt() ?? 0;
      final currentCount = (billSnap.data()?['entriesCount'] as num?)?.toInt() ?? 0;

      tx.delete(_refs.entries(tripId, entry.billId).doc(entry.id));
      tx.update(_refs.bill(tripId, entry.billId), {
        'entriesTotalCents': (currentTotal - entry.amountCents).clamp(0, 1 << 62),
        'entriesCount': (currentCount - 1).clamp(0, 1 << 62),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------
  // Cotas
  // ---------------------------------------------------------------

  Stream<List<BillShare>> watchShares(String tripId, String billId) => _refs
      .shares(tripId, billId)
      .snapshots()
      .map((snap) => snap.docs.map(BillShare.fromDoc).toList()
        ..sort((a, b) {
          final byInstallment = (a.installmentNumber ?? 0).compareTo(b.installmentNumber ?? 0);
          return byInstallment != 0 ? byInstallment : a.memberId.compareTo(b.memberId);
        }));

  /// Marca uma cota como paga ou volta para pendente.
  Future<void> setSharePaid(
    String tripId,
    BillShare share, {
    required bool isPaid,
    DateTime? paidAt,
    int? paidAmountCents,
  }) =>
      _refs.shares(tripId, share.billId).doc(share.id).update({
        'isPaid': isPaid,
        'paidAt': isPaid ? Timestamp.fromDate(paidAt ?? DateTime.now()) : null,
        'paidAmountCents': isPaid ? paidAmountCents : null,
        if (!isPaid) 'paymentGroupId': null,
      });

  /// Adiantamento: quita várias cotas em um único PIX.
  ///
  /// Todas passam a compartilhar o mesmo `paymentGroupId` e o mesmo
  /// comprovante, que é o que aconteceu de fato no mundo real.
  Future<void> payShares(
    String tripId,
    List<BillShare> shares, {
    DateTime? paidAt,
    List<Attachment> receipts = const [],
  }) async {
    if (shares.isEmpty) return;
    final groupId = _uuid.v4();
    final when = Timestamp.fromDate(paidAt ?? DateTime.now());

    final batch = _refs.db.batch();
    for (final share in shares) {
      batch.update(_refs.shares(tripId, share.billId).doc(share.id), {
        'isPaid': true,
        'paidAt': when,
        'paymentGroupId': groupId,
        if (receipts.isNotEmpty)
          'receipts': [...share.receipts, ...receipts].map((r) => r.toMap()).toList(),
      });
    }
    await batch.commit();
  }

  Future<void> addShareReceipt(String tripId, BillShare share, Attachment receipt) =>
      _refs.shares(tripId, share.billId).doc(share.id).update({
        'receipts': FieldValue.arrayUnion([receipt.toMap()]),
      });

  Future<void> removeShareReceipt(String tripId, BillShare share, Attachment receipt) async {
    await _refs.shares(tripId, share.billId).doc(share.id).update({
      'receipts': share.receipts.where((r) => r.id != receipt.id).map((r) => r.toMap()).toList(),
    });
    await _storage.delete(receipt.storagePath);
  }

  Future<void> addEntryReceipt(String tripId, BillEntry entry, Attachment receipt) =>
      _refs.entries(tripId, entry.billId).doc(entry.id).update({
        'receipts': FieldValue.arrayUnion([receipt.toMap()]),
      });

  Future<void> removeEntryReceipt(String tripId, BillEntry entry, Attachment receipt) async {
    await _refs.entries(tripId, entry.billId).doc(entry.id).update({
      'receipts': entry.receipts.where((r) => r.id != receipt.id).map((r) => r.toMap()).toList(),
    });
    await _storage.delete(receipt.storagePath);
  }

  /// Fecha uma conta aberta: congela o total e gera o acerto — quem
  /// transfere quanto para quem, conforme quem bancou cada lançamento.
  Future<void> closeAccumulatingBill(String tripId, Bill bill) async {
    final entries = await _refs.entries(tripId, bill.id).get();
    final settlement =
        BillSettlement.of(bill, entries.docs.map(BillEntry.fromDoc).toList());

    final batch = _refs.db.batch();
    batch.update(_refs.bill(tripId, bill.id), {
      'status': BillStatus.settled.name,
      'totalAmountCents': settlement.totalCents,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _replaceShares(
      batch,
      tripId,
      bill,
      settlement.toShares(tripId: tripId, billId: bill.id),
    );

    await batch.commit();
  }

  /// Reabre a conta para continuar lançando.
  Future<void> reopenBill(String tripId, String billId) =>
      _refs.bill(tripId, billId).update({
        'status': BillStatus.open.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  StorageService get storage => _storage;
}
