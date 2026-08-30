import 'package:flutter_test/flutter_test.dart';
import 'package:vacation_itinerary/data/models/itinerary_enums.dart';
import 'package:vacation_itinerary/data/models/itinerary_item.dart';

ItineraryItem item(
  String title, {
  required DateTime date,
  int? hora,
  int order = 0,
  ItineraryStatus status = ItineraryStatus.planned,
  String? billId,
}) =>
    ItineraryItem(
      id: title,
      title: title,
      date: date,
      order: order,
      status: status,
      billId: billId,
      startAt: hora == null
          ? null
          : DateTime(date.year, date.month, date.day, hora),
    );

void main() {
  final dia1 = DateTime(2026, 1, 10);
  final dia2 = DateTime(2026, 1, 11);

  group('Ordenação dentro do dia', () {
    test('quem tem horário vem antes, na ordem do relógio', () {
      final itens = [
        item('almoço', date: dia1, hora: 12),
        item('café', date: dia1, hora: 8),
        item('jantar', date: dia1, hora: 20),
      ]..sort((a, b) => a.compareForDay(b));

      expect(itens.map((i) => i.title), ['café', 'almoço', 'jantar']);
    });

    test('sem horário vai para o fim, preservando a ordem de cadastro', () {
      final itens = [
        item('praia', date: dia1, order: 2),
        item('trilha', date: dia1, order: 1),
        item('jantar', date: dia1, hora: 20),
      ]..sort((a, b) => a.compareForDay(b));

      expect(itens.map((i) => i.title), ['jantar', 'trilha', 'praia']);
    });
  });

  group('Agrupamento por dia', () {
    test('a chave do dia ignora o horário', () {
      final manha = item('a', date: dia1, hora: 7);
      final noite = item('b', date: dia1, hora: 23);
      expect(manha.dayKey, noite.dayKey);
      expect(manha.dayKey, '2026-01-10');
    });

    test('dias diferentes geram chaves diferentes', () {
      expect(item('a', date: dia1).dayKey == item('b', date: dia2).dayKey, isFalse);
    });
  });

  group('Vínculo com conta', () {
    test('sem conta não conta como vinculada', () {
      expect(item('a', date: dia1).isLinkedToBill, isFalse);
      expect(item('b', date: dia1, billId: '').isLinkedToBill, isFalse);
    });

    test('com conta, sim', () {
      expect(item('c', date: dia1, billId: 'conta-1').isLinkedToBill, isTrue);
    });

    test('desfazer o vínculo limpa o campo', () {
      final ligada = item('d', date: dia1, billId: 'conta-1');
      expect(ligada.copyWith(clearBill: true).isLinkedToBill, isFalse);
    });
  });

  group('Horário opcional', () {
    test('item sem horário não tem hora', () {
      expect(item('a', date: dia1).hasTime, isFalse);
    });

    test('tirar o horário de um item que tinha', () {
      final comHora = item('b', date: dia1, hora: 9);
      expect(comHora.hasTime, isTrue);
      expect(comHora.copyWith(clearTime: true).hasTime, isFalse);
    });
  });
}
