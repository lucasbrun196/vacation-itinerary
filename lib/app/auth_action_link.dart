import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'launch_url/clear_launch_query.dart';

/// Um link de e-mail do Firebase Auth que abriu o app.
///
/// No console, a "URL de ação" dos modelos de e-mail aponta para a raiz
/// do app, e o Firebase acrescenta `?mode=...&oobCode=...`. A query vem
/// **antes** do `#`, então o go_router — que lê só o fragmento — não a
/// enxerga: quem a lê é este objeto, uma vez, na abertura.
class AuthActionLink {
  const AuthActionLink._(this.mode, this.code, this.query);

  final String mode;
  final String code;
  final Map<String, String> query;

  bool get isPasswordReset => mode == 'resetPassword';

  /// O link que abriu o app, se for um. Fora da web não há URL de entrada.
  ///
  /// Lê uma vez só: a primeira leitura já limpa a query da barra de
  /// endereço, e as seguintes devolvem o mesmo resultado guardado.
  static AuthActionLink? fromLaunch() => _launch;

  static final AuthActionLink? _launch = () {
    if (!kIsWeb) return null;
    final link = fromUri(Uri.base);
    if (link != null) clearLaunchQuery();
    return link;
  }();

  @visibleForTesting
  static AuthActionLink? fromUri(Uri uri) {
    final mode = uri.queryParameters['mode'];
    final code = uri.queryParameters['oobCode'];
    if (mode == null || code == null) return null;
    return AuthActionLink._(mode, code, uri.queryParameters);
  }

  /// A URL de ação é uma só para todos os modelos de e-mail. O app só
  /// tem tela para a redefinição de senha; os outros (confirmar e-mail,
  /// desfazer troca de e-mail) seguem para a página padrão do Firebase,
  /// com os mesmos parâmetros.
  Future<void> forwardToFirebase() async {
    final authDomain = Firebase.app().options.authDomain;
    if (authDomain == null) return;
    final target = Uri.https(authDomain, '/__/auth/action', query);
    await launchUrl(target, webOnlyWindowName: '_self');
  }
}
