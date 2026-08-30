import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/map_config.dart';

/// Um lugar escolhido no mapa: a coordenada para o banco e o nome para
/// a tela.
@immutable
class PickedPlace {
  const PickedPlace({
    required this.lat,
    required this.lng,
    required this.name,
    this.address,
  });

  final double lat;
  final double lng;

  /// O que a pessoa vê: "Praia da Joaquina", "Rua Bocaiúva".
  final String name;

  /// Complemento, quando o Nominatim devolve algo mais completo.
  final String? address;

  PickedPlace copyWith({String? name}) => PickedPlace(
        lat: lat,
        lng: lng,
        name: name ?? this.name,
        address: address,
      );

  @override
  bool operator ==(Object other) =>
      other is PickedPlace &&
      other.lat == lat &&
      other.lng == lng &&
      other.name == name &&
      other.address == address;

  @override
  int get hashCode => Object.hash(lat, lng, name, address);
}

/// Traduz coordenada em nome de lugar, e nome de lugar em coordenada.
///
/// Usa o **Nominatim** (OpenStreetMap) e não a geocodificação do Mapbox:
/// o plano gratuito do Mapbox é o *temporary geocoding*, cujos termos não
/// permitem guardar o resultado — e aqui o nome do lugar vai para o
/// Firestore. O Mapbox entra só nos tiles do mapa.
///
/// A política de uso do Nominatim pede no máximo uma requisição por
/// segundo e identificação do app; quem chama é responsável pelo
/// debounce (ver o seletor de mapa).
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'nominatim.openstreetmap.org';

  /// No navegador o `User-Agent` é do próprio navegador e não pode ser
  /// sobrescrito — o Nominatim aceita o `Referer` nesse caso.
  Map<String, String> get _headers =>
      kIsWeb ? const {} : const {'User-Agent': MapConfig.userAgent};

  /// Coordenada → nome. Devolve `null` quando a rede falha ou o ponto
  /// cai no meio do oceano: a UI cai no preenchimento manual.
  Future<PickedPlace?> reverse(double lat, double lng) async {
    final uri = Uri.https(_host, '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '17',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    final json = await _getJson(uri);
    if (json is! Map<String, dynamic>) return null;

    return PickedPlace(
      lat: lat,
      lng: lng,
      name: placeLabel(json) ?? 'Ponto escolhido no mapa',
      address: shortAddress(json),
    );
  }

  /// Nome → lista de candidatos. Lista vazia quando não achou nada.
  Future<List<PickedPlace>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return const [];

    final uri = Uri.https(_host, '/search', {
      'format': 'jsonv2',
      'q': term,
      'limit': '6',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    final json = await _getJson(uri);
    if (json is! List) return const [];

    final places = <PickedPlace>[];
    for (final entry in json) {
      if (entry is! Map<String, dynamic>) continue;
      final lat = double.tryParse('${entry['lat']}');
      final lng = double.tryParse('${entry['lon']}');
      final name = placeLabel(entry);
      if (lat == null || lng == null || name == null) continue;
      places.add(
        PickedPlace(lat: lat, lng: lng, name: name, address: shortAddress(entry)),
      );
    }
    return places;
  }

  Future<Object?> _getJson(Uri uri) async {
    try {
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      // Geocodificação é conveniência: falhou, a pessoa digita o nome.
      return null;
    }
  }

  /// O nome curto que vai para a tela.
  ///
  /// O Nominatim só preenche `name` quando o lugar tem nome próprio
  /// (praia, parque, restaurante). Em um ponto qualquer de rua o campo
  /// vem vazio, e aí a rua é a melhor referência — depois o bairro, a
  /// cidade, e só então a linha inteira.
  @visibleForTesting
  static String? placeLabel(Map<String, dynamic> json) {
    final address = json['address'];
    final parts = address is Map ? address : const {};

    final candidates = [
      json['name'],
      parts['tourism'],
      parts['leisure'],
      parts['amenity'],
      parts['beach'],
      parts['road'],
      parts['neighbourhood'],
      parts['suburb'],
      parts['village'],
      parts['town'],
      parts['city'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    final display = json['display_name'];
    if (display is String && display.trim().isNotEmpty) {
      return display.split(',').first.trim();
    }
    return null;
  }

  /// Complemento do nome: cidade e estado, sem repetir o que já está no
  /// [placeLabel] e sem a linha quilométrica do `display_name`.
  @visibleForTesting
  static String? shortAddress(Map<String, dynamic> json) {
    final address = json['address'];
    if (address is! Map) return null;

    final label = placeLabel(json);
    final parts = [
      address['suburb'],
      address['city'] ?? address['town'] ?? address['village'],
      address['state'],
    ]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != label)
        .toList();

    return parts.isEmpty ? null : parts.join(', ');
  }
}
