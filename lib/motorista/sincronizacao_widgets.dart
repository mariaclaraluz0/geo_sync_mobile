import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/sync/data_exporter.dart';
import 'package:mobile/sync/local_store.dart';
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
                ? LucideIcons.cloudOff
                : LucideIcons.cloudUpload,
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
            icon: LucideIcons.gitMerge,
            color: SettingsColors.violet,
            title: 'Conflitos resolvidos',
            subtitle: estado.conflitos == 0
                ? 'Nenhum conflito até agora'
                : 'Veja como cada divergência foi decidida',
            value: estado.conflitos == 0 ? null : '${estado.conflitos}',
            onTap: () => _abrirConflitos(context),
          ),
          ValueListenableBuilder<int>(
            valueListenable: DataRetentionPolicy.dias,
            builder: (context, dias, _) => SettingsActionTile(
              icon: LucideIcons.calendarClock,
              color: SettingsColors.blue,
              title: 'Retenção do GPS sincronizado',
              subtitle: 'Remover pontos enviados depois de $dias dia(s)',
              onTap: () => _configurarRetencao(context),
            ),
          ),
          SettingsActionTile(
            icon: LucideIcons.trash2,
            color: SettingsColors.orange,
            title: 'Apagar dados locais',
            subtitle: 'Remessas em cache, fila offline, GPS e conflitos',
            onTap: () => _confirmarLimpeza(context),
          ),
          if (estado.acoesPrecisamIntervencao > 0)
            SettingsActionTile(
              icon: LucideIcons.circleAlert,
              color: SettingsColors.orange,
              title: 'Ações que precisam de revisão',
              subtitle:
                  'O servidor rejeitou estas alterações; confira antes de reenviar',
              value: '${estado.acoesPrecisamIntervencao}',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _AcoesRevisaoSheet(sync: sync),
              ),
            ),
          SettingsActionTile(
            icon: LucideIcons.share,
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
              builder: (_) => const ExportarDadosSheet(),
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
        if (rel.acoesPrecisamIntervencao > 0)
          '${rel.acoesPrecisamIntervencao} ação(ões) aguardam revisão',
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

  Future<void> _configurarRetencao(BuildContext context) async {
    final escolhido = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Retenção dos pontos enviados'),
        children: [
          RadioGroup<int>(
            groupValue: DataRetentionPolicy.dias.value,
            onChanged: (valor) => Navigator.pop(context, valor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final dias in DataRetentionPolicy.opcoesEmDias)
                  RadioListTile<int>(value: dias, title: Text('$dias dia(s)')),
              ],
            ),
          ),
        ],
      ),
    );
    if (escolhido == null || !context.mounted) return;
    await DataRetentionPolicy.salvar(escolhido);
    if (context.mounted) showSettingsMessage(context, 'Retenção atualizada.');
  }

  Future<void> _confirmarLimpeza(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar dados deste aparelho?'),
        content: const Text(
          'Isso remove também ações offline ainda não sincronizadas e pontos '
          'de GPS pendentes. Exporte os dados necessários antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    await sync.limparDadosLocais();
    if (context.mounted) showSettingsMessage(context, 'Dados locais apagados.');
  }
}

class _AcoesRevisaoSheet extends StatefulWidget {
  const _AcoesRevisaoSheet({required this.sync});
  final SyncEngine sync;

  @override
  State<_AcoesRevisaoSheet> createState() => _AcoesRevisaoSheetState();
}

class _AcoesRevisaoSheetState extends State<_AcoesRevisaoSheet> {
  late Future<List<PendingAction>> _acoes = widget.sync.acoesParaRevisao();

  void _recarregar() => setState(() => _acoes = widget.sync.acoesParaRevisao());

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.65,
    minChildSize: 0.35,
    maxChildSize: 0.95,
    builder: (context, controller) => FutureBuilder<List<PendingAction>>(
      future: _acoes,
      builder: (context, snapshot) {
        final acoes = snapshot.data ?? const <PendingAction>[];
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            const SettingsSheetHeader(
              icon: LucideIcons.circleAlert,
              color: SettingsColors.orange,
              title: 'Ações para revisar',
              subtitle: 'As ações ficam salvas até você reenviar ou remover.',
            ),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (acoes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhuma ação aguardando revisão.'),
              )
            else
              for (final acao in acoes)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${acao.tipo} • remessa ${acao.remessaId ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(acao.ultimoErro ?? 'O servidor rejeitou a ação.'),
                        Text('Tentativas anteriores: ${acao.tentativas}'),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await widget.sync.removerAcaoPendente(acao.id);
                                if (mounted) _recarregar();
                              },
                              child: const Text('Remover'),
                            ),
                            FilledButton.tonal(
                              onPressed: () async {
                                try {
                                  await widget.sync.tentarAcaoNovamente(
                                    acao.id,
                                  );
                                } on ApiException {
                                  // A ação segue salva; os contadores são atualizados pelo SyncEngine.
                                }
                                if (mounted) _recarregar();
                              },
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );
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
                icon: LucideIcons.gitMerge,
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
                    Icon(LucideIcons.info, size: 18, color: scheme.primary),
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
            icon: LucideIcons.badgeCheck,
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
                    ? LucideIcons.smartphone
                    : LucideIcons.server,
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
            Icon(LucideIcons.check, size: 14, color: cor),
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

/// Folha "Exportar dados": escolhe o conjunto e o formato, mostra quantos
/// registros serão exportados e salva ou compartilha o arquivo. Mensagens
/// de erro e de "nada para exportar" aparecem dentro da própria folha (um
/// SnackBar ficaria escondido atrás dela).
class ExportarDadosSheet extends StatefulWidget {
  const ExportarDadosSheet({super.key, this.servico});

  final ExportService? servico;

  @override
  State<ExportarDadosSheet> createState() => _ExportarDadosSheetState();
}

enum _Acao { salvar, compartilhar }

class _ExportarDadosSheetState extends State<ExportarDadosSheet> {
  ExportService get _servico => widget.servico ?? ExportService.instance;

  var _conjunto = ConjuntoExportacao.localizacoes;
  var _formato = FormatoExportacao.csv;
  final _contagens = <ConjuntoExportacao, int>{};
  _Acao? _executando;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarContagens();
  }

  Future<void> _carregarContagens() async {
    final conjuntos = ConjuntoExportacao.values;
    final totais = await Future.wait(
      conjuntos.map((conjunto) => _servico.contar(conjunto)),
    );
    if (!mounted) return;
    setState(() {
      for (var indice = 0; indice < conjuntos.length; indice++) {
        _contagens[conjuntos[indice]] = totais[indice];
      }
    });
    unawaited(_atualizarContagemRemessas());
  }

  Future<void> _atualizarContagemRemessas() async {
    await _servico.atualizarRemessas();
    final remessas = await _servico.contar(ConjuntoExportacao.remessas);
    if (mounted) {
      setState(() {
        _contagens[ConjuntoExportacao.remessas] = remessas;
      });
    }
  }

  int? get _total => _contagens[_conjunto];
  bool get _ocupado => _executando != null;

  Future<void> _executar(_Acao acao) async {
    setState(() {
      _executando = acao;
      _erro = null;
    });
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final caixa = context.findRenderObject() as RenderBox?;
    final origem = caixa == null
        ? null
        : caixa.localToGlobal(Offset.zero) & caixa.size;
    try {
      final resultado = acao == _Acao.salvar
          ? await _servico.salvar(_conjunto, _formato)
          : await _servico.exportar(
              _conjunto,
              _formato,
              origemCompartilhamento: origem,
            );
      if (!mounted) return;
      if (resultado.registros == 0) {
        setState(() => _erro = _mensagemVazio);
        return;
      }
      if (!resultado.compartilhado) return; // Usuário cancelou.
      navegador.pop();
      _avisar(
        mensageiro,
        resultado.caminho != null
            ? 'Arquivo salvo em ${resultado.caminho}'
            : acao == _Acao.salvar
            ? 'Download iniciado: ${resultado.nomeArquivo}'
            : '${resultado.registros} registro(s) exportado(s).',
      );
    } catch (e) {
      debugPrint('[Export] falhou: $e');
      if (mounted) {
        setState(
          () => _erro = acao == _Acao.compartilhar && ExportService.podeSalvar
              ? 'Não foi possível compartilhar neste dispositivo. '
                    'Use "Salvar arquivo".'
              : 'Não foi possível gerar o arquivo. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _executando = null);
    }
  }

  String get _mensagemVazio => _conjunto == ConjuntoExportacao.localizacoes
      ? 'Ainda não há localizações registradas. Elas são gravadas enquanto o '
            'rastreamento de uma entrega está ativo.'
      : 'Nenhuma remessa disponível. Sincronize com a internet ligada e '
            'tente de novo.';

  void _avisar(ScaffoldMessengerState mensageiro, String texto) {
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(LucideIcons.circleCheckBig, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(texto)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _total;
    final vazio = total == 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSheetHeader(
                icon: LucideIcons.share,
                color: SettingsColors.green,
                title: 'Exportar dados',
                subtitle: 'Gere um arquivo para planilhas ou mapas',
              ),
              const SizedBox(height: 20),
              _rotulo('O que exportar'),
              Row(
                children: [
                  Expanded(
                    child: _OpcaoConjunto(
                      icon: LucideIcons.route,
                      titulo: 'Localizações',
                      contagem: _contagens[ConjuntoExportacao.localizacoes],
                      unidade: 'ponto',
                      selecionado: _conjunto == ConjuntoExportacao.localizacoes,
                      onTap: _ocupado
                          ? null
                          : () => setState(() {
                              _conjunto = ConjuntoExportacao.localizacoes;
                              _erro = null;
                            }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OpcaoConjunto(
                      icon: LucideIcons.package,
                      titulo: 'Remessas',
                      contagem: _contagens[ConjuntoExportacao.remessas],
                      unidade: 'remessa',
                      selecionado: _conjunto == ConjuntoExportacao.remessas,
                      onTap: _ocupado
                          ? null
                          : () => setState(() {
                              _conjunto = ConjuntoExportacao.remessas;
                              _erro = null;
                            }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _rotulo('Formato do arquivo'),
              _OpcaoFormato(
                icon: LucideIcons.sheet,
                color: SettingsColors.green,
                titulo: 'CSV',
                descricao: 'Abre no Excel, Google Planilhas e LibreOffice',
                selecionado: _formato == FormatoExportacao.csv,
                onTap: _ocupado
                    ? null
                    : () => setState(() => _formato = FormatoExportacao.csv),
              ),
              const SizedBox(height: 10),
              _OpcaoFormato(
                icon: LucideIcons.globe,
                color: SettingsColors.indigo,
                titulo: 'GeoJSON',
                descricao: _conjunto == ConjuntoExportacao.localizacoes
                    ? 'Pontos e trajetos para QGIS, geojson.io e Google Earth'
                    : 'Remessas com coordenadas para ferramentas de mapa',
                selecionado: _formato == FormatoExportacao.geoJson,
                onTap: _ocupado
                    ? null
                    : () =>
                          setState(() => _formato = FormatoExportacao.geoJson),
              ),
              const SizedBox(height: 16),
              if (_erro != null || vazio)
                _Aviso(texto: _erro ?? _mensagemVazio)
              else
                _resumo(scheme, total),
              const SizedBox(height: 16),
              ..._botoes(desabilitado: _ocupado || vazio || total == null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      texto.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _resumo(ColorScheme scheme, int? total) {
    final nome = ExportService.nomeArquivo(_conjunto, _formato);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  total == null
                      ? 'Contando registros...'
                      : '$total registro${total == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _botoes({required bool desabilitado}) {
    Widget progresso() => const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2),
    );
    final salvar = FilledButton.icon(
      onPressed: desabilitado ? null : () => _executar(_Acao.salvar),
      icon: _executando == _Acao.salvar
          ? progresso()
          : const Icon(LucideIcons.download),
      label: Text(kIsWeb ? 'Baixar arquivo' : 'Salvar arquivo'),
    );
    final compartilhar = ExportService.podeSalvar
        ? OutlinedButton.icon(
            onPressed: desabilitado
                ? null
                : () => _executar(_Acao.compartilhar),
            icon: _executando == _Acao.compartilhar
                ? progresso()
                : const Icon(LucideIcons.share2),
            label: const Text('Compartilhar'),
          )
        : FilledButton.icon(
            onPressed: desabilitado
                ? null
                : () => _executar(_Acao.compartilhar),
            icon: _executando == _Acao.compartilhar
                ? progresso()
                : const Icon(LucideIcons.share),
            label: const Text('Exportar e compartilhar'),
          );
    return [
      if (ExportService.podeSalvar) salvar,
      if (ExportService.podeSalvar && ExportService.podeCompartilhar)
        const SizedBox(height: 10),
      if (ExportService.podeCompartilhar) compartilhar,
    ];
  }
}

class _OpcaoConjunto extends StatelessWidget {
  const _OpcaoConjunto({
    required this.icon,
    required this.titulo,
    required this.contagem,
    required this.unidade,
    required this.selecionado,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final int? contagem;
  final String unidade;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = selecionado ? scheme.primary : scheme.onSurfaceVariant;
    final detalhe = contagem == null
        ? 'Contando...'
        : '$contagem $unidade${contagem == 1 ? '' : 's'}';
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selecionado ? scheme.primary : scheme.outlineVariant,
                width: selecionado ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: cor, size: 22),
                    const Spacer(),
                    if (selecionado)
                      Icon(
                        LucideIcons.circleCheckBig,
                        color: scheme.primary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detalhe,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required this.selecionado,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String descricao;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado
            ? color.withValues(alpha: 0.08)
            : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selecionado ? color : scheme.outlineVariant,
                width: selecionado ? 1.6 : 1,
              ),
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
                const SizedBox(width: 8),
                Icon(
                  selecionado ? LucideIcons.circleDot : LucideIcons.circle,
                  color: selecionado ? color : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso em destaque dentro da folha (vazio ou erro).
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SettingsColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: SettingsColors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: scheme.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
