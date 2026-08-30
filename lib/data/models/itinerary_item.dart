import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/formatters.dart';
import 'itinerary_enums.dart';

/// Uma parada do roteiro: o que a turma vai fazer, onde, quando e como
/// chega lá.
///
/// O horário é opcional de propósito — em viagem muita coisa é "algum
/// momento da quinta", e obrigar hora exata só geraria dado inventado.
class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.title,
    required this.date,
    this.category = ItineraryCategory.other,
    this.startAt,
    this.endAt,
    this.placeName,
    this.address,
    this.lat,
    this.lng,
    this.transport,
    this.billId,
    this.notes,
    this.link,
    this.status = ItineraryStatus.planned,
    this.order = 0,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;

  /// O dia da atividade, sempre normalizado para meia-noite.
  final DateTime date;

  final ItineraryCategory category;

  /// Data e hora de início. Null quando a atividade não tem horário.
  final DateTime? startAt;
  final DateTime? endAt;

  /// Onde é: nome do lugar e, opcionalmente, o endereço. É isto — e
  /// nunca a coordenada — que aparece para o usuário.
  final String? placeName;
  final String? address;

  /// O ponto exato, escolhido no mapa. Fica só no banco: serve para a
  /// previsão do tempo, que precisa de coordenada e não de nome.
  final double? lat;
  final double? lng;

  final TransportMode? transport;

  /// Conta da viagem ligada a esta atividade. É o que permite responder
  /// "quanto custou o passeio de barco?" sem digitar o valor duas vezes.
  final String? billId;

  final String? notes;
  final String? link;
  final ItineraryStatus status;
  final int order;
  final String? createdBy;
  final DateTime? createdAt;

  bool get hasTime => startAt != null;

  bool get hasCoords => lat != null && lng != null;

  bool get isLinkedToBill => billId != null && billId!.isNotEmpty;

  /// Chave de agrupamento por dia, imune a fuso horário.
  String get dayKey => Fmt.dayKey(date);

  /// Ordenação dentro do dia: quem tem horário vem primeiro, na ordem do
  /// relógio; o resto vai para o fim, na ordem de cadastro.
  int compareForDay(ItineraryItem other) {
    final a = startAt, b = other.startAt;
    if (a != null && b != null) return a.compareTo(b);
    if (a != null) return -1;
    if (b != null) return 1;
    return order.compareTo(other.order);
  }

  factory ItineraryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final date = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ItineraryItem(
      id: doc.id,
      title: d['title'] as String? ?? '',
      date: DateTime(date.year, date.month, date.day),
      category: ItineraryCategory.fromId(d['category'] as String?),
      startAt: (d['startAt'] as Timestamp?)?.toDate(),
      endAt: (d['endAt'] as Timestamp?)?.toDate(),
      placeName: d['placeName'] as String?,
      address: d['address'] as String?,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      transport: TransportMode.fromId(d['transport'] as String?),
      billId: d['billId'] as String?,
      notes: d['notes'] as String?,
      link: d['link'] as String?,
      status: ItineraryStatus.fromId(d['status'] as String?),
      order: (d['order'] as num?)?.toInt() ?? 0,
      createdBy: d['createdBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': Timestamp.fromDate(date),
        'dayKey': dayKey,
        'category': category.name,
        'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
        'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
        'placeName': placeName,
        'address': address,
        'lat': lat,
        'lng': lng,
        'transport': transport?.name,
        'billId': billId,
        'notes': notes,
        'link': link,
        'status': status.name,
        'order': order,
        'createdBy': createdBy,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ItineraryItem copyWith({
    String? title,
    DateTime? date,
    ItineraryCategory? category,
    DateTime? startAt,
    DateTime? endAt,
    String? placeName,
    String? address,
    double? lat,
    double? lng,
    TransportMode? transport,
    String? billId,
    String? notes,
    String? link,
    ItineraryStatus? status,
    int? order,
    bool clearTime = false,
    bool clearBill = false,
    bool clearTransport = false,
    bool clearCoords = false,
  }) =>
      ItineraryItem(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        category: category ?? this.category,
        startAt: clearTime ? null : (startAt ?? this.startAt),
        endAt: clearTime ? null : (endAt ?? this.endAt),
        placeName: placeName ?? this.placeName,
        address: address ?? this.address,
        lat: clearCoords ? null : (lat ?? this.lat),
        lng: clearCoords ? null : (lng ?? this.lng),
        transport: clearTransport ? null : (transport ?? this.transport),
        billId: clearBill ? null : (billId ?? this.billId),
        notes: notes ?? this.notes,
        link: link ?? this.link,
        status: status ?? this.status,
        order: order ?? this.order,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}

/// Um dia do roteiro com suas atividades já ordenadas.
class ItineraryDay {
  const ItineraryDay({required this.date, required this.items});

  final DateTime date;
  final List<ItineraryItem> items;

  String get dayKey => Fmt.dayKey(date);
  bool get isToday => date.isToday;
  int get doneCount => items.where((i) => i.status == ItineraryStatus.done).length;
}
