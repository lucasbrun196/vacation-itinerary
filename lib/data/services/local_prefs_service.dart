import 'package:shared_preferences/shared_preferences.dart';

/// Preferências guardadas no aparelho (localStorage na Web).
///
/// Só conveniência de navegação — a identidade da pessoa vem do
/// Firebase Auth, nunca daqui.
class LocalPrefsService {
  LocalPrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kTripId = 'last_trip_id';

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
}
