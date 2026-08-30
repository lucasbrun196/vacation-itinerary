import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/attachment.dart';
import '../../../data/models/bill.dart';
import '../../../data/models/bill_entry.dart';
import '../../../data/services/file_picker_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../shared/widgets/inputs/money_field.dart';
import '../../../shared/widgets/layout/app_sheet.dart';
import '../../../shared/widgets/media/attachment_tile.dart';

Future<void> showEntryForm(
  BuildContext context, {
  required Bill bill,
  BillEntry? entry,
}) =>
    showAppSheet(
      context: context,
      title: entry == null ? 'Novo lançamento' : 'Editar lançamento',
      subtitle: bill.title,
      builder: (_) => EntryFormSheet(bill: bill, entry: entry),
    );

class EntryFormSheet extends ConsumerStatefulWidget {
  const EntryFormSheet({super.key, required this.bill, this.entry});

  final Bill bill;
  final BillEntry? entry;

  @override
  ConsumerState<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<EntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _date;
  List<Attachment> _receipts = [];
  bool _saving = false;
  bool _uploading = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _date = entry?.date ?? DateTime.now();
    if (entry != null) {
      _descriptionController.text = entry.description;
      _notesController.text = entry.notes ?? '';
      _receipts = [...entry.receipts];
      MoneyField.setCents(_amountController, entry.amountCents);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipts() async {
    final files = await const FilePickerService().pickReceipts();
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadProgress = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final tripId = ref.read(currentTripIdProvider);
      for (final file in files) {
        final attachment = await storage.upload(
          folder: StoragePaths.receipts(tripId, widget.bill.id),
          file: file,
          uploadedBy: ref.read(currentUidProvider),
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        setState(() => _receipts = [..._receipts, attachment]);
      }
    } catch (e) {
      if (mounted) context.showSnack('Falha no envio: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(billRepositoryProvider).saveEntry(
            ref.read(currentTripIdProvider),
            BillEntry(
              id: widget.entry?.id ?? '',
              billId: widget.bill.id,
              description: _descriptionController.text.trim(),
              amountCents: Money.parse(_amountController.text) ?? 0,
              date: _date,
              paidByMemberId: widget.bill.paidByMemberId,
              receipts: _receipts,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              createdAt: widget.entry?.createdAt,
            ),
          );

      if (mounted) {
        Navigator.of(context).pop();
        context.showSnack('Lançamento salvo!', icon: Icons.check_circle_rounded);
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
                  MoneyField(
                    controller: _amountController,
                    label: 'Valor',
                    big: true,
                    autofocus: true,
                    validator: (_) =>
                        (Money.parse(_amountController.text) ?? 0) <= 0 ? 'Informe o valor' : null,
                  ),
                  Gap.vLg,
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      hintText: widget.bill.category.name == 'fuel'
                          ? 'Posto Shell, BR-101'
                          : 'O que foi',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Descreva o lançamento' : null,
                  ),
                  Gap.vLg,
                  InkWell(
                    borderRadius: Radii.brMd,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 2),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        prefixIcon: Icon(Icons.event_rounded, size: 20),
                      ),
                      child: Text(Fmt.dateWithYear(_date), style: context.text.bodyMedium),
                    ),
                  ),
                  Gap.vLg,
                  TextFormField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Opcional',
                    ),
                  ),
                  Gap.vXl,
                  Text('Comprovante', style: context.text.labelLarge),
                  Text('Foto da nota ou PDF', style: context.text.bodySmall),
                  Gap.vMd,
                  AttachmentStrip(
                    attachments: _receipts,
                    onAdd: _pickReceipts,
                    uploading: _uploading,
                    progress: _uploadProgress,
                    onDelete: (a) => setState(
                      () => _receipts = _receipts.where((r) => r.id != a.id).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SheetActions(
          primaryLabel: 'Salvar',
          onPrimary: _save,
          secondaryLabel: 'Cancelar',
          onSecondary: () => Navigator.of(context).pop(),
          isLoading: _saving,
        ),
      ],
    );
  }
}
