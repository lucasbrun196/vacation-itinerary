import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/auth_action_link.dart';
import 'app/bootstrap.dart';
import 'app/providers.dart';
import 'data/services/local_prefs_service.dart';

Future<void> main() async {
  await Bootstrap.init();

  // Link de e-mail do Firebase que o app não trata (só a nova senha tem
  // tela própria): segue para a página padrão e nem sobe o app.
  final link = AuthActionLink.fromLaunch();
  if (link != null && !link.isPasswordReset) {
    await link.forwardToFirebase();
    return;
  }

  // Carregado antes de subir a árvore para que nenhuma tela precise
  // lidar com Future só para descobrir quem é o usuário do aparelho.
  final prefs = await LocalPrefsService.create();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const VacationApp(),
    ),
  );
}
