import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/bill_settlement.dart';
import '../../../data/models/bill_share.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../../../shared/widgets/layout/app_sheet.dart';
import '../../../shared/widgets/layout/section_header.dart';
import 'share_payment_sheet.dart';

/// O acerto de uma conta aberta já fechada: quanto cada pessoa pagou e,
/// ao tocar nela, para quem ela deve (ou de quem recebe).
///
/// O "pagou" sai dos lançamentos; as dívidas saem das cotas, que são o
/// que carrega o pagamento e o comprovante de cada transferência.
class SettlementSection extends ConsumerWidget {
  const SettlementSection({super.key, required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(billEntriesProvider(bill.id)).valueOrNull;
    final shares = ref.watch(billSharesProvider(bill.id)).valueOrNull;
    if (entries == null || shares == null) return const SizedBox.shrink();

    final settlement = BillSettlement.of(bill, entries);
    final membersById = ref.watch(membersByIdProvider);
    final ledger = _Ledger(bill, shares);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Acerto',
          subtitle: 'Quanto cada um pagou. Toque para ver para quem deve.',
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, id) in settlement.memberIds.indexed) ...[
                if (i > 0) const Divider(),
                _PersonCard(
                  bill: bill,
                  memberId: id,
                  member: membersById[id],
                  paidCents: settlement.paidBy(id),
                  ledger: ledger,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// As cotas da conta lidas como transferências entre pessoas.
class _Ledger {
  _Ledger(this.bill, this.shares);

  final Bill bill;
  final List<BillShare> shares;

  String? receiverOf(BillShare s) => s.creditorId ?? bill.paidByMemberId;

  List<BillShare> debtsOf(String id) =>
      shares.where((s) => s.memberId == id && !s.isOwnerShare).toList();

  List<BillShare> creditsOf(String id) =>
      shares.where((s) => !s.isOwnerShare && receiverOf(s) == id).toList();

  /// A parte da pessoa na conta: o que ela cobriu sozinha mais o que
  /// transfere.
  int partOf(String id) => shares
      .where((s) => s.memberId == id)
      .fold<int>(0, (sum, s) => sum + s.amountCents);

  static int pending(List<BillShare> list) =>
      list.where((s) => !s.isPaid).fold<int>(0, (sum, s) => sum + s.remainingCents);
}

class _PersonCard extends ConsumerWidget {
  const _PersonCard({
    required this.bill,
    required this.memberId,
    required this.member,
    required this.paidCents,
    required this.ledger,
  });

  final Bill bill;
  final String memberId;
  final Member? member;
  final int paidCents;
  final _Ledger ledger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ledger.debtsOf(memberId);
    final credits = ledger.creditsOf(memberId);
    final toPay = _Ledger.pending(debts);
    final toReceive = _Ledger.pending(credits);
    final isMe = ref.watch(currentUidProvider) == memberId;
    final name = member?.shortName ?? memberId;

    final (String status, Color? statusColor) = toPay > 0
        ? ('deve ${Money.format(toPay)}', null)
        : toReceive > 0
            ? ('tem ${Money.format(toReceive)} a receber', context.success)
            : debts.isEmpty && credits.isEmpty
                ? ('nada a acertar', context.success)
                : ('acerto feito', context.success);

    return InkWell(
      onTap: () => showAppSheet(
        context: context,
        title: name,
        subtitle: 'Acerto · ${bill.title}',
        builder: (_) => _PersonSheet(bill: bill, memberId: memberId),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
        child: Row(
          children: [
            if (member != null) ...[MemberAvatar(member: member!), Gap.hMd],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMe ? '$name (você)' : name,
                    style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    status,
                    style: context.text.bodySmall?.copyWith(color: statusColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.hSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('pagou', style: context.text.labelSmall),
                Text(
                  Money.format(paidCents),
                  style: AppTypography.money(size: 14, color: context.colors.onSurface),
                ),
              ],
            ),
            Gap.hXs,
            Icon(Icons.chevron_right, size: 18, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// O detalhe de uma pessoa: para quem ela transfere e de quem recebe.
/// Cada transferência abre o registro de pagamento.
class _PersonSheet extends ConsumerWidget {
  const _PersonSheet({required this.bill, required this.memberId});

  final Bill bill;
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lido aqui, e não recebido de quem abriu, para a lista refletir na
    // hora o pagamento registrado pelo sheet aninhado.
    final entries = ref.watch(billEntriesProvider(bill.id)).valueOrNull ?? const [];
    final shares = ref.watch(billSharesProvider(bill.id)).valueOrNull ?? const <BillShare>[];
    final membersById = ref.watch(membersByIdProvider);
    final ledger = _Ledger(bill, shares);
    final debts = ledger.debtsOf(memberId);
    final credits = ledger.creditsOf(memberId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Pagou',
                        cents: BillSettlement.of(bill, entries).paidBy(memberId),
                      ),
                    ),
                    Gap.hMd,
                    Expanded(
                      child: _Stat(label: 'Parte na conta', cents: ledger.partOf(memberId)),
                    ),
                  ],
                ),
                if (debts.isNotEmpty) ...[
                  Gap.vXl,
                  Text('Deve para', style: context.text.labelLarge),
                  Gap.vSm,
                  for (final share in debts)
                    _TransferTile(
                      share: share,
                      other: membersById[ledger.receiverOf(share)],
                      showPix: true,
                      onTap: membersById[memberId] == null
                          ? null
                          : () => showPaymentSheet(
                                context,
                                bill: bill,
                                member: membersById[memberId]!,
                                shares: [share],
                              ),
                    ),
                ],
                if (credits.isNotEmpty) ...[
                  Gap.vXl,
                  Text('Recebe de', style: context.text.labelLarge),
                  Gap.vSm,
                  for (final share in credits)
                    _TransferTile(
                      share: share,
                      other: membersById[share.memberId],
                      onTap: membersById[share.memberId] == null
                          ? null
                          : () => showPaymentSheet(
                                context,
                                bill: bill,
                                member: membersById[share.memberId]!,
                                shares: [share],
                              ),
                    ),
                ],
                if (debts.isEmpty && credits.isEmpty) ...[
                  Gap.vXl,
                  Text(
                    'Pagou exatamente a própria parte. Não há nada a acertar.',
                    style: context.text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        SheetActions(
          primaryLabel: 'Fechar',
          onPrimary: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: Radii.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(cents),
              style: AppTypography.money(size: 18, color: context.colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma transferência: com quem, quanto e se já foi paga.
class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.share,
    required this.other,
    required this.onTap,
    this.showPix = false,
  });

  final BillShare share;
  final Member? other;
  final VoidCallback? onTap;
  final bool showPix;

  @override
  Widget build(BuildContext context) {
    final paid = share.isPaid;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: InkWell(
        borderRadius: Radii.brSm,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
          decoration: BoxDecoration(
            borderRadius: Radii.brSm,
            border: Border.all(
              color: paid ? context.success : context.colors.outline,

            ),
          ),
          child: Row(
            children: [
              if (other != null) MemberAvatar(member: other!),
              Gap.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      other?.shortName ?? 'Participante removido',
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      paid
                          ? 'pago'
                          : showPix
                              ? other?.pixKey ?? 'Chave PIX não cadastrada'
                              : 'pendente',
                      style: context.text.bodySmall?.copyWith(
                        color: paid ? context.success : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap.hSm,
              Text(
                Money.format(share.amountCents),
                style: AppTypography.money(
                  size: 16,
                  color: paid ? context.success : context.colors.onSurface,
                ),
              ),
              if (paid) ...[
                Gap.hXs,
                Icon(Icons.check, color: context.success, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
