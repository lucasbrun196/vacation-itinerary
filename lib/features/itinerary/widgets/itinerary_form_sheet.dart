import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/itinerary_enums.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../core/config/map_config.dart';
import '../../../shared/widgets/inputs/date_range_dialog.dart';
import '../../../shared/widgets/layout/app_sheet.dart';
import 'map_picker_sheet.dart';

Future<void> showItineraryForm(
  BuildContext context, {
  ItineraryItem? item,
  DateTime? suggestedDate,
}) =>
    showAppSheet(
      context: context,
      title: item == null ? 'Nova atividade' : 'Editar atividade',
      subtitle: item == null
          ? 'O que, onde, quando e como chegar'
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

  /// Contas ligadas, na ordem em que foram escolhidas — é a ordem em que
  /// os chips aparecem no card do roteiro.
  final _billIds = <String>[];

  /// A coordenada escolhida no mapa. Só existe no banco — a tela mostra
  /// o nome do lugar.
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _date = item?.date ?? widget.suggestedDate ?? _defaultDate();
    _category = item?.category ?? ItineraryCategory.other;
    _transport = item?.transport;
    _billIds.addAll(item?.billIds ?? const []);
    _lat = item?.lat;
    _lng = item?.lng;

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

  PickedPlace? get _pickedPlace => (_lat == null || _lng == null)
      ? null
      : PickedPlace(
          lat: _lat!,
          lng: _lng!,
          name: _placeController.text.trim().isEmpty
              ? 'Ponto escolhido no mapa'
              : _placeController.text.trim(),
          address: _trimmed(_addressController),
        );

  /// Soma das contas escolhidas, ignorando as que sumiram de Contas.
  int _selectedCents(List<Bill> bills) {
    final byId = {for (final b in bills) b.id: b};
    return _billIds.fold<int>(
      0,
      (sum, id) => sum + (byId[id]?.chargedTotalCents ?? 0),
    );
  }

  Future<void> _pickOnMap() async {
    final place = await showMapPicker(context, initial: _pickedPlace);
    if (!mounted || place == null) return;
    setState(() {
      _lat = place.lat;
      _lng = place.lng;
      _placeController.text = place.name;
      // Sempre sobrescreve: o endereço que estava aqui era do ponto
      // antigo, e manter o antigo ao lado de um ponto novo é pior do que
      // deixar o campo vazio para a pessoa preencher.
      _addressController.text = place.address ?? '';
    });
  }

  Future<void> _pickDate() async {
    final trip = ref.read(tripProvider).valueOrNull;
    final picked = await showAppDatePicker(
      context,
      initialDate: _date,
      firstDate: trip?.startDate ?? DateTime(_date.year - 1),
      lastDate: trip?.endDate ?? DateTime(_date.year + 2),
      title: 'Que dia é a atividade?',
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
        lat: _lat,
        lng: _lng,
        transport: _transport,
        billIds: List.of(_billIds),
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
                    borderRadius: Radii.brSm,
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
                  _MapField(
                    hasPoint: _lat != null,
                    placeName: _placeController.text,
                    onPick: _pickOnMap,
                    onClear: () => setState(() {
                      _lat = null;
                      _lng = null;
                    }),
                  ),
                  Gap.vMd,
                  TextFormField(
                    controller: _placeController,
                    textCapitalization: TextCapitalization.words,
                    // Mantém o nome do ponto marcado em dia com o campo.
                    onChanged: (_) => setState(() {}),
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

                  // ----- Contas vinculadas -----
                  Row(
                    children: [
                      Expanded(
                        child: Text('Contas relacionadas', style: context.text.labelLarge),
                      ),
                      if (_billIds.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(_billIds.clear),
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                  Text(
                    'Ligue quantas contas quiser — todas entram nas estatísticas '
                    'do roteiro',
                    style: context.text.bodySmall,
                  ),
                  Gap.vMd,
                  _BillPicker(
                    bills: bills,
                    selectedIds: _billIds,
                    onToggle: (id) => setState(() {
                      if (!_billIds.remove(id)) _billIds.add(id);
                    }),
                  ),
                  if (_billIds.length > 1) ...[
                    Gap.vSm,
                    Text(
                      '${_billIds.length} contas · '
                      '${Money.format(_selectedCents(bills))} no total',
                      style: context.text.labelSmall,
                    ),
                  ],
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

/// Atalho para o mapa. O ponto é o que a previsão do tempo vai usar; a
/// pessoa continua livre para digitar o lugar à mão nos campos abaixo.
class _MapField extends StatelessWidget {
  const _MapField({
    required this.hasPoint,
    required this.placeName,
    required this.onPick,
    required this.onClear,
  });

  final bool hasPoint;
  final String placeName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!MapConfig.isConfigured) {
      return Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: Radii.brSm,
        ),
        child: Row(
          children: [
            Icon(Icons.map_outlined, size: 16, color: context.colors.onSurfaceVariant),
            Gap.hMd,
            Expanded(
              child: Text(
                'O mapa precisa do token do Mapbox '
                '(--dart-define=MAPBOX_TOKEN). Veja o README.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (!hasPoint) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.map_outlined, size: 18),
        label: const Text('Escolher no mapa'),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.sm, Gap.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brSm,
        border: Border.all(color: context.colors.outline),
      ),
      child: _PickedPlaceRow(
        placeName: placeName,
        onPick: onPick,
        onClear: onClear,
      ),
    );
  }
}

/// O lugar já marcado, com as ações de trocar e tirar do mapa.
///
/// "Trocar" e o "×" comem ~130px: em tela estreita sobra tão pouco que o nome
/// do lugar aparece sempre truncado. Ali as ações descem para a linha de baixo.
class _PickedPlaceRow extends StatelessWidget {
  const _PickedPlaceRow({
    required this.placeName,
    required this.onPick,
    required this.onClear,
  });

  final String placeName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          placeName.trim().isEmpty ? 'Ponto marcado no mapa' : placeName.trim(),
          style: context.text.labelLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text('Marcado no mapa', style: context.text.labelSmall),
      ],
    );

    final swap = TextButton(onPressed: onPick, child: const Text('Trocar'));
    final clear = IconButton(
      tooltip: 'Tirar do mapa',
      onPressed: onClear,
      icon: const Icon(Icons.close_rounded, size: 18),
      visualDensity: VisualDensity.compact,
    );

    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: context.colors.onSurfaceVariant),
              Gap.hMd,
              Expanded(child: label),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [swap, clear],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.place_outlined, size: 18, color: context.colors.onSurfaceVariant),
        Gap.hMd,
        Expanded(child: label),
        swap,
        clear,
      ],
    );
  }
}

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
          ChoiceChip(
            label: Text(category.label),
            selected: value == category,
            onSelected: (_) => onChanged(category),
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
          ChoiceChip(
            label: Text(mode.label),
            selected: value == mode,
            onSelected: (_) => onChanged(mode),
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
            icon: const Icon(Icons.schedule, size: 18),
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

    final start = InkWell(
      borderRadius: Radii.brSm,
      onTap: onPickStart,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Começa',
          prefixIcon: Icon(Icons.schedule, size: 20),
        ),
        child: Text(
          startTime!.format(context),
          style: AppTypography.mono(size: 14, color: context.colors.onSurface),
        ),
      ),
    );

    final end = InkWell(
      borderRadius: Radii.brSm,
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
    );

    final clear = IconButton(
      tooltip: 'Tirar horário',
      onPressed: onClear,
      icon: const Icon(Icons.close_rounded, size: 18),
      visualDensity: VisualDensity.compact,
    );

    // Lado a lado em tela estreita sobram ~60px por campo — e o de início
    // ainda tem o ícone. O label flutuante não cabe. Empilhados, cada um usa
    // a largura toda.
    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          start,
          Gap.vSm,
          Row(
            children: [Expanded(child: end), Gap.hXs, clear],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: start),
        Gap.hMd,
        Expanded(child: end),
        Gap.hXs,
        clear,
      ],
    );
  }
}

class _BillPicker extends StatelessWidget {
  const _BillPicker({
    required this.bills,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<Bill> bills;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: Radii.brSm,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: context.colors.onSurfaceVariant),
            Gap.hMd,
            Expanded(
              child: Text(
                'Nenhuma conta cadastrada ainda. Crie em Contas e volte aqui para ligar.',
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
          _selectable(context, bill, selected: selectedIds.contains(bill.id)),
      ],
    );
  }

  /// Cada conta é um botão de liga/desliga: dá para marcar quantas forem.
  Widget _selectable(BuildContext context, Bill bill, {required bool selected}) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onToggle(bill.id),
      // Dentro de um `Wrap` o título da conta precisa poder encolher: sem
      // o limite, um nome longo estoura a linha.
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          '${bill.title} · ${Money.formatCompact(bill.chargedTotalCents)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
