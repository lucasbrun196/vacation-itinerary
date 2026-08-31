import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

/// Previsão do tempo por coordenada, pela **Open-Meteo**.
///
/// É de graça, não pede chave nem cadastro (por isso não há nada para
/// configurar no build, ao contrário do token do Mapbox) e devolve até 16
/// dias à frente. A licença é CC-BY: a atribuição aparece no tooltip do
/// chip e no README.
///
/// Como a geocodificação, isto é conveniência: quando a rede falha o
/// serviço devolve um mapa vazio e a tela simplesmente não mostra o chip.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'api.open-meteo.com';

  /// O teto da API. A janela de sete dias antes da viagem cabe aqui com
  /// folga, mas uma viagem longa tem dias além do horizonte — para eles a
  /// consulta simplesmente não traz nada.
  static const forecastDays = 16;

  /// Previsão já buscada nesta sessão, por coordenada arredondada.
  ///
  /// Guardamos o `Future`, e não o resultado: várias atividades do mesmo
  /// destino são construídas no mesmo frame, e assim as que chegam
  /// enquanto o primeiro pedido está no ar entram de carona nele.
  final _cache = <String, Future<Map<String, DailyWeather>>>{};

  /// Dia (`yyyy-MM-dd`) → previsão, para o ponto pedido.
  ///
  /// Mapa vazio quando a rede falhou ou a resposta veio estranha.
  Future<Map<String, DailyWeather>> dailyForecast(WeatherQuery query) {
    return _cache.putIfAbsent(query.toString(), () => _fetch(query));
  }

  Future<Map<String, DailyWeather>> _fetch(WeatherQuery query) async {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': '${query.lat}',
      'longitude': '${query.lng}',
      // O resumo do dia alimenta o chip; o resto, o painel de detalhe.
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
          'apparent_temperature_max,apparent_temperature_min,'
          'precipitation_probability_max,precipitation_sum,'
          'wind_speed_10m_max,uv_index_max,sunrise,sunset',
      // A linha do tempo por hora do painel. Pesa alguns KB, mas vem no
      // mesmo pedido que já seria feito — e o cache cobre a viagem toda.
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      'timezone': 'auto',
      'forecast_days': '$forecastDays',
    });

    return Weather.parse(await _getJson(uri));
  }

  Future<Object?> _getJson(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      // Previsão é enfeite útil: falhou, o roteiro continua igual.
      return null;
    }
  }
}
