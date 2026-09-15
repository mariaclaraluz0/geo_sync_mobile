import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centraliza o conteúdo em telas grandes sem limitar a altura disponível.
/// Em celulares, ocupa toda a largura; em tablets e desktop, evita linhas
/// excessivamente longas e mantém os controles ao alcance.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1180,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: math.min(constraints.maxWidth, maxWidth),
          height: constraints.maxHeight,
          child: child,
        ),
      ),
    );
  }
}
