import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_tokens.dart';

/// Estrutura padrão de página: título, subtítulo, ação e conteúdo rolável
/// com largura limitada. Mantém o ritmo visual igual em todas as telas.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.emoji,
    this.action,
    this.floatingActionButton,
    this.bottomSlivers = const [],
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final Widget? action;
  final List<Widget> children;
  final List<Widget> bottomSlivers;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final topPad = context.isMobile ? Gap.lg : Gap.xxl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentContainer(
                child: Padding(
                  padding: EdgeInsets.only(top: topPad, bottom: Gap.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emoji == null ? title : '$title $emoji',
                              style: context.isMobile
                                  ? context.text.headlineMedium
                                  : context.text.displaySmall,
                            ),
                            if (subtitle != null) ...[
                              Gap.vXs,
                              Text(
                                subtitle!,
                                style: context.text.bodyMedium
                                    ?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (action != null) ...[Gap.hMd, action!],
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: Motion.normal).slideY(begin: -0.15, curve: Motion.enter),
            ),
            SliverToBoxAdapter(
              child: ContentContainer(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
            ...bottomSlivers,
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}
