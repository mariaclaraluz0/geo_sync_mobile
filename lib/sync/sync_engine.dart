import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/conflict_resolver.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado observável da sincronização, exibido nas telas.
@immutable
class SyncState {
  const SyncState({
    this.sincronizando = false,
    this.ultimaSincronizacao,
    this.acoesPendentes = 0,
    this.pontosPendentes = 0,
    this.conflitos = 0,
    this.acoesPrecisamIntervencao = 0,
    this.erro,
  });

  final bool sincronizando;
  final DateTime? ultimaSincronizacao;
  final int acoesPendentes;
  final int pontosPendentes;
  final int conflitos;
  final int acoesPrecisamIntervencao;
  final String? erro;

  int get totalPendente => acoesPendentes + pontosPendentes;

  SyncState copyWith({
    bool? sincronizando,
    DateTime? ultimaSincronizacao,
    int? acoesPendentes,
    int? pontosPendentes,
    int? conflitos,
    int? acoesPrecisamIntervencao,
    String? erro,
    bool limparErro = false,
  }) => SyncState(
    sincronizando: sincronizando ?? this.sincronizando,
    ultimaSincronizacao: ultimaSincronizacao ?? this.ultimaSincronizacao,
    acoesPendentes: acoesPendentes ?? this.acoesPendentes,
    pontosPendentes: pontosPendentes ?? this.pontosPendentes,
    conflitos: conflitos ?? this.conflitos,
    acoesPrecisamIntervencao: acoesPrecisamIntervencao ?? this.acoesPrecisamIntervencao,
    erro: limparErro ? null : (erro ?? this.erro),
  );
}

/// Resumo de uma rodada de sincronização.
class SyncReport {
  int remessasRecebidas = 0;
  bool incremental = false;
  int acoesEnviadas = 0;
  int acoesDescartadas = 0;
  int acoesPrecisamIntervencao = 0;
  int conflitos = 0;
  int pontosEnviados = 0;

  @override
  String toString() =>
      'SyncReport(recebidas: $remessasRecebidas, incremental: $incremental, '
      'enviadas: $acoesEnviadas, descartadas: $acoesDescartadas, '
      'conflitos: $conflitos, pontos: $pontosEnviados)';
}

/// Sincronização offline-first entre o aparelho e a API Laravel.
///
/// **Incremental**: cada rodada envia `updated_since=<cursor>` para
/// `GET /remessas/minhas`. O cursor é o maior `updated_at` recebido (ou o
/// `server_time` informado pela API), sempre no relógio do servidor, para não
/// depender do relógio do aparelho. Os registros recebidos são mesclados por
/// `id` no cache local. Se a API ignorar o parâmetro e devolver tudo, o
/// resultado continua correto. Como exclusões só aparecem em uma listagem
/// completa, uma sincronização completa é feita a cada [intervaloCompleto].
class SyncEngine {
  SyncEngine({
    ApiService? api,
    PendingQueue? fila,
    LocationStore? pontos,
    ConflictLog? conflitos,
    this.resolver = const ConflictResolver(),
    DateTime Function()? relogio,
  }) : _api = api ?? ApiService.instance,
       _fila = fila ?? PendingQueue.instance,
       _pontos = pontos ?? LocationStore.instance,
       _conflitos = conflitos ?? ConflictLog.instance,
       _relogio = relogio ?? DateTime.now;

  static final instance = SyncEngine();

  static const cacheRemessasKey = 'motorista_remessas_cache';
  static const _cursorKey = 'geosync_sync_cursor';
  static const _completaKey = 'geosync_sync_completa_em';
  static const _ultimaKey = 'geosync_sync_ultima_em';
  static const _donoKey = 'geosync_sync_usuario';
  static const intervaloCompleto = Duration(minutes: 30);
  static const intervaloAutomatico = Duration(minutes: 2);
  static const _loteDePontos = 100;

  final ApiService _api;
  final PendingQueue _fila;
  final LocationStore _pontos;
  final ConflictLog _conflitos;
  final ConflictResolver resolver;
  final DateTime Function() _relogio;

  final estado = ValueNotifier<SyncState>(const SyncState());

  Future<SyncReport>? _emAndamento;
  Future<int>? _enviandoPontos;
  Timer? _timer;
  AppLifecycleListener? _ciclo;

  // ============================================================
  // SINCRONIZAÇÃO
  // ============================================================

  /// Executa uma rodada completa. Chamadas simultâneas compartilham a mesma
  /// execução. Lança [ApiException] em caso de falha (o estado também
  /// registra o erro).
  Future<SyncReport> sincronizar() =>
      _emAndamento ??= _sincronizar().whenComplete(() => _emAndamento = null);

  Future<SyncReport> _sincronizar() async {
    final relatorio = SyncReport();
    estado.value = estado.value.copyWith(sincronizando: true, limparErro: true);
    try {
      await _garantirDono();
      final servidor = await _baixar(relatorio);
      final enviadas = await _enviarPendentes(servidor, relatorio);
      // Busca o resultado das ações enviadas para atualizar o cache.
      if (enviadas > 0) await _baixar(SyncReport());
      await _enviarTodosOsPontos(relatorio);

      final agora = _relogio().toUtc();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ultimaKey, agora.toIso8601String());
      estado.value = estado.value.copyWith(ultimaSincronizacao: agora);
      debugPrint('[Sync] $relatorio');
      return relatorio;
    } on ApiException catch (error) {
      estado.value = estado.value.copyWith(erro: error.message);
      rethrow;
    } finally {
      await atualizarContadores();
      estado.value = estado.value.copyWith(sincronizando: false);
    }
  }

  /// Remessas do cache local, já com as alterações offline aplicadas.
  Future<List<Map<String, dynamic>>> remessasLocais() async {
    final servidor = await _lerCache();
    return _aplicarPendentes(servidor, await _fila.listar());
  }

  Future<bool> possuiCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(cacheRemessasKey);
  }

  /// Baixa as remessas alteradas e devolve o estado do servidor por id.
  Future<Map<String, Map<String, dynamic>>> _baixar(SyncReport rel) async {
    final prefs = await SharedPreferences.getInstance();
    final agora = _relogio().toUtc();
    final ultimaCompleta = DateTime.tryParse(
      prefs.getString(_completaKey) ?? '',
    );
    final cursor = prefs.getString(_cursorKey);
    final incremental =
        cursor != null &&
        ultimaCompleta != null &&
        agora.difference(ultimaCompleta) < intervaloCompleto;

    final resposta = await _api.requisicao(
      'GET',
      'remessas/minhas',
      query: incremental ? {'updated_since': cursor} : null,
    );
    final recebidas = _api
        .lista(resposta)
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .where((r) => _id(r) != null)
        .toList();

    final Map<String, Map<String, dynamic>> servidor;
    if (incremental) {
      servidor = {for (final r in await _lerCache()) _id(r)!: r};
      for (final registro in recebidas) {
        final id = _id(registro)!;
        if (_excluido(registro)) {
          servidor.remove(id);
        } else if (_maisNovoOuIgual(registro, servidor[id])) {
          servidor[id] = registro;
        }
      }
    } else {
      servidor = {
        for (final r in recebidas)
          if (!_excluido(r)) _id(r)!: r,
      };
      await prefs.setString(_completaKey, agora.toIso8601String());
    }

    final novoCursor = _novoCursor(resposta, recebidas, cursor);
    if (novoCursor != null) {
      await prefs.setString(_cursorKey, novoCursor);
    } else {
      await prefs.remove(_cursorKey);
    }
    await prefs.setString(
      cacheRemessasKey,
      jsonEncode(servidor.values.toList()),
    );

    rel
      ..remessasRecebidas = recebidas.length
      ..incremental = incremental;
    return servidor;
  }

  /// Envia a fila offline aplicando as regras de conflito.
  Future<int> _enviarPendentes(
    Map<String, Map<String, dynamic>> servidor,
    SyncReport rel,
  ) async {
    final acoes = await _fila.listar();
    if (acoes.isEmpty) return 0;
    final removidas = <String>{};
    final atualizadas = <String, PendingAction>{};
    final remessasRejeitadas = <String>{};
    var enviadas = 0;

    for (final acao in acoes) {
      if (acao.requerIntervencao) {
        rel.acoesPrecisamIntervencao++;
        continue;
      }
      final agora = _relogio().toUtc();
      if (acao.proximaTentativa != null && acao.proximaTentativa!.isAfter(agora)) continue;
      final remessa = acao.remessaId;
      if (remessa != null && remessasRejeitadas.contains(remessa)) {
        removidas.add(acao.id);
        rel.acoesDescartadas++;
        continue;
      }

      if (acao.tipo == TipoAcao.aceitar && servidor.containsKey(remessa)) {
        // A remessa já aparece como sua: o aceite já foi processado.
        removidas.add(acao.id);
        continue;
      }

      if (acao.tipo == TipoAcao.status && acao.statusDesejado != null) {
        final registro = servidor[remessa];
        final decisao = resolver.resolverStatus(
          statusLocal: acao.statusDesejado!,
          alteradoEm: acao.criadoEm,
          statusServidor: registro?['status'] as String?,
          atualizadoServidor: _data(registro?['updated_at']),
          statusBase: acao.statusBase,
          atualizadoBase: acao.atualizadoBase,
        );
        if (decisao.conflito) {
          rel.conflitos++;
          await _registrarConflito(acao, registro?['status'], decisao);
        }
        if (!decisao.enviarLocal) {
          removidas.add(acao.id);
          rel.acoesDescartadas++;
          continue;
        }
      }

      try {
        await _api.requisicao(acao.metodo, acao.caminho, body: acao.corpo);
        removidas.add(acao.id);
        enviadas++;
      } on ApiConnectionException {
        break; // Sem conexão: mantém o restante na fila, na mesma ordem.
      } on ApiException catch (error) {
        final codigo = error.statusCode;
        if (codigo == 401) break;
        if (codigo != null && codigo >= 400 && codigo < 500 && codigo != 429) {
          // O servidor rejeitou a alteração (ex.: 409 conflito, 404, 422):
          // o estado do servidor prevalece.
          atualizadas[acao.id] = acao.exigirIntervencao(error.message);
          rel.acoesPrecisamIntervencao++;
        } else {
          atualizadas[acao.id] = acao.comNovaTentativa(agora: agora, erro: error.message);
        }
      }
    }

    await _fila.concluir(removidas: removidas, atualizadas: atualizadas);
    rel.acoesEnviadas += enviadas;
    return enviadas;
  }

  /// Envia apenas a fila offline, usando [servidor] como estado atual.
  Future<SyncReport> enviarPendentes(List<dynamic> servidor) async {
    final rel = SyncReport();
    await _enviarPendentes({
      for (final r in servidor.whereType<Map>())
        if (_id(r) != null) _id(r)!: Map<String, dynamic>.from(r),
    }, rel);
    await atualizarContadores();
    return rel;
  }

  Future<void> _enviarTodosOsPontos(SyncReport rel) async {
    // Limita o número de lotes por rodada para não bloquear a sincronização.
    for (var i = 0; i < 10; i++) {
      final enviados = await enviarPontos();
      rel.pontosEnviados += enviados;
      if (enviados < _loteDePontos) break;
    }
    await _pontos.limparSincronizados(
      antesDe: _relogio().toUtc().subtract(const Duration(days: 7)),
    );
  }

  /// Envia um lote de pontos de GPS pendentes. Retorna quantos foram aceitos.
  /// Envios concorrentes são serializados: quem chama durante um envio
  /// espera ele terminar e faz um novo, então nenhum ponto é enviado duas
  /// vezes e nenhuma chamada reaproveita uma tentativa que falhou antes.
  Future<int> enviarPontos() async {
    while (_enviandoPontos != null) {
      await _enviandoPontos!.catchError((_) => 0);
    }
    final envio = _enviarPontos();
    _enviandoPontos = envio;
    try {
      return await envio;
    } finally {
      _enviandoPontos = null;
    }
  }

  Future<int> _enviarPontos() async {
    final pendentes = await _pontos.pendentes(limite: _loteDePontos);
    final concluidos = <String>[];
    var aceitos = 0;
    for (final ponto in pendentes) {
      try {
        await _api.requisicao('POST', 'localizacao', body: ponto.toApi());
        concluidos.add(ponto.id);
        aceitos++;
      } on ApiConnectionException {
        break;
      } on ApiException catch (error) {
        final codigo = error.statusCode;
        if (codigo == 422 || codigo == 400) {
          // Ponto inválido para o servidor: não adianta reenviar.
          concluidos.add(ponto.id);
          continue;
        }
        break;
      }
    }
    await _pontos.marcarSincronizados(concluidos);
    return aceitos;
  }

  // ============================================================
  // ALTERAÇÕES OFFLINE
  // ============================================================

  /// Registra uma ação feita sem internet para envio posterior.
  Future<void> registrarAcaoOffline({
    required String tipo,
    required String metodo,
    required String caminho,
    required Object remessaId,
    Map<String, dynamic>? corpo,
  }) async {
    await _garantirDono();
    final id = '$remessaId';
    final base = (await _lerCache()).where((r) => _id(r) == id).firstOrNull;
    await _fila.adicionar(
      PendingAction(
        id: gerarIdLocal(),
        tipo: tipo,
        metodo: metodo,
        caminho: caminho,
        corpo: corpo,
        remessaId: id,
        statusBase: base?['status'] as String?,
        atualizadoBase: _data(base?['updated_at']),
        criadoEm: _relogio().toUtc(),
      ),
    );
    await atualizarContadores();
  }

  List<Map<String, dynamic>> _aplicarPendentes(
    List<Map<String, dynamic>> servidor,
    List<PendingAction> acoes,
  ) {
    final porId = {
      for (final r in servidor) _id(r)!: {...r},
    };
    for (final acao in acoes) {
      if (acao.tipo != TipoAcao.status || acao.statusDesejado == null) continue;
      final registro = porId[acao.remessaId];
      if (registro == null) continue;
      final decisao = resolver.resolverStatus(
        statusLocal: acao.statusDesejado!,
        alteradoEm: acao.criadoEm,
        statusServidor: registro['status'] as String?,
        atualizadoServidor: _data(registro['updated_at']),
        statusBase: acao.statusBase,
        atualizadoBase: acao.atualizadoBase,
      );
      if (decisao.enviarLocal) {
        registro['status'] = acao.statusDesejado;
        registro['pendente_sincronizacao'] = true;
      }
    }
    return porId.values.toList();
  }

  // ============================================================
  // AUTOMAÇÃO
  // ============================================================

  bool get _podeSincronizar =>
      AppSession.autenticada && AppSession.tipoUsuario == 'Motorista';

  /// Sincroniza periodicamente e sempre que o app volta ao primeiro plano.
  void iniciarAutomatico() {
    _timer?.cancel();
    _timer = Timer.periodic(intervaloAutomatico, (_) => _tentar());
    _ciclo?.dispose();
    _ciclo = AppLifecycleListener(onResume: _tentar);
    unawaited(_carregarEstado().then((_) => _tentar()));
  }

  void pararAutomatico() {
    _timer?.cancel();
    _timer = null;
    _ciclo?.dispose();
    _ciclo = null;
  }

  Future<void> _tentar() async {
    if (!_podeSincronizar || _emAndamento != null) return;
    try {
      await sincronizar();
    } on ApiException {
      // Estado já registra o erro; a próxima rodada tenta novamente.
    }
  }

  Future<void> _carregarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    estado.value = estado.value.copyWith(
      ultimaSincronizacao: DateTime.tryParse(prefs.getString(_ultimaKey) ?? ''),
    );
    await atualizarContadores();
  }

  Future<void> atualizarContadores() async {
    estado.value = estado.value.copyWith(
      acoesPendentes: await _fila.contar(),
      pontosPendentes: await _pontos.contarPendentes(),
      conflitos: (await _conflitos.listar()).length,
      acoesPrecisamIntervencao: (await _fila.quePrecisamIntervencao()).length,
    );
  }

  Future<List<PendingAction>> acoesParaRevisao() => _fila.quePrecisamIntervencao();

  Future<void> tentarAcaoNovamente(String id) async {
    await _fila.liberarParaNovaTentativa(id);
    await atualizarContadores();
    await sincronizar();
  }

  Future<void> removerAcaoPendente(String id) async {
    await _fila.remover(id);
    await atualizarContadores();
  }

  /// Apaga os dados locais quando outro usuário entra no aparelho, mas
  /// preserva o trabalho offline se o mesmo usuário só renovou o login.
  Future<void> _garantirDono() async {
    final prefs = await SharedPreferences.getInstance();
    final dono = AppSession.email.trim().toLowerCase();
    final anterior = prefs.getString(_donoKey);
    if (dono.isEmpty || anterior == dono) return;
    if (anterior != null) await limparDadosLocais();
    await prefs.setString(_donoKey, dono);
  }

  Future<void> limparDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    for (final chave in [
      cacheRemessasKey,
      _cursorKey,
      _completaKey,
      _ultimaKey,
      _donoKey,
    ]) {
      await prefs.remove(chave);
    }
    await _fila.limpar();
    await _pontos.limparTudo();
    await _conflitos.limpar();
    estado.value = const SyncState();
  }

  // ============================================================
  // AUXILIARES
  // ============================================================

  Future<void> _registrarConflito(
    PendingAction acao,
    Object? valorServidor,
    ResolucaoConflito decisao,
  ) => _conflitos.registrar(
    ConflictRecord(
      remessaId: acao.remessaId,
      campo: acao.tipo == TipoAcao.aceitar ? 'aceite' : 'status',
      valorLocal: acao.statusDesejado ?? acao.tipo,
      valorServidor: valorServidor?.toString(),
      vencedorLocal: decisao.enviarLocal,
      motivo: decisao.motivo,
      resolvidoEm: _relogio().toUtc(),
    ),
  );

  Future<List<Map<String, dynamic>>> _lerCache() async {
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(cacheRemessasKey);
    if (salvo == null) return [];
    try {
      final decoded = jsonDecode(salvo);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .where((r) => _id(r) != null)
          .toList();
    } on FormatException {
      return [];
    }
  }

  static String? _id(Map registro) {
    final id = registro['id'] ?? registro['remessa_id'];
    return id?.toString();
  }

  static DateTime? _data(Object? valor) =>
      valor == null ? null : DateTime.tryParse('$valor')?.toUtc();

  static bool _excluido(Map registro) =>
      registro['deleted_at'] != null || registro['excluido'] == true;

  static bool _maisNovoOuIgual(Map novo, Map? atual) {
    if (atual == null) return true;
    final dataNova = _data(novo['updated_at']);
    final dataAtual = _data(atual['updated_at']);
    if (dataNova == null || dataAtual == null) return true;
    return !dataNova.isBefore(dataAtual);
  }

  String? _novoCursor(
    Object? resposta,
    List<Map<String, dynamic>> recebidas,
    String? anterior,
  ) {
    if (resposta is Map) {
      final meta = resposta['meta'];
      final horaServidor =
          resposta['server_time'] ?? (meta is Map ? meta['server_time'] : null);
      final data = _data(horaServidor);
      if (data != null) return data.toIso8601String();
    }
    DateTime? maior = _data(anterior);
    for (final registro in recebidas) {
      final data = _data(registro['updated_at']);
      if (data != null && (maior == null || data.isAfter(maior))) maior = data;
    }
    return maior?.toIso8601String();
  }
}
