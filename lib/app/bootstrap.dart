import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../firebase_options.dart';

/// Inicialização da aplicação, isolada do `main` para que erros de
/// startup fiquem visíveis em vez de virarem tela branca na web.
abstract final class Bootstrap {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Formatadores de data em pt-BR.
    await initializeDateFormatting('pt_BR', null);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Erros de widget viram log legível em vez de tela vermelha em produção.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode) debugPrint('Erro: ${details.exception}');
    };
  }
}
