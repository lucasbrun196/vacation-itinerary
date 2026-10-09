import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// Abre o calendário de ida e volta num diálogo. Devolve `null` se a
/// pessoa cancelar.
///
/// Só deixa escolher de hoje em diante: viagem se planeja para a frente.
/// Uma viagem já em andamento, ao ser editada, mostra as datas que tinha;
/// só não dá para escolher um dia anterior a hoje.
///
/// Usa `showDialog` direto, e não `showAppSheet`, porque não lê provider
/// nenhum: recebe datas e devolve datas.
Future<DateTimeRange?> showTripDatesDialog(
  BuildContext context, {
  DateTimeRange? initial,
  String title = 'Quando é a viagem?',
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _DateRangeDialog(initial: initial, title: title),
  );
}

class _DateRangeDialog extends StatefulWidget {
  const _DateRangeDialog({required this.initial, required this.title});

  final DateTimeRange? initial;
  final String title;

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  late final DateTime _today = DateTime.now().dateOnly;
  late final DateTime _lastDay = DateTime(_today.year + 5, 12, 31);

  DateTime? _start;
  DateTime? _end;
  late DateTime _month;

  /// Direção da última troca de mês, para o deslize ir para o lado certo.
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start.dateOnly;
    _end = widget.initial?.end.dateOnly;
    final anchor = _start != null && !_start!.isBefore(_today) ? _start! : _today;
    _month = DateTime(anchor.year, anchor.month);
  }

  bool get _canGoBack => _month.isAfter(DateTime(_today.year, _today.month));
  bool get _canGoForward => _month.isBefore(DateTime(_lastDay.year, _lastDay.month));

  void _shiftMonth(int delta) => setState(() {
        _direction = delta;
        _month = DateTime(_month.year, _month.month + delta);
      });

  void _tap(DateTime day) => setState(() {
        if (_start == null || _end != null || day.isBefore(_start!)) {
          // Começa uma seleção nova: primeiro toque, seleção já completa,
          // ou um dia antes da ida (vira a nova ida).
          _start = day;
          _end = null;
        } else {
          _end = day;
        }
      });

  @override
  Widget build(BuildContext context) {
    final nights = _start != null && _end != null ? _end!.difference(_start!).inDays : null;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(Gap.lg),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.brXl,
        side: BorderSide(color: context.colors.outline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: widget.title, start: _start, end: _end, nights: nights),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
              child: _MonthBar(
                month: _month,
                onPrev: _canGoBack ? () => _shiftMonth(-1) : null,
                onNext: _canGoForward ? () => _shiftMonth(1) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: AnimatedSwitcher(
                duration: Motion.normal,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(_month);
                  final dx = (incoming ? 0.15 : -0.15) * _direction;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(
                        CurvedAnimation(parent: animation, curve: Motion.enter),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _MonthGrid(
                  key: ValueKey(_month),
                  month: _month,
                  today: _today,
                  lastDay: _lastDay,
                  start: _start,
                  end: _end,
                  onTap: _tap,
                ),
              ),
            ),
            _Footer(
              canClear: _start != null,
              canConfirm: _start != null,
              onClear: () => setState(() {
                _start = null;
                _end = null;
              }),
              onConfirm: () => Navigator.of(context).pop(
                // Só a ida marcada: viagem de um dia.
                DateTimeRange(start: _start!, end: _end ?? _start!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título e o resumo da escolha: ida, volta e quantas noites.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.start, this.end, this.nights});

  final String title;
  final DateTime? start;
  final DateTime? end;
  final int? nights;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF3A2220), Color(0xFF2E2219)]
              : const [AppColors.coralSoft, AppColors.sunsetSoft],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          Gap.vMd,
          Row(
            children: [
              Expanded(child: _DateSlot(label: 'Ida', date: start, active: end == null)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: context.colors.primary),
              ),
              Expanded(child: _DateSlot(label: 'Volta', date: end, active: start != null && end == null)),
            ],
          ),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.enter,
            child: nights == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Gap.sm),
                    child: Text(
                      nights == 0
                          ? 'Bate e volta, no mesmo dia'
                          : '$nights ${nights == 1 ? "noite" : "noites"} · ${nights! + 1} dias',
                      style: context.text.labelMedium?.copyWith(color: context.colors.primary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateSlot extends StatelessWidget {
  const _DateSlot({required this.label, required this.date, required this.active});

  final String label;
  final DateTime? date;

  /// É o próximo toque que vai preencher este campo.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = date == null ? '—' : DateFormat("d 'de' MMM", 'pt_BR').format(date!).replaceAll('.', '');

    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.enter,
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brMd,
        border: Border.all(
          color: active ? colors.primary : colors.outline,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall),
          AnimatedSwitcher(
            duration: Motion.normal,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(
                color: date == null ? colors.onSurfaceVariant : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, this.onPrev, this.onNext});

  final DateTime month;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat("MMMM 'de' y", 'pt_BR').format(month);

    return Row(
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// A grade do mês: cabeçalho dos dias da semana e seis linhas de dias.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.lastDay,
    required this.start,
    required this.end,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final DateTime lastDay;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onTap;

  static const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    // Domingo primeiro, como no calendário brasileiro: `weekday % 7` leva
    // domingo (7) para a coluna 0.
    final offset = DateTime(month.year, month.month).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dayNumber = week * 7 + col - offset + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(height: 44);
                      }
                      final day = DateTime(month.year, month.month, dayNumber);
                      return _DayCell(
                        day: day,
                        today: today,
                        enabled: !day.isBefore(today) && !day.isAfter(lastDay),
                        start: start,
                        end: end,
                        onTap: onTap,
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.enabled,
    required this.start,
    required this.end,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final bool enabled;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final day = widget.day;
    final start = widget.start;
    final end = widget.end;

    final isStart = start != null && day.isSameDay(start);
    final isEnd = end != null && day.isSameDay(end);
    final isEdge = isStart || isEnd;
    final inRange = start != null && end != null && day.isAfter(start) && day.isBefore(end);
    final isToday = day.isSameDay(widget.today);

    // A faixa entre ida e volta: ocupa a célula inteira no meio e só a
    // metade de dentro nas pontas, para ligar os dois círculos.
    final bandColor = colors.primaryContainer;
    final hasRange = start != null && end != null && !start.isSameDay(end);
    final Widget band = !hasRange || !(inRange || isEdge)
        ? const SizedBox.shrink()
        : Row(
            children: [
              Expanded(child: ColoredBox(color: isStart ? Colors.transparent : bandColor)),
              Expanded(child: ColoredBox(color: isEnd ? Colors.transparent : bandColor)),
            ],
          );

    final textColor = !widget.enabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.35)
        : isEdge
            ? colors.onPrimary
            : inRange
                ? colors.primary
                : colors.onSurface;

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? () => widget.onTap(day) : null,
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(top: 4, bottom: 4, child: band),
              AnimatedContainer(
                duration: Motion.normal,
                curve: Motion.enter,
                width: isEdge ? 38 : 36,
                height: isEdge ? 38 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isEdge ? AppColors.sunsetGradient : null,
                  color: isEdge
                      ? null
                      : _hovered && widget.enabled && !inRange
                          ? colors.surfaceContainerHigh
                          : Colors.transparent,
                  border: isToday && !isEdge ? Border.all(color: colors.primary, width: 1.5) : null,
                  boxShadow: isEdge ? AppColors.glow(AppColors.coral, opacity: 0.35, blur: 10, y: 3) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: AppTypography.mono(
                    size: 13,
                    weight: isEdge || isToday ? FontWeight.w700 : FontWeight.w400,
                    color: textColor,
                  ).copyWith(
                    decoration: widget.enabled ? null : TextDecoration.lineThrough,
                    decorationColor: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canClear,
    required this.canConfirm,
    required this.onClear,
    required this.onConfirm,
  });

  final bool canClear;
  final bool canConfirm;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Limpar',
            onPressed: canClear ? onClear : null,
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
          ),
          const Spacer(),
          Flexible(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            ),
          ),
          Gap.hSm,
          Flexible(
            child: FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              child: const Text('Confirmar', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
