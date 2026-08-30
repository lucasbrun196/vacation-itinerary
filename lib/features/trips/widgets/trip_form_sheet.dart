import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/trip.dart';
import '../../../shared/widgets/inputs/money_field.dart';
import '../../../shared/widgets/layout/app_sheet.dart';

Future<String?> showTripForm(BuildContext context, {Trip? trip}) => showAppSheet<String>(
      context: context,
      title: trip == null ? 'Nova viagem' : 'Editar viagem',
      subtitle: trip == null
          ? 'Você vira o admin e pode convidar a turma depois'
          : trip.name,
      builder: (_) => TripFormSheet(trip: trip),
    );

class TripFormSheet extends ConsumerStatefulWidget {
  const TripFormSheet({super.key, this.trip});

  final Trip? trip;

  @override
  ConsumerState<TripFormSheet> createState() => _TripFormSheetState();
}

class _TripFormSheetState extends ConsumerState<TripFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTimeRange? _dates;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    if (trip != null) {
      _nameController.text = trip.name;
      _destinationController.text = trip.destination;
      MoneyField.setCents(_budgetController, trip.budgetCents);
      if (trip.hasDates) {
        _dates = DateTimeRange(start: trip.startDate!, end: trip.endDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dates,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('pt', 'BR'),
      helpText: 'Quando é a viagem?',
      saveText: 'Pronto',
    );
    if (picked != null) setState(() => _dates = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // Espera o perfil terminar de carregar em vez de assumir que já
      // está em memória — no primeiro acesso ele ainda está a caminho.
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw StateError('Sessão não encontrada. Entre de novo.');

      final repo = ref.read(tripRepositoryProvider);

      if (widget.trip == null) {
        final id = await repo.createTrip(
          creator: user,
          name: _nameController.text,
          destination: _destinationController.text,
          startDate: _dates?.start,
          endDate: _dates?.end,
          budgetCents: Money.parse(_budgetController.text),
        );
        if (mounted) {
          Navigator.of(context).pop(id);
          context.showSnack('Viagem criada!', icon: Icons.celebration_rounded);
        }
      } else {
        await repo.updateTrip(
          widget.trip!.copyWith(
            name: _nameController.text.trim(),
            destination: _destinationController.text.trim(),
            startDate: _dates?.start,
            endDate: _dates?.end,
            budgetCents: Money.parse(_budgetController.text),
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(widget.trip!.id);
          context.showSnack('Viagem atualizada');
        }
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
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome da viagem',
                      hintText: 'Verão na ilha',
                      prefixIcon: Icon(Icons.luggage_rounded, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Dê um nome para a viagem' : null,
                  ),
                  Gap.vLg,
                  TextFormField(
                    controller: _destinationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      hintText: 'Florianópolis, SC',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                  Gap.vLg,
                  InkWell(
                    borderRadius: Radii.brMd,
                    onTap: _pickDates,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Datas',
                        prefixIcon: Icon(Icons.date_range_rounded, size: 20),
                      ),
                      child: Text(
                        _dates == null
                            ? 'Escolher ida e volta'
                            : '${Fmt.dateShort(_dates!.start)} — ${Fmt.dateWithYear(_dates!.end)}',
                        style: _dates == null
                            ? context.text.bodyMedium
                                ?.copyWith(color: context.colors.onSurfaceVariant)
                            : context.text.bodyMedium,
                      ),
                    ),
                  ),
                  Gap.vLg,
                  MoneyField(
                    controller: _budgetController,
                    label: 'Orçamento previsto',
                    helper: 'Opcional — serve de referência no painel',
                  ),
                ],
              ),
            ),
          ),
        ),
        SheetActions(
          primaryLabel: widget.trip == null ? 'Criar viagem' : 'Salvar',
          onPrimary: _save,
          secondaryLabel: 'Cancelar',
          onSecondary: () => Navigator.of(context).pop(),
          isLoading: _saving,
        ),
      ],
    );
  }
}
