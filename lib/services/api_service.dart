import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente da API Laravel.
///
/// Em celular físico, defina a URL com o IP do computador, por exemplo:
/// `flutter run --dart-define=API_BASE_URL=http://IP-DO-SERVIDOR:PORTA/api`
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _baseUrlPreferenceKey = 'api_base_url';
  // A URL de produção deve ser fornecida no build, por exemplo:
  // --dart-define=API_BASE_URL=https://api.exemplo.com/api
  // Em desenvolvimento ela também pode ser configurada na tela de conexão.
  static const _defaultBaseUrl = '';
  static String _savedBaseUrl = '';
  static List<dynamic>? _pagamentosCache;
  static DateTime? _pagamentosCacheAt;
  static List<dynamic>? _remessasCache;
  static DateTime? _remessasCacheAt;
  static List<dynamic>? _alertasCache;
  static DateTime? _alertasCacheAt;

  static Future<void> restoreBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    _savedBaseUrl = preferences.getString(_baseUrlPreferenceKey) ?? '';
  }

  static Future<void> saveBaseUrl(String value) async {
    final normalized = _normalizeBaseUrl(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlPreferenceKey, normalized);
    _savedBaseUrl = normalized;
  }

  static String _normalizeBaseUrl(String value) {
    final url = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiException(
        'Informe a URL da API, por exemplo http://IP-DO-SERVIDOR:8000/api.',
      );
    }
    final pathSegments = [...uri.pathSegments];
    if (pathSegments.isEmpty || pathSegments.last.toLowerCase() != 'api') {
      pathSegments.add('api');
    }
    return uri.replace(pathSegments: pathSegments).toString();
  }

  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl);
    }
    if (_savedBaseUrl.isNotEmpty) return _savedBaseUrl;
    if (_defaultBaseUrl.isNotEmpty) return _defaultBaseUrl;
    throw const ApiException(
      'A URL da API não foi configurada. Informe API_BASE_URL ou configure-a no aplicativo.',
    );
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(_normalizeBaseUrl(baseUrl));
    final endpointSegments = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    return Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.port,
      pathSegments: [...base.pathSegments, ...endpointSegments],
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Map<String, String> _headers({bool authenticated = false}) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authenticated && AppSession.token.isNotEmpty)
      'Authorization': 'Bearer ${AppSession.token}',
  };

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool authenticated = false,
  }) async {
    try {
      final uri = _uri(path, query);
      debugPrint('[API] $method $uri');
      final request = http.Request(method, uri);
      request.headers.addAll(_headers(authenticated: authenticated));
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamed);
      dynamic data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } on FormatException {
          data = response.body;
        }
      }
      if (data is String &&
          response.headers['content-type']?.contains('text/html') == true) {
        throw ApiConnectionException(
          'A URL configurada não é uma API JSON: $baseUrl. '
          'Verifique o IP, a porta e o caminho /api do servidor Laravel.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[API] $method $uri -> ${response.statusCode}');
        if (response.statusCode == 401 && authenticated) {
          await AppSession.encerrarSessao();
        }
        throw ApiException(_messageFrom(data), statusCode: response.statusCode);
      }
      return data;
    } on ApiException {
      rethrow;
    } on http.ClientException catch (error) {
      debugPrint('[API] connection error: $error');
      throw ApiConnectionException(
        'Não foi possível acessar $baseUrl. Confirme que o Laravel está em execução e a URL está correta.',
      );
    } on TimeoutException {
      throw ApiConnectionException(
        'O servidor $baseUrl demorou para responder. Verifique a rede e o Laravel.',
      );
    } catch (error) {
      debugPrint('[API] unexpected error: $error');
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique a URL da API e sua rede.',
      );
    }
  }

  String _messageFrom(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return '${entry.key}: ${value.first}';
          }
          if (value is String && value.isNotEmpty) {
            return '${entry.key}: $value';
          }
        }
      }
    }
    return 'Não foi possível concluir a solicitação.';
  }

  Map<String, dynamic> _map(dynamic response) =>
      response is Map<String, dynamic> ? response : <String, dynamic>{};

  /// Normaliza respostas como `{token: ...}` e `{data: {token: ...}}`.
  Map<String, dynamic> authData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  String? authToken(Map<String, dynamic> response) {
    const tokenKeys = {'token', 'access_token', 'accessToken', 'jwt'};

    String? findToken(dynamic value) {
      if (value is Map) {
        for (final key in tokenKeys) {
          final candidate = value[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate.trim();
          }
        }
        for (final nested in value.values) {
          final token = findToken(nested);
          if (token != null) return token;
        }
      }
      return null;
    }

    return findToken(response);
  }

  Map<String, dynamic> authUser(Map<String, dynamic> response) {
    Map<String, dynamic>? findUser(dynamic value) {
      if (value is Map) {
        for (final key in ['user', 'usuario', 'account']) {
          final candidate = value[key];
          if (candidate is Map) {
            return Map<String, dynamic>.from(candidate);
          }
        }
        for (final nested in value.values) {
          final user = findUser(nested);
          if (user != null) return user;
        }
        if (value.containsKey('email') ||
            value.containsKey('name') ||
            value.containsKey('nome')) {
          return Map<String, dynamic>.from(value);
        }
      }
      return null;
    }

    return findUser(response) ?? <String, dynamic>{};
  }

  List<dynamic> _list(dynamic response) {
    if (response is List) return response;
    final map = _map(response);
    final data = map['data'];
    if (data is List) return data;
    if (data is Map) {
      final nested = data['data'];
      if (nested is List) return nested;
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async => _map(
    await _request(
      'POST',
      'auth/login',
      body: {'email': email.trim(), 'password': password},
    ),
  );

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
    required String userType,
  }) async => _map(
    await _request(
      'POST',
      'auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'cpf': cpf.trim(),
        'telefone': phone.trim(),
        'password': password,
        'password_confirmation': password,
        'tipo': userType.toLowerCase(),
      },
    ),
  );

  Future<Map<String, dynamic>> criarContato({
    required String mensagem,
    required String canal,
  }) async => _map(
    await _request(
      'POST',
      'contatos',
      body: {'mensagem': mensagem.trim(), 'canal': canal},
    ),
  );

  Future<Map<String, dynamic>> me() async =>
      _map(await _request('GET', 'auth/me', authenticated: true));

  Future<void> logout() async {
    await _request('POST', 'auth/logout', authenticated: true);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async =>
      _map(await _request('PUT', 'perfil', body: data, authenticated: true));

  Future<List<dynamic>> minhasRemessas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValido(_remessasCacheAt, _remessasCache)) {
      return List<dynamic>.from(_remessasCache!);
    }
    List<dynamic> remessas;
    try {
      remessas = _list(
        await _request('GET', 'remessas/minhas', authenticated: true),
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('motorista_remessas_cache', jsonEncode(remessas));
    } on ApiConnectionException {
      final preferences = await SharedPreferences.getInstance();
      final cached = preferences.getString('motorista_remessas_cache');
      if (cached == null) rethrow;
      final decoded = jsonDecode(cached);
      if (decoded is! List) rethrow;
      remessas = decoded;
    }
    _remessasCache = List<dynamic>.from(remessas);
    _remessasCacheAt = DateTime.now();
    return remessas;
  }

  Future<List<dynamic>> remessasDisponiveis() async =>
      _list(await _request('GET', 'remessas/disponiveis', authenticated: true));
  Future<Map<String, dynamic>> aceitarRemessa(Object id) async {
    final resposta = _map(
      await _request('POST', 'remessas/$id/aceitar', authenticated: true),
    );
    _remessasCache = null;
    _remessasCacheAt = null;
    return resposta;
  }

  Future<Map<String, dynamic>> atualizarStatusRemessa(
    Object id,
    String status,
  ) async {
    final resposta = _map(
      await _request(
        'PATCH',
        'remessas/$id/status',
        body: {'status': status},
        authenticated: true,
      ),
    );
    _remessasCache = null;
    _remessasCacheAt = null;
    return resposta;
  }

  Future<List<dynamic>> remessas() async =>
      _list(await _request('GET', 'remessas', authenticated: true));
  Future<Map<String, dynamic>> remessa(Object id) async =>
      _map(await _request('GET', 'remessas/$id', authenticated: true));
  Future<Map<String, dynamic>> criarRemessa(Map<String, dynamic> data) async {
    final resposta = _map(
      await _request('POST', 'remessas', body: data, authenticated: true),
    );
    _remessasCache = null;
    _remessasCacheAt = null;
    return resposta;
  }

  Future<Map<String, dynamic>> atualizarRemessa(
    Object id,
    Map<String, dynamic> data,
  ) async {
    final resposta = _map(
      await _request('PUT', 'remessas/$id', body: data, authenticated: true),
    );
    _remessasCache = null;
    _remessasCacheAt = null;
    return resposta;
  }

  Future<void> excluirRemessa(Object id) async {
    await _request('DELETE', 'remessas/$id', authenticated: true);
    _remessasCache = null;
    _remessasCacheAt = null;
  }

  Future<List<dynamic>> alertas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValido(_alertasCacheAt, _alertasCache)) {
      return List<dynamic>.from(_alertasCache!);
    }
    final alertas = _list(
      await _request('GET', 'alertas', authenticated: true),
    );
    _alertasCache = List<dynamic>.from(alertas);
    _alertasCacheAt = DateTime.now();
    return alertas;
  }

  bool _cacheValido(DateTime? criadoEm, List<dynamic>? dados) =>
      dados != null &&
      criadoEm != null &&
      DateTime.now().difference(criadoEm) < const Duration(seconds: 30);
  Future<Map<String, dynamic>> alerta(Object id) async =>
      _map(await _request('GET', 'alertas/$id', authenticated: true));
  Future<Map<String, dynamic>> criarAlerta(Map<String, dynamic> data) async {
    final resposta = _map(
      await _request('POST', 'alertas', body: data, authenticated: true),
    );
    _alertasCache = null;
    _alertasCacheAt = null;
    return resposta;
  }

  Future<Map<String, dynamic>> atualizarAlerta(
    Object id,
    Map<String, dynamic> data,
  ) async {
    final resposta = _map(
      await _request('PUT', 'alertas/$id', body: data, authenticated: true),
    );
    _alertasCache = null;
    _alertasCacheAt = null;
    return resposta;
  }

  Future<void> excluirAlerta(Object id) async {
    await _request('DELETE', 'alertas/$id', authenticated: true);
    _alertasCache = null;
    _alertasCacheAt = null;
  }

  /// Avisos específicos do motorista. O backend deve retornar uma lista em
  /// `data` ou diretamente, com id, titulo, descricao, lido e created_at.
  Future<List<dynamic>> avisosMotorista({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValido(_alertasCacheAt, _alertasCache)) {
      return List<dynamic>.from(_alertasCache!);
    }
    final avisos = _list(
      await _request('GET', 'motorista/avisos', authenticated: true),
    );
    _alertasCache = List<dynamic>.from(avisos);
    _alertasCacheAt = DateTime.now();
    return avisos;
  }

  Future<void> marcarAvisoComoLido(Object id) async {
    await _request('PATCH', 'motorista/avisos/$id/lido', authenticated: true);
    _alertasCache = null;
    _alertasCacheAt = null;
  }

  Future<void> marcarTodosAvisosComoLidos() async {
    await _request('PATCH', 'motorista/avisos/lidos', authenticated: true);
    _alertasCache = null;
    _alertasCacheAt = null;
  }

  /// Envia CNH ou CRLV em multipart/form-data.
  Future<Map<String, dynamic>> enviarDocumentoMotorista({
    required String tipo,
    required String caminhoArquivo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('motorista/documentos/$tipo'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (AppSession.token.isNotEmpty) 'Authorization': 'Bearer ${AppSession.token}',
    });
    request.files.add(await http.MultipartFile.fromPath('arquivo', caminhoArquivo));
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_messageFrom(data), statusCode: response.statusCode);
      }
      return _map(data);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('[API] document upload error: $error');
      throw const ApiConnectionException('Não foi possível enviar o documento.');
    }
  }

  Future<List<dynamic>> pagamentos({bool forceRefresh = false}) async {
    final cacheAt = _pagamentosCacheAt;
    if (!forceRefresh &&
        _pagamentosCache != null &&
        cacheAt != null &&
        DateTime.now().difference(cacheAt) < const Duration(seconds: 30)) {
      return List<dynamic>.from(_pagamentosCache!);
    }
    final pagamentos = _list(
      await _request('GET', 'pagamentos', authenticated: true),
    );
    _pagamentosCache = List<dynamic>.from(pagamentos);
    _pagamentosCacheAt = DateTime.now();
    return pagamentos;
  }

  Future<Map<String, dynamic>> criarPagamento(Map<String, dynamic> data) async {
    final resposta = _map(
      await _request('POST', 'pagamentos', body: data, authenticated: true),
    );
    _pagamentosCache = null;
    _pagamentosCacheAt = null;
    return resposta;
  }

  Future<Map<String, dynamic>> pagamento(Object id) async =>
      _map(await _request('GET', 'pagamentos/$id', authenticated: true));

  Future<List<dynamic>> avaliacoes() async =>
      _list(await _request('GET', 'avaliacoes'));
  Future<Map<String, dynamic>> resumoAvaliacoes() async =>
      _map(await _request('GET', 'avaliacoes/resumo'));
  Future<Map<String, dynamic>> criarAvaliacao(
    Map<String, dynamic> data,
  ) async => _map(
    await _request('POST', 'avaliacoes', body: data, authenticated: true),
  );

  Future<List<dynamic>> localizacoes() async =>
      _list(await _request('GET', 'localizacao'));
  Future<List<dynamic>> localizacoesPorRemessa(Object remessaId) async =>
      _list(await _request('GET', 'localizacao/remessa/$remessaId'));
  Future<Map<String, dynamic>> ultimaLocalizacaoPorRemessa(
    Object remessaId,
  ) async =>
      _map(await _request('GET', 'localizacao/remessa/$remessaId/ultima'));
  Future<Map<String, dynamic>> localizacao(Object id) async =>
      _map(await _request('GET', 'localizacao/$id'));
  Future<Map<String, dynamic>> enviarLocalizacao(
    Map<String, dynamic> data,
  ) async => _map(
    await _request('POST', 'localizacao', body: data, authenticated: true),
  );
  Future<Map<String, dynamic>> atualizarLocalizacao(
    Object id,
    Map<String, dynamic> data,
  ) async => _map(await _request('PUT', 'localizacao/$id', body: data));
  Future<void> excluirLocalizacao(Object id) async =>
      _request('DELETE', 'localizacao/$id');
}
