import 'package:flutter/material.dart';

enum DataStateKind { loading, error, empty }

/// Estados consistentes para listas que dependem de dados remotos.
class DataStatePanel extends StatelessWidget {
  const DataStatePanel({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final DataStateKind kind;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final carregando = kind == DataStateKind.loading;
    final erro = kind == DataStateKind.error;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: carregando,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (carregando)
                  const SizedBox.square(
                    dimension: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  Icon(
                    erro
                        ? Icons.cloud_off_outlined
                        : Icons.inventory_2_outlined,
                    size: 42,
                    color: erro ? scheme.error : scheme.onSurfaceVariant,
                  ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
                if (erro && onRetry != null) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DataFreshnessBanner extends StatelessWidget {
  const DataFreshnessBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Dados possivelmente desatualizados. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          border: Border.all(color: const Color(0xFFB7791F)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final conteudo = [
              const Icon(Icons.cloud_off_outlined, color: Color(0xFF754600)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF4A2C00),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A2C00),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Atualizar'),
                ),
              ],
            ];
            if (constraints.maxWidth < 430 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: conteudo.take(3).toList()),
                  if (onRetry != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A2C00),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Atualizar'),
                      ),
                    ),
                ],
              );
            }
            return Row(children: conteudo);
          },
        ),
      ),
    );
  }
}
