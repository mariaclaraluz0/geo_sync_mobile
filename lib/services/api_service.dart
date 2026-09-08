import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';

/// Cliente da API Laravel.
///
/// Defina a URL ao executar o app, por exemplo:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  Uri _uri(String path, [Map<String, dynamic>? query]) => Uri.parse(
    '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}',
  ).replace(queryParameters: query?.map((key, value) => MapEntry(key, '$value')));

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
      final request = http.Request(method, _uri(path, query));
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
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_messageFrom(data), statusCode: response.statusCode);
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
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
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return '${value.first}';
        }
      }
    }
    return 'Não foi possível concluir a solicitação.';
  }

  Map<String, dynamic> _map(dynamic response) =>
      response is Map<String, dynamic> ? response : <String, dynamic>{};

  List<dynamic> _list(dynamic response) {
    if (response is List) return response;
    final map = _map(response);
    return map['data'] is List ? map['data'] as List : <dynamic>[];
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
        'telefone': phone.trim(),
        'password': password,
        'password_confirmation': password,
        'tipo_usuario': userType.toLowerCase(),
      },
    ),
  );

  Future<Map<String, dynamic>> me() async =>
      _map(await _request('GET', 'auth/me', authenticated: true));

  Future<void> logout() async {
    await _request('POST', 'auth/logout', authenticated: true);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async =>
      _map(await _request('PUT', 'perfil', body: data, authenticated: true));

  Future<List<dynamic>> minhasRemessas() async =>
      _list(await _request('GET', 'remessas/minhas', authenticated: true));
  Future<List<dynamic>> remessasDisponiveis() async =>
      _list(await _request('GET', 'remessas/disponiveis', authenticated: true));
  Future<Map<String, dynamic>> aceitarRemessa(Object id) async =>
      _map(await _request('POST', 'remessas/$id/aceitar', authenticated: true));
  Future<Map<String, dynamic>> atualizarStatusRemessa(
    Object id,
    String status,
  ) async => _map(
    await _request(
      'PATCH',
      'remessas/$id/status',
      body: {'status': status},
      authenticated: true,
    ),
  );
  Future<List<dynamic>> remessas() async =>
      _list(await _request('GET', 'remessas', authenticated: true));
  Future<Map<String, dynamic>> remessa(Object id) async =>
      _map(await _request('GET', 'remessas/$id', authenticated: true));
  Future<Map<String, dynamic>> criarRemessa(Map<String, dynamic> data) async =>
      _map(await _request('POST', 'remessas', body: data, authenticated: true));
  Future<Map<String, dynamic>> atualizarRemessa(
    Object id,
    Map<String, dynamic> data,
  ) async => _map(
    await _request('PUT', 'remessas/$id', body: data, authenticated: true),
  );
  Future<void> excluirRemessa(Object id) async =>
      _request('DELETE', 'remessas/$id', authenticated: true);

  Future<List<dynamic>> alertas() async =>
      _list(await _request('GET', 'alertas', authenticated: true));
  Future<Map<String, dynamic>> alerta(Object id) async =>
      _map(await _request('GET', 'alertas/$id', authenticated: true));
  Future<Map<String, dynamic>> criarAlerta(Map<String, dynamic> data) async =>
      _map(await _request('POST', 'alertas', body: data, authenticated: true));
  Future<Map<String, dynamic>> atualizarAlerta(
    Object id,
    Map<String, dynamic> data,
  ) async => _map(
    await _request('PUT', 'alertas/$id', body: data, authenticated: true),
  );
  Future<void> excluirAlerta(Object id) async =>
      _request('DELETE', 'alertas/$id', authenticated: true);

  Future<List<dynamic>> pagamentos() async =>
      _list(await _request('GET', 'pagamentos', authenticated: true));
  Future<Map<String, dynamic>> criarPagamento(
    Map<String, dynamic> data,
  ) async => _map(
    await _request('POST', 'pagamentos', body: data, authenticated: true),
  );
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
  ) async => _map(await _request('POST', 'localizacao', body: data));
  Future<Map<String, dynamic>> atualizarLocalizacao(
    Object id,
    Map<String, dynamic> data,
  ) async => _map(await _request('PUT', 'localizacao/$id', body: data));
  Future<void> excluirLocalizacao(Object id) async =>
      _request('DELETE', 'localizacao/$id');
}
