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

class _MapPickerSheetState extends ConsumerState<MapPickerSheet>
    with SingleTickerProviderStateMixin {
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

  /// Anima o zoom dos botões. Sem isso o mapa salta de um nível para o
  /// outro e a pessoa perde a referência de onde estava.
  late final AnimationController _zoomAnimation;
  Animation<double>? _zoomTween;

  @override
  void initState() {
    super.initState();
    _zoomAnimation = AnimationController(vsync: this, duration: Motion.normal)
      ..addListener(_applyZoomFrame);

    final initial = widget.initial;
    if (initial != null) {
      _point = LatLng(initial.lat, initial.lng);
      _address = initial.address;
      _nameController.text = initial.name;
    }

    // Onde a câmera abre. Calculado uma vez e guardado: o `MapOptions`
    // leva `initialCenter`/`initialZoom`, e passar valores novos a cada
    // rebuild faz o `FlutterMap` reiniciar a câmera — o mapa voltava
    // sozinho para o zoom de abertura assim que qualquer coisa na tela
    // mudava.
    _startCenter = _resolveStartCenter();
    _startZoom = _point != null || _hasItemWithCoords
        ? MapConfig.pinZoom
        : MapConfig.fallbackZoom;
  }

  late final LatLng _startCenter;
  late final double _startZoom;

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _searchTimer?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Onde o mapa abre: o ponto já escolhido, senão a última atividade do
  /// roteiro que tenha coordenada, senão o Brasil inteiro.
  LatLng _resolveStartCenter() {
    final point = _point;
    if (point != null) return point;

    for (final item in _itineraryItems.reversed) {
      if (item.hasCoords) return LatLng(item.lat!, item.lng!);
    }
    return const LatLng(MapConfig.fallbackLat, MapConfig.fallbackLng);
  }

  bool get _hasItemWithCoords => _itineraryItems.any((i) => i.hasCoords);

  List<ItineraryItem> get _itineraryItems =>
      ref.read(itineraryProvider).valueOrNull ?? const <ItineraryItem>[];

  bool get _canConfirm => _point != null && _nameController.text.trim().isNotEmpty;

  void _applyZoomFrame() {
    final tween = _zoomTween;
    if (tween == null) return;
    _mapController.move(_mapController.camera.center, tween.value);
  }

  /// Aproxima ou afasta um nível, sem sair dos limites do mapa.
  ///
  /// O caminho até o nível novo é animado: além de ficar mais agradável,
  /// a câmera passa por valores contínuos, como num gesto de pinça, em
  /// vez de saltar de uma vez.
  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final target = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    if (target == camera.zoom) return;

    if (context.reduceMotion) {
      _mapController.move(camera.center, target);
      return;
    }

    // Parte de onde a câmera está agora, e não do alvo anterior: assim
    // dois toques seguidos encadeiam sem tranco.
    _zoomTween = Tween(begin: camera.zoom, end: target)
        .chain(CurveTween(curve: Motion.smooth))
        .animate(_zoomAnimation);
    _zoomAnimation.forward(from: 0);
  }

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
      // O endereço era do ponto anterior. Some junto com ele: se a
      // geocodificação falhar, é melhor ficar sem endereço do que
      // mostrar o de outro lugar.
      _address = null;
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
                            center: _startCenter,
                            zoom: _startZoom,
                            point: _point,
                            onTap: _onMapTap,
                          ),
                          Positioned(
                            left: Gap.sm,
                            bottom: Gap.sm,
                            child: _ZoomButtons(
                              onZoomIn: () => _zoomBy(1),
                              onZoomOut: () => _zoomBy(-1),
                            ),
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
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onTap: (_, latLng) => onTap(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
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

/// Os limites de zoom do mapa. Ficam aqui porque tanto o [_Map] quanto
/// os botões precisam obedecer aos mesmos.
const _minZoom = 2.0;
const _maxZoom = 18.0;

/// Aproximar e afastar sem depender do gesto de pinça — no desktop não
/// existe, e no celular nem todo mundo acerta.
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface.withValues(alpha: 0.92),
      borderRadius: Radii.brMd,
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add_rounded,
            tooltip: 'Aproximar',
            onPressed: onZoomIn,
          ),
          Divider(height: 1, thickness: 1, color: context.colors.outline),
          _ZoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'Afastar',
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: context.colors.onSurface),
        ),
      ),
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
