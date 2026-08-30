import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/itinerary_enums.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../shared/widgets/layout/app_sheet.dart';

Future<void> showItineraryForm(
  BuildContext context, {
  ItineraryItem? item,
  DateTime? suggestedDate,
}) =>
    showAppSheet(
      context: context,
      title: item == null ? 'Nova atividade' : 'Editar atividade',
      subtitle: item == null
          ? 'O que a turma vai fazer, onde e como chega lá'
          : item.title,
      builder: (_) => ItineraryFormSheet(item: item, suggestedDate: suggestedDate),
    );

class ItineraryFormSheet extends ConsumerStatefulWidget {
  const ItineraryFormSheet({super.key, this.item, this.suggestedDate});

  final ItineraryItem? item;

  /// Dia já escolhido quando o usuário adiciona a partir de um dia
  /// específico da timeline.
  final DateTime? suggestedDate;

  @override
  ConsumerState<ItineraryFormSheet> createState() => _ItineraryFormSheetState();
}

class _ItineraryFormSheetState extends ConsumerState<ItineraryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _linkController = TextEditingController();

  late DateTime _date;
  late ItineraryCategory _category;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TransportMode? _transport;
  String? _billId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _date = item?.date ?? widget.suggestedDate ?? _defaultDate();
    _category = item?.category ?? ItineraryCategory.other;
    _transport = item?.transport;
    _billId = item?.billId;

    if (item != null) {
      _titleController.text = item.title;
      _placeController.text = item.placeName ?? '';
      _addressController.text = item.address ?? '';
      _notesController.text = item.notes ?? '';
      _linkController.text = item.link ?? '';
      if (item.startAt != null) _startTime = TimeOfDay.fromDateTime(item.startAt!);
      if (item.endAt != null) _endTime = TimeOfDay.fromDateTime(item.endAt!);
    }
  }

  /// Começa no primeiro dia da viagem — é onde a pessoa quer cadastrar
  /// na maior parte das vezes.
  DateTime _defaultDate() {
    final trip = ref.read(tripProvider).valueOrNull;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = trip?.startDate;
    if (start == null) return today;
    final startDay = DateTime(start.year, start.month, start.day);
    return startDay.isAfter(today) ? startDay : today;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  DateTime? get _startAt => _startTime == null
      ? null
      : DateTime(_date.year, _date.month, _date.day, _startTime!.hour, _startTime!.minute);

  DateTime? get _endAt => _endTime == null
      ? null
      : DateTime(_date.year, _date.month, _date.day, _endTime!.hour, _endTime!.minute);

  String? _trimmed(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickDate() async {
    final trip = ref.read(tripProvider).valueOrNull;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: trip?.startDate ?? DateTime(_date.year - 1),
      lastDate: trip?.endDate ?? DateTime(_date.year + 2),
      locale: const Locale('pt', 'BR'),
      helpText: 'Que dia é a atividade?',
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
      helpText: isStart ? 'Começa que horas?' : 'Termina que horas?',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final existing = widget.item;
      final item = ItineraryItem(
        id: existing?.id ?? '',
        title: _titleController.text.trim(),
        date: _date,
        category: _category,
        startAt: _startAt,
        endAt: _endAt,
        placeName: _trimmed(_placeController),
        address: _trimmed(_addressController),
        transport: _transport,
        billId: _billId,
        notes: _trimmed(_notesController),
        link: _trimmed(_linkController),
        status: existing?.status ?? ItineraryStatus.planned,
        order: existing?.order ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        createdBy: existing?.createdBy ?? ref.read(currentUidProvider),
        createdAt: existing?.createdAt,
      );

      await ref
          .read(itineraryRepositoryProvider)
          .saveItem(ref.read(currentTripIdProvider), item);

      if (mounted) {
        Navigator.of(context).pop();
        context.showSnack(
          existing == null ? 'Atividade adicionada!' : 'Atividade atualizada',
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showSnack('Não deu para salvar: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'O que vamos fazer',
                      hintText: 'Trilha da Lagoinha do Leste',
                      prefixIcon: Icon(Icons.flag_outlined, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Diga o que é a atividade' : null,
                  ),
                  Gap.vLg,

                  Text('Categoria', style: context.text.labelLarge),
                  Gap.vSm,
                  _CategoryPicker(
                    value: _category,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                  Gap.vXl,

                  // ----- Quando -----
                  Text('Quando', style: context.text.labelLarge),
                  Gap.vMd,
                  InkWell(
                    borderRadius: Radii.brMd,
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Dia',
                        prefixIcon: Icon(Icons.event_rounded, size: 20),
                      ),
                      child: Text(Fmt.dateFull(_date), style: context.text.bodyMedium),
                    ),
                  ),
                  Gap.vMd,
                  _TimeRow(
                    startTime: _startTime,
                    endTime: _endTime,
                    onPickStart: () => _pickTime(isStart: true),
                    onPickEnd: () => _pickTime(isStart: false),
                    onClear: () => setState(() {
                      _startTime = null;
                      _endTime = null;
                    }),
                  ),
                  Gap.vXl,

                  // ----- Onde -----
                  Text('Onde', style: context.text.labelLarge),
                  Gap.vMd,
                  TextFormField(
                    controller: _placeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      hintText: 'Pântano do Sul',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                  Gap.vMd,
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      hintText: 'Opcional — rua, referência, ponto de encontro',
                      prefixIcon: Icon(Icons.signpost_outlined, size: 20),
                    ),
                  ),
                  Gap.vXl,

                  // ----- Como chega -----
                  Row(
                    children: [
                      Expanded(child: Text('Como vamos', style: context.text.labelLarge)),
                      if (_transport != null)
                        TextButton(
                          onPressed: () => setState(() => _transport = null),
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                  Gap.vSm,
                  _TransportPicker(
                    value: _transport,
                    onChanged: (t) => setState(
                      () => _transport = _transport == t ? null : t,
                    ),
                  ),
                  Gap.vXl,

                  // ----- Conta vinculada -----
                  Text('Conta relacionada', style: context.text.labelLarge),
                  Text(
                    'Ligue a uma conta para o gasto entrar nas estatísticas do roteiro',
                    style: context.text.bodySmall,
                  ),
                  Gap.vMd,
                  _BillPicker(
                    bills: bills,
                    selectedId: _billId,
                    onChanged: (id) => setState(() => _billId = _billId == id ? null : id),
                  ),
                  Gap.vXl,

                  TextFormField(
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Link',
                      hintText: 'Opcional — reserva, mapa, site',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                  ),
                  Gap.vLg,
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Opcional — levar protetor, chegar cedo...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SheetActions(
          primaryLabel: widget.item == null ? 'Adicionar' : 'Salvar',
          onPrimary: _save,
          secondaryLabel: 'Cancelar',
          onSecondary: () => Navigator.of(context).pop(),
          isLoading: _saving,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final ItineraryCategory value;
  final ValueChanged<ItineraryCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final category in ItineraryCategory.values)
          InkWell(
            borderRadius: Radii.brPill,
            onTap: () => onChanged(category),
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
              decoration: BoxDecoration(
                color: value == category
                    ? category.color.withValues(alpha: 0.16)
                    : context.colors.surfaceContainerHigh,
                borderRadius: Radii.brPill,
                border: Border.all(
                  color: value == category ? category.color : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 15,
                    color: value == category ? category.color : context.colors.onSurfaceVariant,
                  ),
                  Gap.hXs,
                  Text(
                    category.label,
                    style: context.text.labelMedium?.copyWith(
                      color:
                          value == category ? category.color : context.colors.onSurfaceVariant,
                      fontWeight: value == category ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TransportPicker extends StatelessWidget {
  const _TransportPicker({required this.value, required this.onChanged});

  final TransportMode? value;
  final ValueChanged<TransportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final mode in TransportMode.values)
          InkWell(
            borderRadius: Radii.brPill,
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
              decoration: BoxDecoration(
                color: value == mode
                    ? AppColors.sky.withValues(alpha: 0.16)
                    : context.colors.surfaceContainerHigh,
                borderRadius: Radii.brPill,
                border: Border.all(
                  color: value == mode ? AppColors.sky : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode.icon,
                    size: 15,
                    color: value == mode ? AppColors.sky : context.colors.onSurfaceVariant,
                  ),
                  Gap.hXs,
                  Text(
                    mode.label,
                    style: context.text.labelMedium?.copyWith(
                      color: value == mode ? AppColors.sky : context.colors.onSurfaceVariant,
                      fontWeight: value == mode ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Horário é opcional: enquanto ninguém define, a atividade é "algum
/// momento do dia" e vai para o fim da lista daquele dia.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.startTime,
    required this.endTime,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
  });

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (startTime == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onPickStart,
            icon: const Icon(Icons.schedule_rounded, size: 18),
            label: const Text('Definir horário'),
          ),
          Gap.vSm,
          Text(
            'Sem horário, a atividade fica como "algum momento do dia" '
            'e aparece no fim daquele dia.',
            style: context.text.labelSmall,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: Radii.brMd,
            onTap: onPickStart,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Começa',
                prefixIcon: Icon(Icons.schedule_rounded, size: 20),
              ),
              child: Text(startTime!.format(context), style: context.text.bodyMedium),
            ),
          ),
        ),
        Gap.hMd,
        Expanded(
          child: InkWell(
            borderRadius: Radii.brMd,
            onTap: onPickEnd,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Termina'),
              child: Text(
                endTime?.format(context) ?? 'opcional',
                style: endTime == null
                    ? context.text.bodyMedium?.copyWith(color: AppColors.inkFaint)
                    : context.text.bodyMedium,
              ),
            ),
          ),
        ),
        Gap.hXs,
        IconButton(
          tooltip: 'Tirar horário',
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _BillPicker extends StatelessWidget {
  const _BillPicker({
    required this.bills,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Bill> bills;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: Radii.brMd,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: context.colors.onSurfaceVariant),
            Gap.hMd,
            Expanded(
              child: Text(
                'Nenhuma conta cadastrada ainda. Crie em Gastos e volte aqui para ligar.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final bill in bills)
          InkWell(
            borderRadius: Radii.brPill,
            onTap: () => onChanged(bill.id),
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
              decoration: BoxDecoration(
                color: selectedId == bill.id
                    ? bill.category.color.withValues(alpha: 0.16)
                    : context.colors.surfaceContainerHigh,
                borderRadius: Radii.brPill,
                border: Border.all(
                  color: selectedId == bill.id ? bill.category.color : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(bill.category.icon, size: 15, color: bill.category.color),
                  Gap.hXs,
                  Text(
                    bill.title,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight:
                          selectedId == bill.id ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Gap.hSm,
                  Text(
                    Money.formatCompact(bill.chargedTotalCents),
                    style: context.text.labelSmall,
                  ),
                  if (selectedId == bill.id) ...[
                    Gap.hXs,
                    Icon(Icons.check_rounded, size: 14, color: bill.category.color),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
