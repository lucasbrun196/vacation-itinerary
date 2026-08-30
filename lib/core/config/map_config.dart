/// Configuração do mapa.
///
/// O token do Mapbox entra por `--dart-define`, nunca pelo código:
///
/// ```bash
/// flutter run -d web-server --web-port 5173 --dart-define=MAPBOX_TOKEN=pk.xxx
/// ```
///
/// Sem token o app continua funcionando — o seletor de mapa fica
/// desabilitado e o lugar é digitado à mão, como antes.
abstract final class MapConfig {
  /// Token público do Mapbox (começa com `pk.`). Vazio quando não foi
  /// passado no build.
  static const token = String.fromEnvironment('MAPBOX_TOKEN');

  static bool get isConfigured => token.isNotEmpty;

  /// Estilo raster do Mapbox — o plano gratuito cobre 750 mil
  /// requisições de tile por mês.
  ///
  /// O `{r}` vira `@2x` em telas de alta densidade; as peças são de
  /// 512px, daí `tileDimension: 512` e `zoomOffset: -1` no [TileLayer].
  static String get tileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}{r}'
      '?access_token=$token';

  static const tileDimension = 512;
  static const tileZoomOffset = -1.0;

  /// Identifica o app para o Mapbox e para o Nominatim.
  static const userAgent = 'com.lucasbrun.vacation_itinerary';

  /// Onde o mapa abre quando não há nenhuma pista de lugar: Brasil
  /// inteiro, para a pessoa navegar até onde quiser.
  static const fallbackLat = -14.235;
  static const fallbackLng = -51.925;
  static const fallbackZoom = 3.5;

  /// Zoom de quando já sabemos o ponto exato.
  static const pinZoom = 15.0;
}
