import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/background_location_service.dart';
import 'package:mobile/sync/data_exporter.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_server.dart';

/// Testes de integração: cliente HTTP real + ApiService + SyncEngine +
/// armazenamento local + exportação, contra um servidor HTTP local.
void main() {
  late FakeApiServer servidor;
  const semConexao = 'http://127.0.0.1:1/api';

  Future<void> online() => ApiService.saveBaseUrl(servidor.baseUrl);
  Future<void> offline() => ApiService.saveBaseUrl(semConexao);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servidor = await FakeApiServer.iniciar();
    servidor.salvarRemessa({
      'id': 1,
      'codigo': 'GS-1',
      'status': 'Aguardando coleta',
      'destino': 'Campinas, SP',
    });
    servidor.salvarRemessa({
      'id': 2,
      'codigo': 'GS-2',
      'status': 'Em rota',
      'destino': 'Santos, SP',
    });
    await AppSession.iniciarSessao(
      token: 'token-teste',
      tipoUsuario: 'Motorista',
      email: 'motorista@geosync.com',
      nome: 'Motorista Teste',
    );
    await AppSession.salvarConfiguracoes(const ConfiguracoesMotorista());
    await online();
  });

  tearDown(() => servidor.fechar());

  Future<Map<String, dynamic>> remessaLocal(Object id) async =>
      (await SyncEngine.instance.remessasLocais()).firstWhere(
        (r) => '${r['id']}' == '$id',
      );

  group('Sincronização offline e fila de ações', () {
    test(
      'mudança de status offline é enviada quando a conexão volta',
      () async {
        await ApiService.instance.minhasRemessas(forceRefresh: true);

        await offline();
        final resposta = await ApiService.instance.atualizarStatusRemessa(
          1,
          'Em rota',
        );
        expect(resposta['pendente_sincronizacao'], isTrue);
        expect(await PendingQueue.instance.contar(), 1);

        // Sem internet, a lista mostra a alteração otimista.
        final offlineLista = await ApiService.instance.minhasRemessas(
          forceRefresh: true,
        );
        final remessa = offlineLista.cast<Map>().firstWhere(
          (r) => r['id'] == 1,
        );
        expect(remessa['status'], 'Em rota');
        expect(remessa['pendente_sincronizacao'], isTrue);

        await online();
        final rel = await SyncEngine.instance.sincronizar();

        expect(rel.acoesEnviadas, 1);
        expect(rel.conflitos, 0);
        expect(servidor.remessas['1']!['status'], 'Em rota');
        expect(await PendingQueue.instance.contar(), 0);
        expect((await remessaLocal(1))['pendente_sincronizacao'], isNull);
      },
    );

    test('aceite offline é reenviado uma única vez', () async {
      await SyncEngine.instance.sincronizar();
      await offline();
      await ApiService.instance.aceitarRemessa(7);
      await online();

      await SyncEngine.instance.sincronizar();
      await SyncEngine.instance.sincronizar();

      expect(
        servidor.requisicoes.where((r) => r == 'POST remessas/7/aceitar'),
        hasLength(1),
      );
      expect(servidor.remessas.containsKey('7'), isTrue);
      expect(await remessaLocal(7), containsPair('codigo', 'GS-7'));
    });

    test(
      'mantém a fila e a ordem quando a rede cai no meio do envio',
      () async {
        await SyncEngine.instance.sincronizar();
        await offline();
        await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');
        await ApiService.instance.atualizarStatusRemessa(2, 'Entregue');

        await expectLater(
          SyncEngine.instance.sincronizar(),
          throwsA(isA<Exception>()),
        );
        expect(SyncEngine.instance.estado.value.erro, isNotNull);
        expect(await PendingQueue.instance.contar(), 2);

        await online();
        await SyncEngine.instance.sincronizar();
        expect(servidor.remessas['1']!['status'], 'Em rota');
        expect(servidor.remessas['2']!['status'], 'Entregue');
        expect(SyncEngine.instance.estado.value.erro, isNull);
      },
    );
  });

  group('Resolução de conflitos', () {
    setUp(() async {
      await ConflictLog.instance.limpar();
      await SyncEngine.instance.sincronizar();
      await offline();
    });

    test(
      'status final no servidor prevalece sobre a alteração offline',
      () async {
        await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');
        // Enquanto o motorista estava offline, a central finalizou a remessa.
        servidor.avancar(const Duration(minutes: 5));
        servidor.salvarRemessa({
          ...servidor.remessas['1']!,
          'status': 'Entregue',
        });

        await online();
        final rel = await SyncEngine.instance.sincronizar();

        expect(rel.acoesEnviadas, 0);
        expect(rel.acoesDescartadas, 1);
        expect(rel.conflitos, 1);
        expect(
          servidor.requisicoes,
          isNot(contains('PATCH remessas/1/status')),
        );
        expect(servidor.remessas['1']!['status'], 'Entregue');
        expect((await remessaLocal(1))['status'], 'Entregue');

        final conflitos = await ConflictLog.instance.listar();
        expect(conflitos, hasLength(1));
        expect(conflitos.first.vencedorLocal, isFalse);
        expect(conflitos.first.valorLocal, 'Em rota');
        expect(conflitos.first.valorServidor, 'Entregue');
      },
    );

    test('alteração local mais avançada no ciclo de vida vence', () async {
      await ApiService.instance.atualizarStatusRemessa(1, 'Entregue');
      servidor.avancar(const Duration(minutes: 5));
      servidor.salvarRemessa({...servidor.remessas['1']!, 'status': 'Alerta'});

      await online();
      final rel = await SyncEngine.instance.sincronizar();

      expect(rel.acoesEnviadas, 1);
      expect(rel.conflitos, 1);
      expect(servidor.remessas['1']!['status'], 'Entregue');
      expect(
        (await ConflictLog.instance.listar()).single.vencedorLocal,
        isTrue,
      );
    });

    test('alteração já aplicada no servidor não gera conflito', () async {
      await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');
      servidor.avancar(const Duration(minutes: 1));
      servidor.salvarRemessa({...servidor.remessas['1']!, 'status': 'Em rota'});

      await online();
      final rel = await SyncEngine.instance.sincronizar();

      expect(rel.conflitos, 0);
      expect(servidor.requisicoes, isNot(contains('PATCH remessas/1/status')));
      expect(await PendingQueue.instance.contar(), 0);
    });

    test(
      'rejeição 409 do servidor descarta a ação e registra o conflito',
      () async {
        await ApiService.instance.atualizarStatusRemessa(2, 'Entregue');
        servidor.respostasForcadas['PATCH remessas/2/status'] = 409;

        await online();
        final rel = await SyncEngine.instance.sincronizar();

        expect(rel.acoesDescartadas, 1);
        expect(rel.conflitos, 1);
        expect(await PendingQueue.instance.contar(), 0);
        expect(servidor.remessas['2']!['status'], 'Em rota');
        expect(
          (await ConflictLog.instance.listar()).single.motivo,
          contains('alterada por outro usuário'),
        );
      },
    );
  });

  group('Sincronização incremental', () {
    test('baixa somente as remessas alteradas desde o último cursor', () async {
      final primeira = await SyncEngine.instance.sincronizar();
      expect(primeira.incremental, isFalse);
      expect(primeira.remessasRecebidas, 2);
      expect(servidor.requisicoes.last, 'GET remessas/minhas');

      servidor.avancar(const Duration(minutes: 1));
      servidor.salvarRemessa({
        ...servidor.remessas['2']!,
        'status': 'Entregue',
      });

      final segunda = await SyncEngine.instance.sincronizar();
      expect(segunda.incremental, isTrue);
      expect(segunda.remessasRecebidas, 1);
      expect(
        servidor.requisicoes.last,
        startsWith('GET remessas/minhas?updated_since='),
      );

      final locais = await SyncEngine.instance.remessasLocais();
      expect(locais, hasLength(2));
      expect((await remessaLocal(1))['status'], 'Aguardando coleta');
      expect((await remessaLocal(2))['status'], 'Entregue');

      final terceira = await SyncEngine.instance.sincronizar();
      expect(terceira.remessasRecebidas, 0);
    });

    test('continua correta com uma API que ignora updated_since', () async {
      servidor.suportaIncremental = false;
      await SyncEngine.instance.sincronizar();
      servidor.avancar(const Duration(minutes: 1));
      servidor.salvarRemessa({...servidor.remessas['1']!, 'status': 'Em rota'});

      final rel = await SyncEngine.instance.sincronizar();
      expect(rel.remessasRecebidas, 2);
      expect((await remessaLocal(1))['status'], 'Em rota');
      expect(await SyncEngine.instance.remessasLocais(), hasLength(2));
    });

    test(
      'sincronização completa periódica remove remessas excluídas',
      () async {
        var agora = DateTime.now();
        final sync = SyncEngine(relogio: () => agora);
        await sync.sincronizar();

        servidor.remessas.remove('2');
        await sync.sincronizar();
        expect(await sync.remessasLocais(), hasLength(2)); // Incremental.

        agora = agora.add(
          SyncEngine.intervaloCompleto + const Duration(minutes: 1),
        );
        final rel = await sync.sincronizar();
        expect(rel.incremental, isFalse);
        expect((await sync.remessasLocais()).map((r) => r['id']), [1]);
      },
    );

    test('dados de outro usuário são descartados ao trocar de conta', () async {
      await SyncEngine.instance.sincronizar();
      await offline();
      await ApiService.instance.atualizarStatusRemessa(1, 'Em rota');

      await AppSession.iniciarSessao(
        token: 'token-teste',
        tipoUsuario: 'Motorista',
        email: 'outro@geosync.com',
      );
      await online();
      await SyncEngine.instance.sincronizar();

      expect(await PendingQueue.instance.contar(), 0);
      expect(servidor.requisicoes, isNot(contains('PATCH remessas/1/status')));
    });
  });

  group('Captura de localização em segundo plano', () {
    late StreamController<LocationPoint> gps;
    late BackgroundLocationService rastreamento;
    late LocationStore store;
    late SyncEngine sync;
    final inicio = DateTime.utc(2026, 9, 28, 10);

    LocationPoint leitura(
      int segundos, {
      double lat = -22.9056,
      double lng = -47.0608,
      double precisao = 8,
    }) => LocationPoint(
      id: '',
      latitude: lat,
      longitude: lng,
      registradoEm: inicio.add(Duration(seconds: segundos)),
      precisao: precisao,
      velocidade: 12.5,
    );

    setUp(() {
      gps = StreamController<LocationPoint>();
      store = LocationStore();
      sync = SyncEngine(pontos: store);
      rastreamento = BackgroundLocationService(
        fonte: (_) => gps.stream,
        verificarPermissao: () async => ResultadoRastreamento.iniciado,
        store: store,
        sync: sync,
      );
    });

    tearDown(() async {
      await rastreamento.parar();
      await gps.close();
    });

    Future<void> aguardar() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('grava pontos filtrados localmente e envia ao servidor', () async {
      expect(
        await rastreamento.iniciar(remessaId: 1),
        ResultadoRastreamento.iniciado,
      );
      expect(rastreamento.ativo.value, isTrue);

      gps
        ..add(leitura(0))
        ..add(leitura(5, lat: -22.9057)) // Muito próximo no tempo: ignorado.
        ..add(leitura(20, lat: -22.9100))
        ..add(leitura(40, lat: -22.9200, precisao: 500)); // Impreciso.
      await aguardar();

      final pontos = await store.todos();
      expect(pontos, hasLength(2));
      expect(pontos.map((p) => p.remessaId), everyElement('1'));
      expect(rastreamento.ultimaPosicao.value!.latitude, -22.9100);

      await sync.enviarPontos();
      expect(servidor.localizacoes, hasLength(2));
      expect(servidor.localizacoes.first['remessa_id'], 1);
      expect(servidor.localizacoes.first['client_id'], pontos.first.id);
      expect(
        servidor.localizacoes.first['registrado_em'],
        inicio.toIso8601String(),
      );
      expect(await store.contarPendentes(), 0);
    });

    test(
      'sem internet os pontos ficam na fila e são enviados depois',
      () async {
        await offline();
        await rastreamento.iniciar(remessaId: 2);
        gps
          ..add(leitura(0))
          ..add(leitura(30, lat: -22.95))
          ..add(leitura(60, lat: -23.0));
        await aguardar();
        await rastreamento.parar();
        await aguardar();

        expect(await store.contarPendentes(), 3);
        expect(servidor.localizacoes, isEmpty);

        await online();
        // Quem enviar primeiro (a tentativa agendada ou esta rodada) envia
        // tudo uma única vez.
        await sync.sincronizar();
        expect(servidor.localizacoes, hasLength(3));
        expect(
          servidor.requisicoes.where((r) => r == 'POST localizacao'),
          hasLength(3),
        );
        expect(await store.contarPendentes(), 0);
      },
    );

    test('para ao desativar a localização nas configurações', () async {
      await rastreamento.iniciar(remessaId: 1);
      await AppSession.salvarConfiguracoes(
        const ConfiguracoesMotorista(localizacao: false),
      );
      await aguardar();
      expect(rastreamento.ativo.value, isFalse);
      expect(
        await rastreamento.iniciar(remessaId: 1),
        ResultadoRastreamento.desativadoNasConfiguracoes,
      );
    });

    test('retoma o rastreamento após reiniciar o app', () async {
      await rastreamento.iniciar(remessaId: 5);
      final reiniciado = BackgroundLocationService(
        fonte: (_) => const Stream.empty(),
        verificarPermissao: () async => ResultadoRastreamento.iniciado,
        store: store,
        sync: sync,
      );
      await reiniciado.restaurar();
      expect(reiniciado.ativo.value, isTrue);
      expect(reiniciado.remessaId, '5');
      await reiniciado.parar();
    });
  });

  group('Exportação', () {
    test('exporta o trajeto capturado em CSV e GeoJSON válidos', () async {
      final store = LocationStore();
      await store.adicionar(
        LocationPoint.capturado(
          latitude: -22.9,
          longitude: -47.06,
          remessaId: '1',
          registradoEm: DateTime.utc(2026, 9, 28, 10),
        ),
      );
      await store.adicionar(
        LocationPoint.capturado(
          latitude: -22.95,
          longitude: -47.1,
          remessaId: '1',
          registradoEm: DateTime.utc(2026, 9, 28, 10, 1),
        ),
      );
      final exportacao = ExportService(pontos: store);

      final csv = await exportacao.gerar(
        ConjuntoExportacao.localizacoes,
        FormatoExportacao.csv,
      );
      final linhas = csv.conteudo.trim().split('\r\n');
      expect(csv.registros, 2);
      expect(linhas, hasLength(3));
      expect(linhas[1], contains('-22.9,-47.06'));

      final geo = await exportacao.gerar(
        ConjuntoExportacao.localizacoes,
        FormatoExportacao.geoJson,
      );
      final json = jsonDecode(geo.conteudo) as Map<String, dynamic>;
      final features = json['features'] as List;
      expect(json['type'], 'FeatureCollection');
      expect(features, hasLength(3));
      expect(features.first['geometry']['type'], 'LineString');
      expect(features.first['geometry']['coordinates'][0], [-47.06, -22.9]);
    });

    test('exporta as remessas sincronizadas', () async {
      await SyncEngine.instance.sincronizar();
      final csv = await ExportService.instance.gerar(
        ConjuntoExportacao.remessas,
        FormatoExportacao.csv,
      );
      final linhas = csv.conteudo.trim().split('\r\n');
      expect(csv.conteudo.codeUnitAt(0), 0xFEFF); // BOM para o Excel.
      expect(linhas.first, endsWith('id,codigo,status,destino,updated_at'));
      expect(linhas, hasLength(3));
      expect(csv.conteudo, contains('Aguardando coleta'));
    });
  });
}
