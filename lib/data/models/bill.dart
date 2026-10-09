import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/money.dart';
import 'bill_share.dart';
import 'enums.dart';

/// Uma **conta** da viagem.
///
/// Cobre os dois comportamentos que aparecem numa viagem de verdade:
///
/// * [BillType.fixed] — "o Airbnb deu 9.000, parcelamos em 6x entre 4".
///   O total é conhecido, o app gera as parcelas e as cotas de cada um.
///
/// * [BillType.accumulating] — "não sei quanto vai dar de gasolina, vou
///   anotando cada posto". O total cresce com os lançamentos e só vira
///   cota no fechamento.
class Bill {
  const Bill({
    required this.id,
    required this.title,
    required this.categories,
    required this.type,
    this.totalAmountCents,
    this.installmentCount = 1,
    this.firstDueDate,
    this.paidByMemberId,
    this.isShared = true,
    this.participantIds = const [],
    this.splitMode = SplitMode.equal,
    this.customWeights = const {},
    this.status = BillStatus.open,
    this.entriesTotalCents = 0,
    this.entriesCount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String title;
  /// Do que é a conta — pode ser mais de uma coisa ("Mercado" e "Café").
  /// Nunca vazia. A ordem é a da escolha, e a primeira é a principal.
  final List<BillCategory> categories;

  /// A categoria principal: dá ícone e cor à conta.
  BillCategory get category => categories.first;

  String get categoriesLabel => categories.map((c) => c.label).join(', ');
  final BillType type;

  /// Valor de referência informado no cadastro. Em conta aberta fica
  /// null e o valor real vem de [entriesTotalCents].
  final int? totalAmountCents;

  final int installmentCount;
  final DateTime? firstDueDate;

  /// Quem desembolsou / vai receber as transferências.
  final String? paidByMemberId;

  final bool isShared;
  final List<String> participantIds;
  final SplitMode splitMode;

  /// memberId → peso, quando a divisão não é igual.
  final Map<String, double> customWeights;

  final BillStatus status;

  /// Somatório dos lançamentos, mantido pelo repositório para evitar
  /// ler a subcoleção inteira só para exibir o total na lista.
  final int entriesTotalCents;
  final int entriesCount;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // ---------------------------------------------------------------
  // Valores derivados
  // ---------------------------------------------------------------

  bool get isInstallment => installmentCount > 1;

  bool get isAccumulating => type == BillType.accumulating;

  /// O que efetivamente será cobrado — é este valor que a divisão usa.
  int get chargedTotalCents =>
      isAccumulating ? entriesTotalCents : (totalAmountCents ?? 0);

  /// Valor cheio de cada parcela (todos os participantes somados).
  /// Sempre derivado: total ÷ número de parcelas.
  int get effectiveInstallmentCents => installmentCount <= 1
      ? chargedTotalCents
      : Money.divide(chargedTotalCents, installmentCount).first;

  int get participantCount => participantIds.isEmpty ? 1 : participantIds.length;

  /// Quanto cada pessoa paga por parcela (aproximado — o valor exato de
  /// cada um sai de [generateShares], que trata os centavos de resto).
  int get perPersonPerInstallmentCents =>
      Money.divide(effectiveInstallmentCents, participantCount).first;

  // ---------------------------------------------------------------
  // Geração das cotas
  // ---------------------------------------------------------------

  /// Produz a matriz `parcela × pessoa` desta conta.
  ///
  /// Função pura: dado o mesmo Bill, sempre gera as mesmas cotas. É o
  /// que garante que a soma das cotas bate exatamente com o total, sem
  /// sobrar nem faltar centavo.
  List<BillShare> generateShares({
    required String tripId,
    int? overrideTotalCents,
    String? billId,
  }) {
    final members = participantIds.isEmpty
        ? (paidByMemberId == null ? const <String>[] : [paidByMemberId!])
        : participantIds;

    if (members.isEmpty) return const [];

    final total = overrideTotalCents ?? chargedTotalCents;
    if (total <= 0) return const [];

    final installments = isInstallment ? installmentCount : 1;

    // Primeiro reparte o total entre as parcelas, depois cada parcela
    // entre as pessoas. Nessa ordem os centavos de resto ficam nas
    // primeiras parcelas, que é o comportamento usual de carnê.
    final perInstallment = Money.divide(total, installments);

    final shares = <BillShare>[];

    for (var i = 0; i < installments; i++) {
      final amounts = splitMode == SplitMode.custom && customWeights.isNotEmpty
          ? Money.divideByWeights(
              perInstallment[i],
              members.map((m) => customWeights[m] ?? 1).toList(),
            )
          : Money.divide(perInstallment[i], members.length);

      for (var j = 0; j < members.length; j++) {
        shares.add(
          BillShare(
            id: '${i + 1}_${members[j]}',
            billId: billId ?? id,
            tripId: tripId,
            memberId: members[j],
            amountCents: amounts[j],
            installmentNumber: isInstallment ? i + 1 : null,
            dueDate: dueDateFor(i + 1),
            isOwnerShare: members[j] == paidByMemberId,
          ),
        );
      }
    }

    return shares;
  }

  /// Vencimento da parcela [number] (1-based), somando meses à primeira.
  DateTime? dueDateFor(int number) {
    final first = firstDueDate;
    if (first == null) return null;
    if (number <= 1) return first;

    final monthsAhead = number - 1;
    final targetMonth = first.month + monthsAhead;
    final year = first.year + (targetMonth - 1) ~/ 12;
    final month = (targetMonth - 1) % 12 + 1;

    // Dia 31 em mês de 30 dias vira o último dia do mês.
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, first.day > lastDay ? lastDay : first.day);
  }

  // ---------------------------------------------------------------
  // Serialização
  // ---------------------------------------------------------------

  /// Lê as categorias aceitando o formato antigo, de uma só em `category`.
  static List<BillCategory> _readCategories(Map<String, dynamic> d) {
    final list = d['categories'];
    final ids = list is List ? list.whereType<String>() : [?d['category'] as String?];
    final result = ids.map(BillCategory.fromId).toSet().toList();
    return result.isEmpty ? const [BillCategory.other] : result;
  }

  factory Bill.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Bill(
      id: doc.id,
      title: d['title'] as String? ?? '',
      categories: _readCategories(d),
      type: BillType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => BillType.fixed,
      ),
      totalAmountCents: (d['totalAmountCents'] as num?)?.toInt(),
      installmentCount: (d['installmentCount'] as num?)?.toInt() ?? 1,
      firstDueDate: (d['firstDueDate'] as Timestamp?)?.toDate(),
      paidByMemberId: d['paidByMemberId'] as String?,
      isShared: d['isShared'] as bool? ?? true,
      participantIds: (d['participantIds'] as List<dynamic>? ?? []).cast<String>(),
      splitMode: SplitMode.values.firstWhere(
        (s) => s.name == d['splitMode'],
        orElse: () => SplitMode.equal,
      ),
      customWeights: (d['customWeights'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      status: BillStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => BillStatus.open,
      ),
      entriesTotalCents: (d['entriesTotalCents'] as num?)?.toInt() ?? 0,
      entriesCount: (d['entriesCount'] as num?)?.toInt() ?? 0,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'categories': [for (final c in categories) c.name],
        // O campo antigo, de uma categoria só. Salvar é `merge: true`, então
        // ele precisa ser apagado na mão, ou volta na leitura.
        'category': FieldValue.delete(),
        'type': type.name,
        'totalAmountCents': totalAmountCents,
        'installmentCount': installmentCount,
        'firstDueDate': firstDueDate == null ? null : Timestamp.fromDate(firstDueDate!),
        'paidByMemberId': paidByMemberId,
        'isShared': isShared,
        'participantIds': participantIds,
        'splitMode': splitMode.name,
        'customWeights': customWeights,
        'status': status.name,
        'entriesTotalCents': entriesTotalCents,
        'entriesCount': entriesCount,
        'notes': notes,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };

  Bill copyWith({
    String? title,
    List<BillCategory>? categories,
    BillType? type,
    int? totalAmountCents,
    int? installmentCount,
    DateTime? firstDueDate,
    String? paidByMemberId,
    bool? isShared,
    List<String>? participantIds,
    SplitMode? splitMode,
    Map<String, double>? customWeights,
    BillStatus? status,
    int? entriesTotalCents,
    int? entriesCount,
    String? notes,
  }) =>
      Bill(
        id: id,
        title: title ?? this.title,
        categories: categories ?? this.categories,
        type: type ?? this.type,
        totalAmountCents: totalAmountCents ?? this.totalAmountCents,
        installmentCount: installmentCount ?? this.installmentCount,
        firstDueDate: firstDueDate ?? this.firstDueDate,
        paidByMemberId: paidByMemberId ?? this.paidByMemberId,
        isShared: isShared ?? this.isShared,
        participantIds: participantIds ?? this.participantIds,
        splitMode: splitMode ?? this.splitMode,
        customWeights: customWeights ?? this.customWeights,
        status: status ?? this.status,
        entriesTotalCents: entriesTotalCents ?? this.entriesTotalCents,
        entriesCount: entriesCount ?? this.entriesCount,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );
}
