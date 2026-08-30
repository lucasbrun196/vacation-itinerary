import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/feedback/empty_state.dart';
import '../../../shared/widgets/layout/app_page.dart';

/// Etapa 6: feed de fotos e vídeos em grid masonry com visualizador em tela cheia.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: 'Mural',
      emoji: '📸',
      subtitle: 'O álbum compartilhado da turma',
      children: const [
        SizedBox(height: 40),
        EmptyState(
          icon: Icons.photo_library_rounded,
          title: 'Em breve',
          message: 'Aqui vão ficar as fotos e vídeos enviados pelo grupo.',
          accent: AppColors.grape,
        ),
      ],
    );
  }
}
