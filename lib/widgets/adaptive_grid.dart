import 'package:flutter/material.dart';

/// Grade de cartões cuja altura acompanha o conteúdo.
///
/// Diferente de `GridView.count` com `childAspectRatio` fixo, não corta o
/// texto quando a tela é estreita ou a fonte do sistema está ampliada. O
/// número de colunas cresce com a largura disponível (celular → tablet), e
/// os cartões de uma mesma linha ficam com a mesma altura.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 150,
    this.maxColumns = 4,
    this.spacing = 12,
  });

  final List<Widget> children;

  /// Largura mínima de cada cartão; define quantas colunas cabem.
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cabem =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor();
        final colunas = cabem.clamp(1, maxColumns);
        final linhas = <Widget>[];
        for (var i = 0; i < children.length; i += colunas) {
          final itens = children.sublist(
            i,
            (i + colunas).clamp(0, children.length),
          );
          linhas.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < colunas; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: j < itens.length ? itens[j] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < linhas.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              linhas[i],
            ],
          ],
        );
      },
    );
  }
}
