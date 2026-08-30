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

  /// Estilo do mapa, no formato `usuario/estilo`.
  ///
  /// Para usar um estilo próprio feito no Mapbox Studio, é só trocar esta
  /// constante pelo id de lá (`seu-usuario/clx...`). O resto do app não
  /// muda.
  static const style = 'mapbox/streets-v12';

  /// Tiles raster do estilo.
  ///
  /// Isto é a **Static Tiles API**: o plano gratuito cobre 200 mil
  /// requisições por mês. As peças são de 512px porque as de 256
  /// custariam quatro requisições para cobrir a mesma área — daí o
  /// `tileDimension: 512` no [TileLayer].
  ///
  /// Não acrescente `zoomOffset: -1` junto do `tileDimension`. O
  /// `tileDimension` já deixa a grade um nível mais grossa; o offset
  /// pedia a peça de um zoom acima com as coordenadas do zoom de baixo,
  /// e a partir de certo zoom o x/y estourava o limite daquele nível e o
  /// mapa ficava cinza.
  ///
  /// O `{r}` vira `@2x` em telas de alta densidade.
  static String get tileUrl =>
      'https://api.mapbox.com/styles/v1/$style'
      '/tiles/512/{z}/{x}/{y}{r}?access_token=$token';

  static const tileDimension = 512;

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
