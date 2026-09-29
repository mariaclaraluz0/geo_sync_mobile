import 'dart:convert';
import 'dart:io';

/// Servidor HTTP local que imita os endpoints da API Laravel usados pela
/// sincronização. Roda em `127.0.0.1` numa porta livre, então os testes
/// exercitam o cliente HTTP real, a serialização e o tratamento de erros.
class FakeApiServer {
  FakeApiServer._(this._server);

  final HttpServer _server;

  /// Remessas do motorista, por id.
  final remessas = <String, Map<String, dynamic>>{};

  /// Pontos recebidos em `POST /localizacao`.
  final localizacoes = <Map<String, dynamic>>[];

  /// Todas as requisições recebidas (`METODO caminho?query`).
  final requisicoes = <String>[];

  /// Força uma resposta para `METODO caminho` (ex.: 409 no PATCH de status).
  final respostasForcadas = <String, int>{};

  /// Relógio do servidor, controlado pelos testes.
  DateTime agora = DateTime.now().toUtc().subtract(const Duration(hours: 1));

  /// Quando `false`, ignora `updated_since` e devolve sempre tudo, como uma
  /// API que ainda não implementa sincronização incremental.
  bool suportaIncremental = true;

  String get baseUrl => 'http://127.0.0.1:${_server.port}/api';

  static Future<FakeApiServer> iniciar() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeApiServer._(server);
    server.listen(fake._tratar);
    return fake;
  }

  Future<void> fechar() => _server.close(force: true);

  void avancar(Duration duracao) => agora = agora.add(duracao);

  void salvarRemessa(Map<String, dynamic> remessa) {
    final id = '${remessa['id']}';
    remessas[id] = {...remessa, 'updated_at': agora.toIso8601String()};
  }

  Future<void> _tratar(HttpRequest req) async {
    final caminho = req.uri.path.replaceFirst('/api/', '');
    final descricao =
        '${req.method} $caminho${req.uri.hasQuery ? '?${req.uri.query}' : ''}';
    requisicoes.add(descricao);

    final corpoTexto = await utf8.decoder.bind(req).join();
    final corpo = corpoTexto.isEmpty ? null : jsonDecode(corpoTexto);

    if (req.headers.value('authorization') != 'Bearer token-teste') {
      return _responder(req, 401, {'message': 'Unauthenticated.'});
    }
    final forcada = respostasForcadas['${req.method} $caminho'];
    if (forcada != null) {
      return _responder(req, forcada, {
        'message': 'A remessa foi alterada por outro usuário.',
      });
    }

    final partes = caminho.split('/');
    if (req.method == 'GET' && caminho == 'remessas/minhas') {
      final desde = DateTime.tryParse(
        req.uri.queryParameters['updated_since'] ?? '',
      );
      final lista = remessas.values.where((r) {
        if (!suportaIncremental || desde == null) return true;
        return DateTime.parse(r['updated_at'] as String).isAfter(desde);
      }).toList();
      return _responder(req, 200, {
        'data': lista,
        'meta': {'server_time': agora.toIso8601String()},
      });
    }
    if (req.method == 'PATCH' &&
        partes.length == 3 &&
        partes[0] == 'remessas' &&
        partes[2] == 'status') {
      final remessa = remessas[partes[1]];
      if (remessa == null) {
        return _responder(req, 404, {'message': 'Não encontrada'});
      }
      avancar(const Duration(seconds: 1));
      salvarRemessa({...remessa, 'status': (corpo as Map)['status']});
      return _responder(req, 200, {'data': remessas[partes[1]]});
    }
    if (req.method == 'POST' &&
        partes.length == 3 &&
        partes[0] == 'remessas' &&
        partes[2] == 'aceitar') {
      avancar(const Duration(seconds: 1));
      salvarRemessa({
        'id': int.tryParse(partes[1]) ?? partes[1],
        'codigo': 'GS-${partes[1]}',
        'status': 'Aguardando coleta',
      });
      return _responder(req, 200, {'data': remessas[partes[1]]});
    }
    if (req.method == 'POST' && caminho == 'localizacao') {
      final ponto = Map<String, dynamic>.from(corpo as Map);
      if (ponto['latitude'] is! num || ponto['longitude'] is! num) {
        return _responder(req, 422, {'message': 'Coordenadas inválidas'});
      }
      // Idempotente pelo client_id, como recomendado para o backend.
      final duplicado = localizacoes.any(
        (p) => p['client_id'] == ponto['client_id'],
      );
      if (!duplicado) localizacoes.add(ponto);
      return _responder(req, 201, {'data': ponto});
    }
    return _responder(req, 404, {'message': 'Rota não encontrada'});
  }

  Future<void> _responder(HttpRequest req, int status, Object corpo) async {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(corpo));
    await req.response.close();
  }
}
