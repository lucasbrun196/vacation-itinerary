import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/layout/app_page.dart';

/// Etapa 6: feed de fotos e vídeos em grid masonry com visualizador em tela cheia.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPage(
      title: 'Mural',
      children: [
        SizedBox(height: 40),
        EmptyState(
          icon: Icons.photo_outlined,
          title: 'Em breve',
          message: 'Aqui vão ficar as fotos e os vídeos da viagem.',
        ),
      ],
    );
  }
}
