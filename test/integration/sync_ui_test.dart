import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_server.dart';

/// Mesmo fluxo de `integration_test/sync_flow_test.dart`, executável com
/// `flutter test` (sem aparelho): a tela de configurações do motorista
/// conversa com o servidor HTTP local por rede real.
void main() {
  late FakeApiServer servidor;

  setUp(() async {
    // O flutter_test bloqueia HTTP por padrão; aqui queremos a rede real.
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> preparar(WidgetTester tester) async {
    await tester.runAsync(() async {
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
      await ConflictLog.instance.limpar();
      await ApiService.saveBaseUrl(servidor.baseUrl);
      await SyncEngine.instance.sincronizar();
    });
    addTearDown(() => tester.runAsync(servidor.fechar));
  }

  /// Altera o status "sem internet" e volta a ficar online.
  Future<void> alterarOffline(WidgetTester tester, String status) =>
      tester.runAsync(() async {
        await ApiService.saveBaseUrl('http://127.0.0.1:1/api');
        await ApiService.instance.atualizarStatusRemessa(1, status);
        await ApiService.saveBaseUrl(servidor.baseUrl);
      });

  /// Deixa a rede real concluir (até ~10 s) e redesenha a tela. Espera a
  /// sincronização terminar antes de estabilizar, pois o indicador de
  /// progresso é uma animação contínua.
  Future<void> aguardarRede(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (i >= 4 && !SyncEngine.instance.estado.value.sincronizando) break;
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ConfiguracoesMotoristaPage(),
      ),
    );
    await aguardarRede(tester);
    await tester.scrollUntilVisible(
      find.text('Exportar dados'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
  }

  testWidgets('sincroniza a alteração offline pelo botão', (tester) async {
    await preparar(tester);
    await alterarOffline(tester, 'Em rota');
    await tester.runAsync(SyncEngine.instance.atualizarContadores);

    await abrir(tester);
    expect(find.text('1 pendente'), findsOneWidget);

    await tocar(tester, 'Sincronizar agora');
    await aguardarRede(tester);

    expect(find.textContaining('1 alteração(ões) enviada(s)'), findsOneWidget);
    expect(find.text('1 pendente'), findsNothing);
    expect(servidor.remessas['1']!['status'], 'Em rota');
    expect(await tester.runAsync(PendingQueue.instance.contar), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exibe conflito resolvido e painel de exportação', (
    tester,
  ) async {
    await preparar(tester);
    await alterarOffline(tester, 'Em rota');
    servidor.avancar(const Duration(minutes: 5));
    servidor.salvarRemessa({...servidor.remessas['1']!, 'status': 'Cancelada'});

    await abrir(tester);
    await tocar(tester, 'Sincronizar agora');
    await aguardarRede(tester);
    expect(find.textContaining('1 conflito(s) resolvido(s)'), findsOneWidget);

    await tocar(tester, 'Conflitos resolvidos');
    await aguardarRede(tester);
    expect(find.text('Remessa 1 • status'), findsOneWidget);
    expect(find.text('Servidor: Cancelada'), findsOneWidget);
    expect(find.text('Aparelho: Em rota'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tocar(tester, 'Exportar dados');
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('GeoJSON'), findsOneWidget);
    await tester.tap(find.text('Remessas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Remessas com coordenadas para ferramentas de mapa'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
