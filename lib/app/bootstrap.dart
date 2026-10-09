import 'package:cloud_firestore/cloud_firestore.dart';
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

    _enableOfflineCache();

    // Erros de widget viram log legível em vez de tela vermelha em produção.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode) debugPrint('Erro: ${details.exception}');
    };
  }

  /// Liga o cache em disco do Firestore.
  ///
  /// Viagem é justamente onde a rede falha, e na web o padrão do
  /// Firestore é guardar tudo **só em memória**: recarregar a página
  /// sem rede abria o app (o service worker já guarda a casca) e
  /// mostrava tela vazia. Com o cache em disco as leituras vêm do
  /// que já foi baixado e as escritas ficam na fila até a rede voltar.
  ///
  /// Precisa rodar antes da primeira consulta — depois disso mudar
  /// `settings` lança.
  static void _enableOfflineCache() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,

      // O roteiro, as contas e as cotas de uma viagem são poucos
      // kilobytes. O limite padrão (40 MB) descartaria dado antigo sem
      // necessidade, e o que foi descartado não existe offline.
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,

      // Sem isto, a segunda aba aberta não ganha a posse do cache e
      // fica sem persistência — e no navegador o app vive em abas.
      // Ignorado fora da web.
      webPersistentTabManager: WebPersistentMultipleTabManager(),
    );
  }
}
