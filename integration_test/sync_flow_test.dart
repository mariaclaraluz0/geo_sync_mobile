import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/integration/fake_api_server.dart';

/// Fluxo completo no app real (Android, iOS ou desktop):
/// `flutter test integration_test -d <dispositivo>`
///
/// Um servidor HTTP local imita a API Laravel, então o teste não depende de
/// backend nem de internet.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiServer servidor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = await FakeApiServer.iniciar();
    servidor.salvarRemessa({
      'id': 1,
      'codigo': 'GS-1',
      'status': 'Aguardando coleta',
    });
    await AppSession.iniciarSessao(
      token: 'token-teste',
      tipoUsuario: 'Motorista',
      email: 'motorista@geosync.com',
      nome: 'Motorista Teste',
    );
    await ApiService.saveBaseUrl(servidor.baseUrl);
  });

  tearDown(() => servidor.fechar());

  Future<void> abrirConfiguracoes(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConfiguracoesMotoristaPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sincronizar agora'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('envia alteração offline pelo botão "Sincronizar agora"', (
    tester,
  ) async {
    await SyncEngine.instance.sincronizar();
    await ApiService.saveBaseUrl('http://127.0.0.1:1/api');
    await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');
    await ApiService.saveBaseUrl(servidor.baseUrl);
    await SyncEngine.instance.atualizarContadores();

    await abrirConfiguracoes(tester);
    expect(find.text('1 pendente'), findsOneWidget);

    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 alteração(ões) enviada(s)'), findsOneWidget);
    expect(find.text('1 pendente'), findsNothing);
    expect(servidor.remessas['1']!['status'], 'Em rota');
    expect(await PendingQueue.instance.contar(), 0);
  });

  testWidgets('mostra o conflito resolvido e o painel de exportação', (
    tester,
  ) async {
    await ConflictLog.instance.limpar();
    await SyncEngine.instance.sincronizar();
    await ApiService.saveBaseUrl('http://127.0.0.1:1/api');
    await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');
    servidor.avancar(const Duration(minutes: 5));
    servidor.salvarRemessa({...servidor.remessas['1']!, 'status': 'Cancelada'});
    await ApiService.saveBaseUrl(servidor.baseUrl);

    await abrirConfiguracoes(tester);
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 conflito(s) resolvido(s)'), findsOneWidget);

    await tester.tap(find.text('Conflitos resolvidos'));
    await tester.pumpAndSettle();
    expect(find.text('Remessa 1 • status'), findsOneWidget);
    expect(find.text('Servidor: Cancelada'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar dados'));
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('GeoJSON'), findsOneWidget);
  });
}
