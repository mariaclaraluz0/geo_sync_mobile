import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/sync/data_exporter.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:mobile/widgets/settings_widgets.dart';

/// Grupo "Dados e sincronização" das configurações do motorista.
class SecaoSincronizacao extends StatelessWidget {
  const SecaoSincronizacao({super.key, SyncEngine? sync}) : _sync = sync;

  final SyncEngine? _sync;

  SyncEngine get sync => _sync ?? SyncEngine.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: sync.estado,
      builder: (context, estado, _) => SettingsGroup(
        children: [
          SettingsActionTile(
            icon: estado.erro != null
                ? Icons.cloud_off_rounded
                : Icons.cloud_sync_rounded,
            color: estado.erro != null
                ? SettingsColors.orange
                : SettingsColors.blue,
            title: estado.sincronizando
                ? 'Sincronizando…'
                : 'Sincronizar agora',
            subtitle: _descricao(estado),
            value: estado.totalPendente > 0
                ? '${estado.totalPendente} pendente${estado.totalPendente == 1 ? '' : 's'}'
                : null,
            loading: estado.sincronizando,
            onTap: () => _sincronizar(context),
          ),
          SettingsActionTile(
            icon: Icons.merge_type_rounded,
            color: SettingsColors.violet,
            title: 'Conflitos resolvidos',
            subtitle: estado.conflitos == 0
                ? 'Nenhum conflito até agora'
                : 'Veja como cada divergência foi decidida',
            value: estado.conflitos == 0 ? null : '${estado.conflitos}',
            onTap: () => _abrirConflitos(context),
          ),
          SettingsActionTile(
            icon: Icons.ios_share_rounded,
            color: SettingsColors.green,
            title: 'Exportar dados',
            subtitle: 'Localizações e remessas em CSV ou GeoJSON',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (_) => const _ExportarSheet(),
            ),
          ),
        ],
      ),
    );
  }

  static String _descricao(SyncState estado) {
    if (estado.sincronizando) return 'Enviando e recebendo alterações';
    if (estado.erro != null) return 'Sem conexão • tentaremos novamente';
    final ultima = estado.ultimaSincronizacao;
    final quando = ultima == null
        ? 'Ainda não sincronizado'
        : 'Última: ${tempoRelativo(ultima)}';
    if (estado.pontosPendentes > 0) {
      return '$quando • ${estado.pontosPendentes} ponto${estado.pontosPendentes == 1 ? '' : 's'} de GPS na fila';
    }
    return quando;
  }

  Future<void> _sincronizar(BuildContext context) async {
    try {
      final rel = await sync.sincronizar();
      if (!context.mounted) return;
      final partes = <String>[
        if (rel.acoesEnviadas > 0)
          '${rel.acoesEnviadas} alteração(ões) enviada(s)',
        if (rel.pontosEnviados > 0) '${rel.pontosEnviados} ponto(s) de GPS',
        if (rel.conflitos > 0) '${rel.conflitos} conflito(s) resolvido(s)',
      ];
      showSettingsMessage(
        context,
        partes.isEmpty
            ? 'Tudo sincronizado.'
            : 'Sincronizado: ${partes.join(', ')}.',
      );
    } on ApiException catch (error) {
      if (context.mounted) {
        showSettingsMessage(context, error.message, error: true);
      }
    }
  }

  void _abrirConflitos(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ConflitosSheet(),
    );
  }
}

/// "agora", "há 5 min", "há 2 h", "há 3 dias".
String tempoRelativo(DateTime data, {DateTime? agora}) {
  final diferenca = (agora ?? DateTime.now()).difference(data);
  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inDays < 1) return 'há ${diferenca.inHours} h';
  return 'há ${diferenca.inDays} dia${diferenca.inDays == 1 ? '' : 's'}';
}

// ============================================================
// CONFLITOS
// ============================================================

class _ConflitosSheet extends StatefulWidget {
  const _ConflitosSheet();

  @override
  State<_ConflitosSheet> createState() => _ConflitosSheetState();
}

class _ConflitosSheetState extends State<_ConflitosSheet> {
  final _registros = ConflictLog.instance.listar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, controller) => FutureBuilder<List<ConflictRecord>>(
        future: _registros,
        builder: (context, snapshot) {
          final itens = snapshot.data ?? const <ConflictRecord>[];
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SettingsSheetHeader(
                icon: Icons.merge_type_rounded,
                color: SettingsColors.violet,
                title: 'Conflitos resolvidos',
                subtitle: 'Alterações offline que divergiram do servidor',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O status de uma remessa nunca regride e status finais '
                        'do servidor sempre prevalecem. Nos demais casos vence '
                        'a alteração mais recente.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (itens.isEmpty)
                const _Vazio()
              else
                for (final item in itens) _ItemConflito(item),
            ],
          );
        },
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SettingsIconBadge(
            icon: Icons.verified_rounded,
            color: SettingsColors.green,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum conflito registrado',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suas alterações offline foram aplicadas sem divergências.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ItemConflito extends StatelessWidget {
  const _ItemConflito(this.item);

  final ConflictRecord item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = item.vencedorLocal
        ? SettingsColors.green
        : SettingsColors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.vencedorLocal
                    ? Icons.phone_android_rounded
                    : Icons.dns_rounded,
                size: 18,
                color: cor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Remessa ${item.remessaId ?? '-'} • ${item.campo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                tempoRelativo(item.resolvidoEm),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Valor('Aparelho', item.valorLocal, item.vencedorLocal),
              _Valor('Servidor', item.valorServidor, !item.vencedorLocal),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.motivo,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor(this.origem, this.valor, this.venceu);

  final String origem;
  final String? valor;
  final bool venceu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = venceu ? SettingsColors.green : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: venceu
            ? SettingsColors.green.withValues(alpha: 0.12)
            : scheme.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (venceu) ...[
            Icon(Icons.check_rounded, size: 14, color: cor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              '$origem: ${valor ?? '—'}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: venceu ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPORTAÇÃO
// ============================================================

class _ExportarSheet extends StatefulWidget {
  const _ExportarSheet();

  @override
  State<_ExportarSheet> createState() => _ExportarSheetState();
}

class _ExportarSheetState extends State<_ExportarSheet> {
  var _conjunto = ConjuntoExportacao.localizacoes;
  FormatoExportacao? _exportando;

  Future<void> _exportar(FormatoExportacao formato) async {
    setState(() => _exportando = formato);
    final caixa = context.findRenderObject() as RenderBox?;
    final origem = caixa == null
        ? null
        : caixa.localToGlobal(Offset.zero) & caixa.size;
    try {
      final resultado = await ExportService.instance.exportar(
        _conjunto,
        formato,
        origemCompartilhamento: origem,
      );
      if (!mounted) return;
      if (resultado.registros == 0) {
        showSettingsMessage(
          context,
          _conjunto == ConjuntoExportacao.localizacoes
              ? 'Nenhuma localização registrada ainda.'
              : 'Nenhuma remessa sincronizada ainda.',
          error: true,
        );
        return;
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showSettingsMessage(
          context,
          'Não foi possível exportar: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsSheetHeader(
            icon: Icons.ios_share_rounded,
            color: SettingsColors.green,
            title: 'Exportar dados',
            subtitle: 'Gere um arquivo para planilhas ou mapas',
          ),
          const SizedBox(height: 20),
          SegmentedButton<ConjuntoExportacao>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ConjuntoExportacao.localizacoes,
                icon: Icon(Icons.route_rounded, size: 18),
                label: Text('Localizações'),
              ),
              ButtonSegment(
                value: ConjuntoExportacao.remessas,
                icon: Icon(Icons.inventory_2_rounded, size: 18),
                label: Text('Remessas'),
              ),
            ],
            selected: {_conjunto},
            onSelectionChanged: _exportando != null
                ? null
                : (valor) => setState(() => _conjunto = valor.first),
          ),
          const SizedBox(height: 16),
          _OpcaoFormato(
            icon: Icons.table_chart_rounded,
            color: SettingsColors.green,
            titulo: 'CSV',
            descricao: 'Abre no Excel, Google Planilhas e LibreOffice',
            carregando: _exportando == FormatoExportacao.csv,
            habilitado: _exportando == null,
            onTap: () => _exportar(FormatoExportacao.csv),
          ),
          const SizedBox(height: 10),
          _OpcaoFormato(
            icon: Icons.public_rounded,
            color: SettingsColors.indigo,
            titulo: 'GeoJSON',
            descricao: _conjunto == ConjuntoExportacao.localizacoes
                ? 'Pontos e trajetos para QGIS, geojson.io e Google Earth'
                : 'Remessas com coordenadas para ferramentas de mapa',
            carregando: _exportando == FormatoExportacao.geoJson,
            habilitado: _exportando == null,
            onTap: () => _exportar(FormatoExportacao.geoJson),
          ),
        ],
      ),
    );
  }
}

class _OpcaoFormato extends StatelessWidget {
  const _OpcaoFormato({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.descricao,
    required this.carregando,
    required this.habilitado,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String descricao;
  final bool carregando;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: habilitado ? onTap : null,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              SettingsIconBadge(icon: icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (carregando)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: color,
                  ),
                )
              else
                Icon(Icons.download_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
