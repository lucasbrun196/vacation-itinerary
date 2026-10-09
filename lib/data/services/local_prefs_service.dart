import 'package:shared_preferences/shared_preferences.dart';

/// Preferências guardadas no aparelho (localStorage na Web).
///
/// Só conveniência de navegação — a identidade da pessoa vem do
/// Firebase Auth, nunca daqui.
class LocalPrefsService {
  LocalPrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kTripId = 'last_trip_id';
  static const _kThemeMode = 'theme_mode';

  static Future<LocalPrefsService> create() async =>
      LocalPrefsService(await SharedPreferences.getInstance());

  /// Última viagem aberta, para o app voltar direto nela.
  String? get lastTripId => _prefs.getString(_kTripId);

  Future<void> setLastTripId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kTripId);
    } else {
      await _prefs.setString(_kTripId, id);
    }
  }

  /// Tema escolhido: `system`, `light` ou `dark` — o `name` do
  /// `ThemeMode`. Guardado como texto para não depender do Flutter aqui.
  String? get themeMode => _prefs.getString(_kThemeMode);

  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);
}
