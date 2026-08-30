import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'breakpoints.dart';

/// Escolhe entre layouts completamente diferentes por tamanho de tela.
/// Se [desktop] ou [tablet] não forem informados, cai para o anterior.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Breakpoints.fromWidth(constraints.maxWidth);
        return switch (size) {
          ScreenSize.mobile => mobile(context),
          ScreenSize.tablet => (tablet ?? mobile)(context),
          ScreenSize.desktop || ScreenSize.wide => (desktop ?? tablet ?? mobile)(context),
        };
      },
    );
  }
}

/// Seleciona um *valor* (não um layout) conforme a largura.
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
  T? wide,
}) {
  return switch (Breakpoints.of(context)) {
    ScreenSize.mobile => mobile,
    ScreenSize.tablet => tablet ?? mobile,
    ScreenSize.desktop => desktop ?? tablet ?? mobile,
    ScreenSize.wide => wide ?? desktop ?? tablet ?? mobile,
  };
}

/// Centraliza e limita a largura do conteúdo em telas largas.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final horizontal = responsiveValue(context, mobile: Gap.lg, tablet: Gap.xl, desktop: Gap.xxl);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}
