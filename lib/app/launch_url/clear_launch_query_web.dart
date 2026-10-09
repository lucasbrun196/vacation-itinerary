import 'package:web/web.dart' as web;

/// Tira a query (`?mode=...&oobCode=...`) da barra de endereço, mantendo o
/// caminho e o `#` da rota. Sem isto, recarregar a página depois de trocar
/// a senha reabriria a tela com o código já gasto.
void clearLaunchQuery() {
  final location = web.window.location;
  web.window.history.replaceState(null, '', '${location.pathname}${location.hash}');
}
