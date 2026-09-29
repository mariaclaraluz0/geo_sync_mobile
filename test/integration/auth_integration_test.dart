import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/main.dart' show validarSessao;
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_server.dart';

/// Autenticação ponta a ponta: cliente HTTP real + ApiService + AppSession
/// contra o servidor HTTP local.
void main() {
  late FakeApiServer servidor;
  const semConexao = 'http://127.0.0.1:1/api';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = await FakeApiServer.iniciar();
    await AppSession.encerrarSessao();
    await ApiService.saveBaseUrl(servidor.baseUrl);
  });

  tearDown(() => servidor.fechar());

  Future<void> entrar() async {
    final resposta = await ApiService.instance.login(
      email: 'motorista@geosync.com',
      password: 'segredo123',
    );
    final usuario = ApiService.instance.authUser(resposta);
    await AppSession.iniciarSessao(
      token: ApiService.instance.authToken(resposta)!,
      tipoUsuario: 'Motorista',
      email: '${usuario['email']}',
      nome: '${usuario['name']}',
    );
  }

  test('login válido cria a sessão e a persiste entre reinícios', () async {
    await entrar();
    expect(AppSession.autenticada, isTrue);
    expect(AppSession.nome, 'Motorista Teste');

    await AppSession.restaurar();
    expect(AppSession.token, 'token-teste');
    expect(AppSession.tipoUsuario, 'Motorista');
    expect(AppSession.email, 'motorista@geosync.com');
  });

  test('senha errada é recusada e não cria sessão', () async {
    await expectLater(
      ApiService.instance.login(
        email: 'motorista@geosync.com',
        password: 'errada',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
    expect(AppSession.autenticada, isFalse);
  });

  test('requisições autenticadas enviam o token Bearer', () async {
    await entrar();
    await SyncEngine.instance.sincronizar();
    expect(servidor.requisicoes, contains('GET remessas/minhas'));
  });

  test('token expirado encerra a sessão automaticamente', () async {
    await entrar();
    servidor.tokenRevogado = true;

    await expectLater(
      SyncEngine.instance.sincronizar(),
      throwsA(isA<ApiException>()),
    );
    expect(AppSession.autenticada, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
  });

  test('ao abrir o app, a sessão é validada e os dados atualizados', () async {
    await entrar();
    await AppSession.atualizarDadosUsuario(
      nome: 'Nome Antigo',
      email: 'motorista@geosync.com',
    );

    await validarSessao();

    expect(AppSession.autenticada, isTrue);
    expect(AppSession.nome, 'Motorista Teste');
    expect(servidor.requisicoes, contains('GET auth/me'));
  });

  test('ao abrir o app sem internet, a sessão offline é mantida', () async {
    await entrar();
    await ApiService.saveBaseUrl(semConexao);

    await validarSessao();

    expect(AppSession.autenticada, isTrue);
  });

  test('ao abrir o app com token revogado, a sessão é encerrada', () async {
    await entrar();
    servidor.tokenRevogado = true;

    await validarSessao();

    expect(AppSession.autenticada, isFalse);
  });

  test('logout revoga o token no servidor e limpa a sessão local', () async {
    await entrar();
    await ApiService.instance.logout();
    await AppSession.encerrarSessao();

    expect(AppSession.autenticada, isFalse);
    expect(servidor.tokenRevogado, isTrue);
  });

  test('esqueci a senha envia o link para o e-mail informado', () async {
    await ApiService.instance.esqueciSenha('  Motorista@GeoSync.com ');
    expect(servidor.linksDeSenhaEnviados, ['motorista@geosync.com']);
  });

  test(
    'trabalho offline de outro usuário não vaza após trocar de conta',
    () async {
      await entrar();
      await SyncEngine.instance.sincronizar();
      await ApiService.saveBaseUrl(semConexao);
      await ApiService.instance.atualizarStatusRemessa(99, 'Entregue');
      expect(await PendingQueue.instance.contar(), 1);

      await AppSession.encerrarSessao();
      await AppSession.iniciarSessao(
        token: 'token-teste',
        tipoUsuario: 'Motorista',
        email: 'outro@geosync.com',
      );
      await ApiService.saveBaseUrl(servidor.baseUrl);
      await SyncEngine.instance.sincronizar();

      expect(await PendingQueue.instance.contar(), 0);
    },
  );
}
