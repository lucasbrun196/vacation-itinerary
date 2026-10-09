import 'package:flutter/material.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/domain/brand_mark.dart';

/// A moldura das telas de fora do app — login e nova senha: a ilustração
/// da praia, a marca e um cartão com o conteúdo.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: context.isMobile ? _buildMobile() : _buildWide(),
    );
  }

  /// Tela larga: a ilustração ocupa 40% da largura e toda a altura, à
  /// esquerda; o formulário fica centrado no resto. Não rola — se a janela
  /// for baixa demais, o `FittedBox` encolhe o formulário em vez de cortar.
  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2 : 3 é a divisão 40% / 60% pedida para a imagem e o formulário.
        const Expanded(flex: 2, child: _Cover()),
        Expanded(
          flex: 3,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Gap.xl),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Logo(),
                        Gap.vXl,
                        _Card(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Celular: a ilustração vira o fundo inteiro e o formulário flutua num
  /// cartão no centro. Aqui rola, porque o teclado come metade da tela.
  Widget _buildMobile() {
    return Stack(
      children: [
        const Positioned.fill(child: _Cover()),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Logo(),
                      Gap.vXl,
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandMark(size: 32),
        Gap.vXs,
        Text(
          'Roteiro, contas e fotos da viagem',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.xl),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brXl,
        border: Border.all(color: context.colors.outline),
        boxShadow: AppColors.glow(AppColors.coral, opacity: context.isDark ? 0 : 0.12, blur: 40, y: 16),
      ),
      child: child,
    );
  }
}

/// A ilustração do avião sobre a praia. Decorativa: fica fora da árvore de
/// acessibilidade.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_cover.jpg',
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
  }
}
