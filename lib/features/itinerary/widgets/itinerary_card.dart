import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/itinerary_enums.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../shared/widgets/cards/glass_card.dart';
import 'itinerary_chip.dart';
import 'itinerary_form_sheet.dart';
import 'weather_chip.dart';

/// Uma parada na linha do tempo: marcador do horário à esquerda, o
/// conteúdo à direita.
class ItineraryCard extends ConsumerWidget {
  const ItineraryCard({super.key, required this.item, this.isLast = false});

  final ItineraryItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = item.status == ItineraryStatus.done;
    final cancelled = item.status == ItineraryStatus.cancelled;
    final accent = cancelled ? AppColors.inkFaint : item.category.color;

    final bill = item.isLinkedToBill
        ? (ref.watch(billsProvider).valueOrNull ?? const <Bill>[])
            .where((b) => b.id == item.billId)
            .firstOrNull
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Timeline(item: item, accent: accent, isLast: isLast, done: done),
          Gap.hMd,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Gap.md),
              child: GlassCard(
                accent: accent,
                onTap: () => showItineraryForm(context, item: item),
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: context.text.titleMedium?.copyWith(
                              decoration: cancelled ? TextDecoration.lineThrough : null,
                              color: cancelled ? AppColors.inkFaint : null,
                            ),
                          ),
                        ),
                        _StatusButton(item: item),
                      ],
                    ),
                    if (item.placeName != null || item.address != null) ...[
                      Gap.vXs,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pin cheio quando o lugar está fixado no mapa.
                          Icon(
                            item.hasCoords ? Icons.place_rounded : Icons.place_outlined,
                            size: 13,
                            color: item.hasCoords
                                ? AppColors.sky
                                : context.colors.onSurfaceVariant,
                          ),
                          Gap.hXs,
                          Expanded(
                            child: Text(
                              [item.placeName, item.address]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(' · '),
                              style: context.text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Gap.vSm,
                    Wrap(
                      spacing: Gap.xs,
                      runSpacing: Gap.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ItineraryChip(
                          label: item.category.label,
                          icon: item.category.icon,
                          color: accent,
                        ),
                        if (item.transport != null)
                          ItineraryChip(
                            label: item.transport!.label,
                            icon: item.transport!.icon,
                            color: AppColors.sky,
                          ),
                        // Só entra na lista quando há coordenada: o chip
                        // se esconde sozinho, mas um widget vazio ainda
                        // ocuparia o `spacing` do Wrap.
                        if (item.hasCoords) WeatherChip(item: item),
                        if (bill != null)
                          ItineraryChip(
                            label: '${bill.title} · '
                                '${Money.formatCompact(bill.chargedTotalCents)}',
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.sunset,
                          ),
                        if (item.link != null && item.link!.isNotEmpty)
                          _LinkChip(url: item.link!),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      Gap.vSm,
                      Text(
                        item.notes!,
                        style: context.text.bodySmall?.copyWith(color: AppColors.inkFaint),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coluna do horário com a linha vertical ligando as paradas.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.item,
    required this.accent,
    required this.isLast,
    required this.done,
  });

  final ItineraryItem item;
  final Color accent;
  final bool isLast;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: Center(
              child: item.hasTime
                  ? Text(
                      Fmt.time(item.startAt!),
                      style: context.text.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.inkFaint),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: done ? accent : context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2.4),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 8, color: Colors.white)
                : null,
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: context.colors.outline,
              ),
            ),
        ],
      ),
    );
  }
}

/// Marca como feita, cancela ou apaga a atividade.
class _StatusButton extends ConsumerWidget {
  const _StatusButton({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = item.status == ItineraryStatus.done;

    return PopupMenuButton<String>(
      tooltip: 'Opções',
      icon: Icon(
        done ? Icons.check_circle_rounded : Icons.more_vert_rounded,
        size: 18,
        color: done ? AppColors.success : context.colors.onSurfaceVariant,
      ),
      shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
      onSelected: (value) async {
        final repo = ref.read(itineraryRepositoryProvider);
        final tripId = ref.read(currentTripIdProvider);

        switch (value) {
          case 'feito':
            await repo.setStatus(tripId, item.id, ItineraryStatus.done.name);
          case 'planejado':
            await repo.setStatus(tripId, item.id, ItineraryStatus.planned.name);
          case 'cancelado':
            await repo.setStatus(tripId, item.id, ItineraryStatus.cancelled.name);
          case 'editar':
            if (context.mounted) await showItineraryForm(context, item: item);
          case 'excluir':
            if (context.mounted) await _confirmDelete(context, ref);
        }
      },
      itemBuilder: (context) => [
        if (!done)
          const PopupMenuItem(
            value: 'feito',
            child: _MenuRow(icon: Icons.check_circle_outline_rounded, label: 'Marcar como feito'),
          )
        else
          const PopupMenuItem(
            value: 'planejado',
            child: _MenuRow(icon: Icons.undo_rounded, label: 'Voltar para planejado'),
          ),
        const PopupMenuItem(
          value: 'editar',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Editar'),
        ),
        if (item.status != ItineraryStatus.cancelled)
          const PopupMenuItem(
            value: 'cancelado',
            child: _MenuRow(icon: Icons.block_rounded, label: 'Cancelar atividade'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'excluir',
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Excluir',
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir atividade?'),
        content: Text('"${item.title}" sai do roteiro. A conta ligada a ela, se houver, '
            'continua em Gastos.'),
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
    if (ok != true) return;

    await ref
        .read(itineraryRepositoryProvider)
        .deleteItem(ref.read(currentTripIdProvider), item.id);
    if (context.mounted) context.showSnack('Atividade excluída');
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        Gap.hMd,
        Text(label, style: context.text.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: Radii.brPill,
      onTap: () async {
        final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
        if (uri == null) return;
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          context.showSnack('Não deu para abrir o link', isError: true);
        }
      },
      child: const ItineraryChip(
        label: 'Abrir link',
        icon: Icons.open_in_new_rounded,
        color: AppColors.grape,
      ),
    );
  }
}
