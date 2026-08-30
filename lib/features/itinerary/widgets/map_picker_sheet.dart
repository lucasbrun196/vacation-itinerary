import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/providers.dart';
import '../../../core/config/map_config.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../shared/widgets/layout/app_sheet.dart';

/// Abre o mapa para escolher um ponto e devolve o lugar escolhido, ou
/// `null` se a pessoa desistir.
///
/// Sai obrigatoriamente por [showAppSheet]: o mapa é montado no overlay
/// do Navigator raiz, fora do escopo da viagem, e é o `showAppSheet` que
/// reembrulha o `ProviderContainer` de quem abriu.
Future<PickedPlace?> showMapPicker(
  BuildContext context, {
  PickedPlace? initial,
}) =>
    showAppSheet<PickedPlace>(
      context: context,
      title: 'Onde é?',
      subtitle: 'Busque ou toque no mapa para marcar o ponto',
      maxWidth: 640,
      builder: (_) => MapPickerSheet(initial: initial),
    );

class MapPickerSheet extends ConsumerStatefulWidget {
  const MapPickerSheet({super.key, this.initial});

  final PickedPlace? initial;

  @override
  ConsumerState<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends ConsumerState<MapPickerSheet> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();

  /// O Nominatim pede no máximo uma requisição por segundo — daí o
  /// debounce enquanto a pessoa digita.
  static const _debounce = Duration(milliseconds: 600);
  Timer? _searchTimer;

  /// Cresce a cada chamada: respostas atrasadas de buscas antigas são
  /// descartadas em vez de sobrescrever a atual.
  int _requestId = 0;

  LatLng? _point;
  String? _address;
  List<PickedPlace> _results = const [];
  bool _searching = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _point = LatLng(initial.lat, initial.lng);
      _address = initial.address;
      _nameController.text = initial.name;
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Onde o mapa abre: o ponto já escolhido, senão a última atividade do
  /// roteiro que tenha coordenada, senão o Brasil inteiro.
  LatLng get _initialCenter {
    final point = _point;
    if (point != null) return point;

    final items = ref.read(itineraryProvider).valueOrNull ?? const <ItineraryItem>[];
    for (final item in items.reversed) {
      if (item.hasCoords) return LatLng(item.lat!, item.lng!);
    }
    return const LatLng(MapConfig.fallbackLat, MapConfig.fallbackLng);
  }

  double get _initialZoom =>
      _point != null || _hasNearbyItem ? MapConfig.pinZoom : MapConfig.fallbackZoom;

  bool get _hasNearbyItem =>
      (ref.read(itineraryProvider).valueOrNull ?? const <ItineraryItem>[])
          .any((i) => i.hasCoords);

  bool get _canConfirm => _point != null && _nameController.text.trim().isNotEmpty;

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    if (value.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _searchTimer = Timer(_debounce, () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    final id = ++_requestId;
    setState(() => _searching = true);

    final places = await ref.read(geocodingServiceProvider).search(query);
    if (!mounted || id != _requestId) return;

    setState(() {
      _searching = false;
      _results = places;
    });

    if (places.isEmpty && context.mounted) {
      context.showSnack('Não achei esse lugar. Tente outro nome.');
    }
  }

  void _selectResult(PickedPlace place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _point = LatLng(place.lat, place.lng);
      _address = place.address;
      _nameController.text = place.name;
      _results = const [];
      _searchController.clear();
    });
    _mapController.move(LatLng(place.lat, place.lng), MapConfig.pinZoom);
  }

  /// Toque no mapa: marca o ponto na hora e busca o nome depois — o pin
  /// não pode esperar a rede.
  Future<void> _onMapTap(LatLng point) async {
    final id = ++_requestId;
    setState(() {
      _point = point;
      _results = const [];
      _resolving = true;
    });

    final place = await ref.read(geocodingServiceProvider).reverse(
          point.latitude,
          point.longitude,
        );
    if (!mounted || id != _requestId) return;

    setState(() {
      _resolving = false;
      if (place != null) {
        _address = place.address;
        _nameController.text = place.name;
      }
    });
  }

  void _confirm() {
    final point = _point;
    if (point == null) return;
    Navigator.of(context).pop(
      PickedPlace(
        lat: point.latitude,
        lng: point.longitude,
        name: _nameController.text.trim(),
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = context.isMobile ? 300.0 : 360.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: !context.isMobile,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    labelText: 'Buscar',
                    hintText: 'Praia da Joaquina, Rua Bocaiúva...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(Gap.md),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          )
                        : null,
                  ),
                ),
                Gap.vMd,
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: Radii.brMd,
                    border: Border.all(color: context.colors.outline),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.shadow.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.brMd,
                    child: SizedBox(
                      height: mapHeight,
                      child: Stack(
                        children: [
                          _Map(
                            controller: _mapController,
                            center: _initialCenter,
                            zoom: _initialZoom,
                            point: _point,
                            onTap: _onMapTap,
                          ),
                          if (_results.isNotEmpty)
                            _Results(results: _results, onPick: _selectResult),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap.vMd,
                _Selection(
                  controller: _nameController,
                  address: _address,
                  hasPoint: _point != null,
                  resolving: _resolving,
                  onNameChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        SheetActions(
          primaryLabel: 'Usar este lugar',
          onPrimary: _canConfirm ? _confirm : null,
          secondaryLabel: 'Cancelar',
          onSecondary: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------

class _Map extends StatelessWidget {
  const _Map({
    required this.controller,
    required this.center,
    required this.zoom,
    required this.point,
    required this.onTap,
  });

  final MapController controller;
  final LatLng center;
  final double zoom;
  final LatLng? point;
  final ValueChanged<LatLng> onTap;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 2,
        maxZoom: 18,
        onTap: (_, latLng) => onTap(latLng),
      ),
      children: [
        TileLayer(
          // A chave força a recarga quando o tema muda de claro para escuro.
          key: ValueKey(context.isDark),
          urlTemplate: MapConfig.tileUrl(dark: context.isDark),
          tileDimension: MapConfig.tileDimension,
          zoomOffset: MapConfig.tileZoomOffset,
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: MapConfig.userAgent,
        ),
        if (point != null)
          MarkerLayer(
            markers: [
              Marker(
                point: point!,
                width: 48,
                height: 52,
                // `topCenter` desenha o marcador acima do ponto, ou seja,
                // com a ponta do pin exatamente onde a pessoa tocou.
                alignment: Alignment.topCenter,
                child: _Pin(point: point!),
              ),
            ],
          ),
        // Atribuição exigida pelos termos do Mapbox e do OpenStreetMap.
        const RichAttributionWidget(
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution('Mapbox'),
            TextSourceAttribution('OpenStreetMap'),
          ],
        ),
      ],
    );
  }
}

/// O pin. Cai de cima a cada novo ponto — a animação é o que dá a
/// sensação de "marcado aqui"; a elipse embaixo é o que o assenta no
/// chão em vez de deixá-lo flutuando.
class _Pin extends StatelessWidget {
  const _Pin({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.place_rounded,
          size: 42,
          color: AppColors.coral,
          shadows: [
            Shadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 3)),
          ],
        ),
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: Radii.brPill,
          ),
        ),
      ],
    );

    if (context.reduceMotion) return pin;

    return pin
        .animate(key: ValueKey('${point.latitude},${point.longitude}'))
        .fadeIn(duration: Motion.fast)
        .slideY(begin: -0.5, end: 0, duration: Motion.normal, curve: Motion.spring);
  }
}

/// Resultados da busca, sobrepostos ao mapa — some assim que a pessoa
/// escolhe um.
class _Results extends StatelessWidget {
  const _Results({required this.results, required this.onPick});

  final List<PickedPlace> results;
  final ValueChanged<PickedPlace> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: Gap.sm,
      right: Gap.sm,
      top: Gap.sm,
      child: Material(
        borderRadius: Radii.brMd,
        elevation: 6,
        color: context.colors.surface,
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: context.colors.outline),
          itemBuilder: (context, i) {
            final place = results[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, size: 20),
              title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: place.address == null
                  ? null
                  : Text(place.address!, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => onPick(place),
            );
          },
        ),
      ),
    );
  }
}

/// O lugar escolhido. O nome fica editável: o Nominatim às vezes devolve
/// algo genérico e a pessoa quer "Casa da Ana".
class _Selection extends StatelessWidget {
  const _Selection({
    required this.controller,
    required this.address,
    required this.hasPoint,
    required this.resolving,
    required this.onNameChanged,
  });

  final TextEditingController controller;
  final String? address;
  final bool hasPoint;
  final bool resolving;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    if (!hasPoint) {
      return Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: Radii.brMd,
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 18, color: context.colors.onSurfaceVariant),
            Gap.hMd,
            Expanded(
              child: Text(
                'Toque no mapa para marcar o ponto — ou busque pelo nome ali em cima.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          onChanged: onNameChanged,
          decoration: InputDecoration(
            labelText: 'Como esse lugar aparece no roteiro',
            prefixIcon: const Icon(Icons.place_rounded, size: 20),
            suffixIcon: resolving
                ? const Padding(
                    padding: EdgeInsets.all(Gap.md),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                : null,
          ),
        ),
        if (address != null) ...[
          Gap.vSm,
          Text(address!, style: context.text.bodySmall),
        ],
      ],
    );
  }
}
