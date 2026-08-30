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

  /// Estilos do mapa, no formato `usuario/estilo`.
  ///
  /// Para usar um estilo próprio feito no Mapbox Studio, é só trocar
  /// estas duas constantes pelo id de lá (`seu-usuario/clx...`). O resto
  /// do app não muda.
  static const lightStyle = 'mapbox/light-v11';
  static const darkStyle = 'mapbox/dark-v11';

  /// Tiles raster do estilo, na variante que combina com o tema do app.
  ///
  /// Isto é a **Static Tiles API**: o plano gratuito cobre 200 mil
  /// requisições por mês. As peças são de 512px porque as de 256
  /// custariam quatro requisições para cobrir a mesma área — daí
  /// `tileDimension: 512` e `zoomOffset: -1` no [TileLayer].
  ///
  /// O `{r}` vira `@2x` em telas de alta densidade.
  static String tileUrl({required bool dark}) =>
      'https://api.mapbox.com/styles/v1/${dark ? darkStyle : lightStyle}'
      '/tiles/512/{z}/{x}/{y}{r}?access_token=$token';

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
