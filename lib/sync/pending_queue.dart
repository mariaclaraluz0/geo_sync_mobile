import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';

/// Tipos de ação que o motorista pode fazer sem internet.
class TipoAcao {
  TipoAcao._();

  static const status = 'status';
  static const aceitar = 'aceitar';

  /// Ações gravadas por versões antigas do app, sem metadados.
  static const generica = 'generica';
}

/// Uma requisição feita offline, aguardando para ser reenviada.
class PendingAction {
  const PendingAction({
    required this.id,
    required this.metodo,
    required this.caminho,
    required this.criadoEm,
    this.tipo = TipoAcao.generica,
    this.corpo,
    this.remessaId,
    this.statusBase,
    this.atualizadoBase,
    this.tentativas = 0,
    this.proximaTentativa,
    this.requerIntervencao = false,
    this.ultimoErro,
  });

  final String id;
  final String tipo;
  final String metodo;
  final String caminho;
  final Map<String, dynamic>? corpo;
  final String? remessaId;

  /// Status que o aparelho conhecia no momento da alteração.
  final String? statusBase;

  /// `updated_at` do servidor que o aparelho conhecia na alteração.
  final DateTime? atualizadoBase;
  final DateTime criadoEm;
  final int tentativas;
  final DateTime? proximaTentativa;
  final bool requerIntervencao;
  final String? ultimoErro;

  String? get statusDesejado => corpo?['status'] as String?;

  PendingAction comNovaTentativa({required DateTime agora, String? erro}) => PendingAction(
    id: id,
    tipo: tipo,
    metodo: metodo,
    caminho: caminho,
    corpo: corpo,
    remessaId: remessaId,
    statusBase: statusBase,
    atualizadoBase: atualizadoBase,
    criadoEm: criadoEm,
    tentativas: tentativas + 1,
    proximaTentativa: agora.add(Duration(seconds: (30 * (1 << tentativas.clamp(0, 6))).clamp(30, 1800).toInt())),
    ultimoErro: erro,
  );

  PendingAction exigirIntervencao(String erro) => PendingAction(
    id: id, tipo: tipo, metodo: metodo, caminho: caminho, corpo: corpo,
    remessaId: remessaId, statusBase: statusBase,
    atualizadoBase: atualizadoBase, criadoEm: criadoEm, tentativas: tentativas + 1,
    requerIntervencao: true, ultimoErro: erro,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    // Nomes antigos mantidos para compatibilidade com a fila anterior.
    'method': metodo,
    'path': caminho,
    'body': corpo,
    'remessa_id': remessaId,
    'status_base': statusBase,
    'atualizado_base': atualizadoBase?.toIso8601String(),
    'criado_em': criadoEm.toIso8601String(),
    'tentativas': tentativas,
    'proxima_tentativa': proximaTentativa?.toIso8601String(),
    'requer_intervencao': requerIntervencao,
    'ultimo_erro': ultimoErro,
  };

  static PendingAction? fromJson(Map<String, dynamic> json) {
    final metodo = json['method'];
    final caminho = json['path'];
    if (metodo is! String || caminho is! String) return null;
    final corpo = json['body'];
    return PendingAction(
      id: json['id'] is String ? json['id'] as String : gerarIdLocal(),
      tipo: json['tipo'] is String ? json['tipo'] as String : TipoAcao.generica,
      metodo: metodo,
      caminho: caminho,
      corpo: corpo is Map ? Map<String, dynamic>.from(corpo) : null,
      remessaId: json['remessa_id']?.toString(),
      statusBase: json['status_base'] as String?,
      atualizadoBase: DateTime.tryParse('${json['atualizado_base']}'),
      criadoEm:
          DateTime.tryParse('${json['criado_em']}')?.toUtc() ??
          DateTime.now().toUtc(),
      tentativas: json['tentativas'] is int ? json['tentativas'] as int : 0,
      proximaTentativa: DateTime.tryParse('${json['proxima_tentativa']}'),
      requerIntervencao: json['requer_intervencao'] == true,
      ultimoErro: json['ultimo_erro'] as String?,
    );
  }
}

/// Fila persistente de ações offline, na ordem em que foram feitas.
class PendingQueue {
  PendingQueue() : _store = JsonListStore('motorista_acoes_pendentes');

  static final instance = PendingQueue();

  final JsonListStore _store;

  Future<List<PendingAction>> listar() async =>
      (await _store.ler()).map(PendingAction.fromJson).nonNulls.toList();

  Future<int> contar() async => (await _store.ler()).length;

  Future<List<PendingAction>> quePrecisamIntervencao() async =>
      (await listar()).where((acao) => acao.requerIntervencao).toList();

  Future<void> liberarParaNovaTentativa(String id) => _store.atualizar((itens) {
    final indice = itens.indexWhere((item) => item['id'] == id);
    if (indice < 0) return;
    final acao = PendingAction.fromJson(itens[indice]);
    if (acao == null) return;
    itens[indice] = PendingAction(
      id: acao.id, tipo: acao.tipo, metodo: acao.metodo, caminho: acao.caminho,
      corpo: acao.corpo, remessaId: acao.remessaId, statusBase: acao.statusBase,
      atualizadoBase: acao.atualizadoBase, criadoEm: acao.criadoEm,
      tentativas: acao.tentativas,
    ).toJson();
  });

  Future<void> remover(String id) => _store.atualizar((itens) {
    itens.removeWhere((item) => item['id'] == id);
  });

  Future<void> adicionar(PendingAction acao) => _store.atualizar((itens) {
    // Uma nova mudança de status substitui a anterior da mesma remessa,
    // mantendo o status base original para detectar conflitos corretamente.
    if (acao.tipo == TipoAcao.status && acao.remessaId != null) {
      final indice = itens.indexWhere(
        (item) =>
            item['tipo'] == TipoAcao.status &&
            item['remessa_id']?.toString() == acao.remessaId,
      );
      if (indice >= 0) {
        final anterior = PendingAction.fromJson(itens[indice]);
        itens[indice] = PendingAction(
          id: acao.id,
          tipo: acao.tipo,
          metodo: acao.metodo,
          caminho: acao.caminho,
          corpo: acao.corpo,
          remessaId: acao.remessaId,
          statusBase: anterior?.statusBase ?? acao.statusBase,
          atualizadoBase: anterior?.atualizadoBase ?? acao.atualizadoBase,
          criadoEm: acao.criadoEm,
        ).toJson();
        return;
      }
    }
    itens.add(acao.toJson());
  });

  /// Substitui a fila inteira (usado ao final de cada sincronização).
  Future<void> substituir(List<PendingAction> acoes) =>
      _store.gravar(acoes.map((a) => a.toJson()).toList());

  /// Remove da fila as ações processadas, preservando as que foram
  /// adicionadas enquanto a sincronização estava em andamento.
  Future<void> concluir({
    required Set<String> removidas,
    required Map<String, PendingAction> atualizadas,
  }) => _store.atualizar((itens) {
    itens.removeWhere((item) => removidas.contains(item['id']));
    for (var i = 0; i < itens.length; i++) {
      final nova = atualizadas[itens[i]['id']];
      if (nova != null) itens[i] = nova.toJson();
    }
  });

  Future<void> limpar() => _store.gravar([]);
}

/// Registro de um conflito resolvido, exibido ao motorista.
class ConflictRecord {
  const ConflictRecord({
    required this.remessaId,
    required this.campo,
    required this.valorLocal,
    required this.valorServidor,
    required this.vencedorLocal,
    required this.motivo,
    required this.resolvidoEm,
  });

  final String? remessaId;
  final String campo;
  final String? valorLocal;
  final String? valorServidor;
  final bool vencedorLocal;
  final String motivo;
  final DateTime resolvidoEm;

  Map<String, dynamic> toJson() => {
    'remessa_id': remessaId,
    'campo': campo,
    'valor_local': valorLocal,
    'valor_servidor': valorServidor,
    'vencedor_local': vencedorLocal,
    'motivo': motivo,
    'resolvido_em': resolvidoEm.toIso8601String(),
  };

  static ConflictRecord? fromJson(Map<String, dynamic> json) {
    final data = DateTime.tryParse('${json['resolvido_em']}');
    if (data == null) return null;
    return ConflictRecord(
      remessaId: json['remessa_id']?.toString(),
      campo: '${json['campo'] ?? 'status'}',
      valorLocal: json['valor_local']?.toString(),
      valorServidor: json['valor_servidor']?.toString(),
      vencedorLocal: json['vencedor_local'] == true,
      motivo: '${json['motivo'] ?? ''}',
      resolvidoEm: data,
    );
  }
}

/// Histórico dos últimos conflitos resolvidos automaticamente.
class ConflictLog {
  ConflictLog({this.limite = 100})
    : _store = JsonListStore('geosync_conflitos');

  static final instance = ConflictLog();

  final int limite;
  final JsonListStore _store;

  Future<void> registrar(ConflictRecord registro) => _store.atualizar((itens) {
    itens.insert(0, registro.toJson());
    if (itens.length > limite) itens.removeRange(limite, itens.length);
  });

  /// Mais recentes primeiro.
  Future<List<ConflictRecord>> listar() async =>
      (await _store.ler()).map(ConflictRecord.fromJson).nonNulls.toList();

  Future<void> limpar() => _store.gravar([]);
}
