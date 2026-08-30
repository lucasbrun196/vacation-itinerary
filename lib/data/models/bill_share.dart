import 'package:cloud_firestore/cloud_firestore.dart';

import 'attachment.dart';

/// Uma **cota**: o que uma pessoa deve, em uma parcela específica.
///
/// É a unidade mais granular do controle de dinheiro. O Airbnb de 6
/// parcelas dividido entre 4 pessoas gera 24 cotas — e é justamente essa
/// granularidade que permite marcar "a Ana pagou a parcela 3" e anexar o
/// comprovante do PIX daquela transferência específica.
class BillShare {
  const BillShare({
    required this.id,
    required this.billId,
    this.tripId = '',
    required this.memberId,
    required this.amountCents,
    this.installmentNumber,
    this.dueDate,
    this.isPaid = false,
    this.paidAt,
    this.paidAmountCents,
    this.paymentGroupId,
    this.receipts = const [],
    this.isOwnerShare = false,
    this.notes,
  });

  final String id;
  final String billId;

  /// Carimbado em toda cota para que a consulta de grupo de coleções
  /// possa ser filtrada por viagem — sem isso, "minhas pendências"
  /// atravessaria as viagens de todo mundo.
  final String tripId;

  final String memberId;
  final int amountCents;

  /// 1..n para contas parceladas; null quando é pagamento único.
  final int? installmentNumber;
  final DateTime? dueDate;

  final bool isPaid;
  final DateTime? paidAt;

  /// Permite pagamento parcial de uma cota. Null = pagou o valor cheio.
  final int? paidAmountCents;

  /// Quando alguém adianta várias parcelas de uma vez, todas as cotas
  /// pagas naquele PIX compartilham este id e o mesmo comprovante.
  final String? paymentGroupId;

  final List<Attachment> receipts;

  /// A cota de quem bancou a conta. Não precisa transferir para si mesmo,
  /// mas continua contando na divisão.
  final bool isOwnerShare;

  final String? notes;

  int get effectivePaidCents => isPaid ? (paidAmountCents ?? amountCents) : (paidAmountCents ?? 0);
  int get remainingCents => (amountCents - effectivePaidCents).clamp(0, amountCents);

  bool get isOverdue =>
      !isPaid && !isOwnerShare && dueDate != null && DateTime.now().isAfter(dueDate!);

  /// Pagou antes do vencimento — o app dá um destaque positivo para isso.
  bool get isEarly =>
      isPaid && paidAt != null && dueDate != null && paidAt!.isBefore(dueDate!);

  factory BillShare.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BillShare(
      id: doc.id,
      billId: d['billId'] as String? ?? '',
      tripId: d['tripId'] as String? ?? '',
      memberId: d['memberId'] as String? ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      installmentNumber: (d['installmentNumber'] as num?)?.toInt(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      isPaid: d['isPaid'] as bool? ?? false,
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
      paidAmountCents: (d['paidAmountCents'] as num?)?.toInt(),
      paymentGroupId: d['paymentGroupId'] as String?,
      receipts: (d['receipts'] as List<dynamic>? ?? [])
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isOwnerShare: d['isOwnerShare'] as bool? ?? false,
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'billId': billId,
        'tripId': tripId,
        'memberId': memberId,
        'amountCents': amountCents,
        'installmentNumber': installmentNumber,
        'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
        'isPaid': isPaid,
        'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
        'paidAmountCents': paidAmountCents,
        'paymentGroupId': paymentGroupId,
        'receipts': receipts.map((r) => r.toMap()).toList(),
        'isOwnerShare': isOwnerShare,
        'notes': notes,
      };

  BillShare copyWith({
    int? amountCents,
    bool? isPaid,
    DateTime? paidAt,
    int? paidAmountCents,
    String? paymentGroupId,
    List<Attachment>? receipts,
    String? notes,
    bool clearPayment = false,
  }) =>
      BillShare(
        id: id,
        billId: billId,
        tripId: tripId,
        memberId: memberId,
        amountCents: amountCents ?? this.amountCents,
        installmentNumber: installmentNumber,
        dueDate: dueDate,
        isPaid: clearPayment ? false : (isPaid ?? this.isPaid),
        paidAt: clearPayment ? null : (paidAt ?? this.paidAt),
        paidAmountCents: clearPayment ? null : (paidAmountCents ?? this.paidAmountCents),
        paymentGroupId: clearPayment ? null : (paymentGroupId ?? this.paymentGroupId),
        receipts: receipts ?? this.receipts,
        isOwnerShare: isOwnerShare,
        notes: notes ?? this.notes,
      );
}
