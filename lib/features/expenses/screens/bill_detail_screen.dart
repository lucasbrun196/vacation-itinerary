import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinations.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/bill_entry.dart';
import '../../../data/models/bill_share.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import '../../../shared/widgets/cards/gradient_card.dart';
import '../../../shared/widgets/domain/member_avatar.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/feedback/loading_shimmer.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../../shared/widgets/media/attachment_tile.dart';
import '../controllers/money_controllers.dart';
import '../widgets/bill_form_sheet.dart';
import '../widgets/entry_form_sheet.dart';
import '../widgets/share_payment_sheet.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(billProvider(billId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: billAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Gap.xl),
          child: ShimmerList(itemCount: 4, itemHeight: 100),
        ),
        error: (e, _) => ErrorView(message: 'Não deu para carregar a conta', details: '$e'),
        data: (bill) => bill == null
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Conta não encontrada',
                message: 'Ela pode ter sido apagada por outra pessoa.',
                actionLabel: 'Voltar',
                onAction: () => context.pop(),
              )
            : _BillDetailBody(bill: bill),
      ),
    );
  }
}

class _BillDetailBody extends ConsumerWidget {
  const _BillDetailBody({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(billSummaryProvider(bill));
    final sharesAsync = ref.watch(billSharesProvider(bill.id));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: ContentContainer(
              child: Padding(
                padding: EdgeInsets.only(top: context.isMobile ? Gap.md : Gap.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(bill: bill),
                    Gap.vLg,
                    _BillHeader(bill: bill, summary: summary),
                    Gap.vXl,
                    if (bill.isAccumulating)
                      _EntriesSection(bill: bill)
                    else
                      _SharesSection(bill: bill, shares: sharesAsync.valueOrNull ?? const []),
                    if (bill.isAccumulating && bill.status == BillStatus.settled) ...[
                      Gap.vXl,
                      _SharesSection(bill: bill, shares: sharesAsync.valueOrNull ?? const []),
                    ],
                    if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                      Gap.vXl,
                      const SectionHeader(title: 'Observações', icon: Icons.notes_rounded),
                      GlassCard(child: Text(bill.notes!, style: context.text.bodyMedium)),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => context.go(
            Routes.tripSection(ref.read(currentTripIdProvider), AppDestination.expenses),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        const Spacer(),
        IconButton(
          onPressed: () => showBillForm(context, bill: bill),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar conta',
        ),
        IconButton(
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Excluir conta',
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir esta conta?'),
        content: Text(
          'Todos os lançamentos, cotas e comprovantes de "${bill.title}" '
          'serão apagados. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final tripId = ref.read(currentTripIdProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Sai da tela antes de apagar. A exclusão varre subcoleções e
    // arquivos, e o documento some do stream no meio do caminho — ficar
    // aqui faria a tela piscar "conta não encontrada" antes de sair.
    context.go(Routes.tripSection(tripId, AppDestination.expenses));

    try {
      await ref.read(billRepositoryProvider).deleteBill(tripId, bill.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Conta excluída')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Não deu para excluir a conta: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
    }
  }
}

class _BillHeader extends ConsumerWidget {
  const _BillHeader({required this.bill, required this.summary});

  final Bill bill;
  final BillSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = bill.paidByMemberId == null
        ? null
        : ref.watch(membersByIdProvider)[bill.paidByMemberId];

    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bill.category.color, bill.category.color.withValues(alpha: 0.72)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bill.category.icon, color: Colors.white70, size: 18),
              Gap.hSm,
              Text(
                bill.category.label,
                style: context.text.labelMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          Gap.vSm,
          Text(
            bill.title,
            style: (context.isMobile ? context.text.headlineMedium : context.text.displaySmall)
                ?.copyWith(color: Colors.white),
          ),
          Gap.vLg,
          Text(
            Money.format(summary.totalCents),
            style: AppTypography.money(size: context.isMobile ? 32 : 38, color: Colors.white),
          ),
          if (bill.isInstallment)
            Text(
              '${bill.installmentCount}x de ${Money.format(bill.effectiveInstallmentCents)} '
              '· ${Money.format(bill.perPersonPerInstallmentCents)} por pessoa',
              style: context.text.bodySmall?.copyWith(color: Colors.white70),
            ),
          if (summary.shareCount > 0) ...[
            Gap.vLg,
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: summary.progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Gap.vSm,
            Row(
              children: [
                Flexible(
                  child: Text(
                    summary.isSettled
                        ? 'Tudo quitado 🎉'
                        : '${Money.format(summary.pendingCents)} em aberto',
                    style: context.text.bodySmall?.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (owner != null)
                  Flexible(
                    child: Text(
                      '${owner.shortName} bancou',
                      style: context.text.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Cotas: uma faixa por pessoa, com as parcelas em bolinhas
// ---------------------------------------------------------------

class _SharesSection extends ConsumerWidget {
  const _SharesSection({required this.bill, required this.shares});

  final Bill bill;
  final List<BillShare> shares;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shares.isEmpty) {
      return const SizedBox.shrink();
    }

    final membersById = ref.watch(membersByIdProvider);
    final byMember = <String, List<BillShare>>{};
    for (final share in shares) {
      byMember.putIfAbsent(share.memberId, () => []).add(share);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: bill.isInstallment ? 'Quem deve o quê' : 'Divisão',
          subtitle: bill.isInstallment
              ? 'Toque em uma pessoa para registrar o pagamento'
              : 'Toque para registrar o pagamento',
          icon: Icons.groups_rounded,
        ),
        for (final entry in byMember.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: _MemberShareCard(
              bill: bill,
              member: membersById[entry.key],
              memberId: entry.key,
              shares: entry.value,
            ),
          ),
      ],
    );
  }
}

class _MemberShareCard extends ConsumerWidget {
  const _MemberShareCard({
    required this.bill,
    required this.member,
    required this.memberId,
    required this.shares,
  });

  final Bill bill;
  final Member? member;
  final String memberId;
  final List<BillShare> shares;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = shares.first.isOwnerShare;
    final total = shares.fold<int>(0, (sum, s) => sum + s.amountCents);
    final paid = shares.where((s) => s.isPaid || s.isOwnerShare).length;
    final pendingCents = isOwner
        ? 0
        : shares.where((s) => !s.isPaid).fold<int>(0, (sum, s) => sum + s.remainingCents);
    final isMe = ref.watch(currentUidProvider) == memberId;
    final color = member?.color ?? AppColors.inkMuted;

    return GlassCard(
      accent: color,
      onTap: isOwner || member == null
          ? null
          : () => showPaymentSheet(
                context,
                bill: bill,
                member: member!,
                shares: shares,
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member != null) MemberAvatar(member: member!, size: 42),
              Gap.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Sem `Flexible` o nome estoura a faixa — e o
                        // fallback aqui é o uid, com 28 caracteres.
                        Flexible(
                          child: Text(
                            member?.shortName ?? memberId,
                            style: context.text.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          Gap.hSm,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.16),
                              borderRadius: Radii.brPill,
                            ),
                            child: Text(
                              'você',
                              style: context.text.labelSmall
                                  ?.copyWith(color: AppColors.turquoise),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isOwner
                          ? 'bancou a conta · sua parte já está inclusa'
                          : pendingCents == 0
                              ? 'tudo pago'
                              : 'faltam ${Money.format(pendingCents)}',
                      style: context.text.bodySmall?.copyWith(
                        color: isOwner
                            ? AppColors.success
                            : pendingCents == 0
                                ? AppColors.success
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(total),
                    style: AppTypography.money(size: 17, color: context.colors.onSurface),
                  ),
                  if (bill.isInstallment)
                    Text('$paid/${shares.length} parcelas', style: context.text.labelSmall),
                ],
              ),
            ],
          ),
          if (bill.isInstallment) ...[
            Gap.vLg,
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final share in shares)
                  _InstallmentDot(
                    share: share,
                    color: color,
                    onTap: isOwner || member == null
                        ? null
                        : () => showPaymentSheet(
                              context,
                              bill: bill,
                              member: member!,
                              shares: shares,
                              preselect: share,
                            ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma parcela: verde paga, vermelha vencida, cinza pendente.
class _InstallmentDot extends StatelessWidget {
  const _InstallmentDot({required this.share, required this.color, this.onTap});

  final BillShare share;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData? icon) = share.isOwnerShare
        ? (AppColors.success.withValues(alpha: 0.14), AppColors.success, Icons.check_rounded)
        : share.isPaid
            ? (AppColors.success, Colors.white, Icons.check_rounded)
            : share.isOverdue
                ? (AppColors.danger.withValues(alpha: 0.14), AppColors.danger, null)
                : (context.colors.surfaceContainerHigh, context.colors.onSurfaceVariant, null);

    return Tooltip(
      message: [
        'Parcela ${share.installmentNumber}',
        Money.format(share.amountCents),
        if (share.dueDate != null) 'vence ${Fmt.dateShort(share.dueDate!)}',
        if (share.isPaid && share.paidAt != null) 'pago ${Fmt.dateShort(share.paidAt!)}',
      ].join(' · '),
      child: InkWell(
        borderRadius: Radii.brSm,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Radii.brSm,
            border: share.isOverdue ? Border.all(color: AppColors.danger, width: 1.4) : null,
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 18, color: fg)
                : Text(
                    '${share.installmentNumber}',
                    style: context.text.labelMedium?.copyWith(color: fg),
                  ),
          ),
        ),
      ),
    ).animate(target: share.isPaid ? 1 : 0).scaleXY(
          begin: 1,
          end: 1.06,
          duration: Motion.fast,
          curve: Motion.spring,
        );
  }
}

// ---------------------------------------------------------------
// Lançamentos da conta aberta
// ---------------------------------------------------------------

class _EntriesSection extends ConsumerWidget {
  const _EntriesSection({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(billEntriesProvider(bill.id));
    final isSettled = bill.status == BillStatus.settled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Lançamentos',
          subtitle: isSettled
              ? 'Conta fechada — reabra para lançar mais'
              : 'Cada vez que gastar, lance aqui',
          icon: Icons.playlist_add_rounded,
          trailing: isSettled
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => showEntryForm(context, bill: bill),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Lançar'),
                ),
        ),
        entriesAsync.when(
          loading: () => const ShimmerList(itemCount: 2, itemHeight: 72),
          error: (e, _) => ErrorView(message: 'Erro ao carregar', details: '$e'),
          data: (entries) => entries.isEmpty
              ? GlassCard(
                  child: Column(
                    children: [
                      Text('🛣️', style: context.text.displaySmall),
                      Gap.vSm,
                      Text('Nenhum lançamento ainda', style: context.text.titleSmall),
                      Gap.vXs,
                      Text(
                        'Toque em "Lançar" cada vez que gastar. '
                        'No final, o app divide o total.',
                        style: context.text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: _EntryTile(bill: bill, entry: entries[i])
                            .animate()
                            .fadeIn(delay: (40 * i).ms, duration: Motion.fast),
                      ),
                  ],
                ),
        ),
        Gap.vLg,
        _AccumulatingFooter(bill: bill),
      ],
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.bill, required this.entry});

  final Bill bill;
  final BillEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      onTap: bill.status == BillStatus.settled
          ? null
          : () => showEntryForm(context, bill: bill, entry: entry),
      child: _EntryTileBody(bill: bill, entry: entry, ref: ref),
    );
  }
}

/// O corpo do lançamento.
///
/// No celular, ícone + descrição + comprovante + valor + excluir na mesma
/// linha deixavam ~40px para a descrição, que quebrava em cinco linhas de
/// duas letras. Em tela estreita as ações descem para uma segunda linha.
class _EntryTileBody extends StatelessWidget {
  const _EntryTileBody({required this.bill, required this.entry, required this.ref});

  final Bill bill;
  final BillEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final receipt = entry.receipts.isEmpty
        ? null
        : IconButton(
            tooltip: 'Comprovante',
            onPressed: () => openAttachment(context, entry.receipts.first),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
          );

    final delete = bill.status == BillStatus.settled
        ? null
        : IconButton(
            tooltip: 'Excluir lançamento',
            onPressed: () => ref
                .read(billRepositoryProvider)
                .deleteEntry(ref.read(currentTripIdProvider), entry),
            icon: const Icon(Icons.close_rounded, size: 16),
          );

    final amount = Text(
      Money.format(entry.amountCents),
      style: AppTypography.money(size: 16, color: context.colors.onSurface),
    );

    final icon = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bill.category.color.withValues(alpha: 0.12),
        borderRadius: Radii.brSm,
      ),
      child: Icon(bill.category.icon, size: 18, color: bill.category.color),
    );

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.description,
          style: context.text.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(Fmt.dateWithYear(entry.date), style: context.text.bodySmall),
      ],
    );

    if (!context.isNarrow) {
      return Row(
        children: [
          icon,
          Gap.hMd,
          Expanded(child: label),
          if (receipt != null) Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: receipt,
          ),
          amount,
          ?delete,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            icon,
            Gap.hMd,
            Expanded(child: label),
            Gap.hSm,
            amount,
          ],
        ),
        if (receipt != null || delete != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [?receipt, ?delete],
          ),
      ],
    );
  }
}

/// Total acumulado + ação de fechar/reabrir a conta.
class _AccumulatingFooter extends ConsumerWidget {
  const _AccumulatingFooter({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSettled = bill.status == BillStatus.settled;
    final perPerson = bill.participantIds.isEmpty
        ? 0
        : Money.divide(bill.entriesTotalCents, bill.participantIds.length).first;

    return GlassCard(
      accent: AppColors.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Total acumulado', style: context.text.titleMedium)),
              Text(
                Money.format(bill.entriesTotalCents),
                style: AppTypography.money(size: 22, color: context.colors.onSurface),
              ),
            ],
          ),
          if (bill.participantIds.isNotEmpty) ...[
            Gap.vXs,
            Text(
              'Daria ${Money.format(perPerson)} para cada uma das '
              '${bill.participantIds.length} pessoas',
              style: context.text.bodySmall,
            ),
          ],
          Gap.vLg,
          if (isSettled)
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(billRepositoryProvider)
                  .reopenBill(ref.read(currentTripIdProvider), bill.id),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text('Reabrir para lançar mais'),
            )
          else
            FilledButton.icon(
              onPressed: bill.entriesTotalCents <= 0
                  ? null
                  : () => _close(context, ref),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Fechar e dividir'),
            ),
        ],
      ),
    );
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fechar a conta?'),
        content: Text(
          'O total de ${Money.format(bill.entriesTotalCents)} será dividido entre '
          '${bill.participantIds.length} pessoas e as cotas serão geradas. '
          'Você pode reabrir depois se precisar lançar mais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fechar e dividir'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    await ref
        .read(billRepositoryProvider)
        .closeAccumulatingBill(ref.read(currentTripIdProvider), bill);
    if (context.mounted) {
      context.showSnack('Conta fechada e dividida!', icon: Icons.celebration_rounded);
    }
  }
}
