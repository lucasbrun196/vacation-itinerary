import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/bill_share.dart';

/// Todas as cotas da viagem em um único stream.
///
/// Uma consulta de grupo de coleções custa o mesmo que N consultas por
/// conta, mas cabe em um stream só — o que mantém dashboard, lista de
/// contas e "minhas pendências" sempre coerentes entre si.
final allSharesProvider = StreamProvider<List<BillShare>>(
  (ref) => ref
      .watch(refsProvider)
      .sharesOfTrip(ref.watch(currentTripIdProvider))
      .snapshots()
      .map((snap) => snap.docs.map(BillShare.fromDoc).toList()),
  dependencies: [currentTripIdProvider],
);

final sharesByBillProvider = Provider<Map<String, List<BillShare>>>(
  (ref) {
  final shares = ref.watch(allSharesProvider).valueOrNull ?? const <BillShare>[];
  final grouped = <String, List<BillShare>>{};
  for (final share in shares) {
    grouped.putIfAbsent(share.billId, () => []).add(share);
  }
  return grouped;
  },
  dependencies: [allSharesProvider],
);

/// Situação financeira de uma conta.
class BillSummary {
  const BillSummary({
    required this.totalCents,
    required this.paidCents,
    required this.ownerCents,
    required this.shareCount,
    required this.paidCount,
  });

  final int totalCents;

  /// Inclui a parte de quem bancou, que já está quitada por definição.
  final int paidCents;
  final int ownerCents;
  final int shareCount;
  final int paidCount;

  int get pendingCents => (totalCents - paidCents).clamp(0, totalCents);

  /// Fração quitada, de 0 a 1.
  double get progress => totalCents <= 0 ? 0 : (paidCents / totalCents).clamp(0.0, 1.0);

  bool get isSettled => totalCents > 0 && pendingCents == 0;

  static const empty = BillSummary(
    totalCents: 0,
    paidCents: 0,
    ownerCents: 0,
    shareCount: 0,
    paidCount: 0,
  );

  factory BillSummary.from(Bill bill, List<BillShare> shares) {
    if (shares.isEmpty) {
      return BillSummary(
        totalCents: bill.chargedTotalCents,
        paidCents: 0,
        ownerCents: 0,
        shareCount: 0,
        paidCount: 0,
      );
    }

    var total = 0;
    var paid = 0;
    var owner = 0;
    var paidCount = 0;

    for (final s in shares) {
      total += s.amountCents;
      // A cota de quem bancou não gera transferência: conta como paga.
      if (s.isOwnerShare) {
        owner += s.amountCents;
        paid += s.amountCents;
        paidCount++;
      } else if (s.isPaid) {
        paid += s.effectivePaidCents;
        paidCount++;
      } else {
        paid += s.paidAmountCents ?? 0;
      }
    }

    return BillSummary(
      totalCents: total,
      paidCents: paid,
      ownerCents: owner,
      shareCount: shares.length,
      paidCount: paidCount,
    );
  }
}

final billSummaryProvider = Provider.family<BillSummary, Bill>(
  (ref, bill) {
    final shares = ref.watch(sharesByBillProvider)[bill.id] ?? const <BillShare>[];
    return BillSummary.from(bill, shares);
  },
  dependencies: [sharesByBillProvider],
);

/// Visão geral do dinheiro da viagem inteira.
class MoneyOverview {
  const MoneyOverview({
    required this.totalCents,
    required this.paidCents,
    required this.billCount,
    required this.openBillCount,
  });

  final int totalCents;
  final int paidCents;
  final int billCount;
  final int openBillCount;

  int get pendingCents => (totalCents - paidCents).clamp(0, totalCents);
  double get progress => totalCents <= 0 ? 0 : (paidCents / totalCents).clamp(0.0, 1.0);

  static const empty =
      MoneyOverview(totalCents: 0, paidCents: 0, billCount: 0, openBillCount: 0);
}

final moneyOverviewProvider = Provider<MoneyOverview>(
  (ref) {
  final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
  final byBill = ref.watch(sharesByBillProvider);

  var total = 0;
  var paid = 0;
  var open = 0;

  for (final bill in bills) {
    final shares = byBill[bill.id] ?? const <BillShare>[];
    if (shares.isEmpty) {
      // Conta aberta ainda sem fechamento: o total já conta, mas nada
      // foi dividido, então não há nada quitado.
      total += bill.chargedTotalCents;
      if (bill.chargedTotalCents > 0) open++;
      continue;
    }
    final summary = BillSummary.from(bill, shares);
    total += summary.totalCents;
    paid += summary.paidCents;
    if (!summary.isSettled) open++;
  }

  return MoneyOverview(
    totalCents: total,
    paidCents: paid,
    billCount: bills.length,
    openBillCount: open,
  );
  },
  dependencies: [billsProvider, sharesByBillProvider],
);

/// As cotas que a pessoa deste aparelho ainda precisa pagar,
/// da mais próxima do vencimento para a mais distante.
final myPendingSharesProvider = Provider<List<BillShare>>(
  (ref) {
  final memberId = ref.watch(currentUidProvider);
  if (memberId == null) return const [];

  final shares = ref.watch(allSharesProvider).valueOrNull ?? const <BillShare>[];
  return shares.where((s) => s.memberId == memberId && !s.isPaid && !s.isOwnerShare).toList()
    ..sort((a, b) {
      final ad = a.dueDate, bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
  },
  dependencies: [allSharesProvider],
);

/// O que os outros ainda devem para a pessoa deste aparelho.
final owedToMeProvider = Provider<int>(
  (ref) {
  final memberId = ref.watch(currentUidProvider);
  if (memberId == null) return 0;

  final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
  final payerOf = {for (final b in bills) b.id: b.paidByMemberId};
  final shares = ref.watch(allSharesProvider).valueOrNull ?? const <BillShare>[];

  // No acerto de conta aberta cada cota diz para quem é paga; nas demais
  // quem recebe é quem bancou a conta.
  return shares
      .where((s) =>
          !s.isPaid && !s.isOwnerShare && (s.creditorId ?? payerOf[s.billId]) == memberId)
      .fold<int>(0, (sum, s) => sum + s.remainingCents);
  },
  dependencies: [billsProvider, allSharesProvider],
);

/// Saldo pendente de cada participante na viagem inteira, em centavos:
/// positivo é o que ainda tem a receber, negativo o que ainda tem a pagar.
///
/// Mesma regra do [owedToMeProvider] — quem recebe é o credor da cota ou,
/// sem ele, quem bancou a conta —, só que para todo mundo de uma vez. Por
/// isso a soma dos saldos é sempre zero.
final memberBalancesProvider = Provider<Map<String, int>>(
  (ref) {
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
    final payerOf = {for (final b in bills) b.id: b.paidByMemberId};
    final shares = ref.watch(allSharesProvider).valueOrNull ?? const <BillShare>[];

    final balances = <String, int>{};
    for (final s in shares) {
      if (s.isPaid || s.isOwnerShare) continue;
      final receiver = s.creditorId ?? payerOf[s.billId];
      if (receiver == null || receiver == s.memberId) continue;
      balances.update(s.memberId, (v) => v - s.remainingCents, ifAbsent: () => -s.remainingCents);
      balances.update(receiver, (v) => v + s.remainingCents, ifAbsent: () => s.remainingCents);
    }
    return balances;
  },
  dependencies: [billsProvider, allSharesProvider],
);
