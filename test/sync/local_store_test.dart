import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  setUp(() async {
    await JsonListStore.resetarParaTeste();
    JsonListStore.usarSqliteDeTeste = false;
    JsonListStore.chaveDeTeste = SecretKey(List<int>.filled(32, 42));
    SharedPreferences.setMockInitialValues({});
  });

  LocationPoint ponto(int segundo) => LocationPoint.capturado(
    latitude: -23,
    longitude: -46,
    registradoEm: DateTime.utc(2026, 1, 1, 0, 0, segundo),
  );

  group('LocationStore', () {
    test('escritas concorrentes não se perdem', () async {
      final store = LocationStore();
      await Future.wait([
        for (var i = 0; i < 50; i++) store.adicionar(ponto(i)),
      ]);
      expect(await store.todos(), hasLength(50));
    });

    test(
      'limita registros removendo sincronizados sem perder pontos pendentes',
      () async {
        final store = LocationStore(limite: 3);
        final a = ponto(1), b = ponto(2), c = ponto(3);
        for (final p in [a, b, c]) {
          await store.adicionar(p);
        }
        await store.marcarSincronizados([b.id]);
        await store.adicionar(ponto(4));
        expect((await store.todos()).map((p) => p.id), isNot(contains(b.id)));

        await expectLater(
          store.adicionar(ponto(5)),
          throwsA(isA<StateError>()),
        );
        final ids = (await store.todos()).map((p) => p.id).toList();
        expect(ids, hasLength(3));
        expect(ids, contains(a.id));
      },
    );

    test('ignora dados corrompidos', () async {
      SharedPreferences.setMockInitialValues({
        'geosync_pontos_localizacao': 'não é json',
      });
      expect(await LocationStore().todos(), isEmpty);
    });

    test('migra JSON legado e protege o conteúdo no armazenamento', () async {
      final legado = jsonEncode([
        {'id': 'gps-1', 'latitude': -23.0, 'nota': 'localização privada'},
      ]);
      SharedPreferences.setMockInitialValues({
        'geosync_pontos_localizacao': legado,
      });

      final store = JsonListStore('geosync_pontos_localizacao');
      expect(await store.ler(), hasLength(1));
      final salvo = (await SharedPreferences.getInstance()).getString(
        'geosync_pontos_localizacao',
      )!;
      expect(salvo, startsWith('enc:v1:'));
      expect(salvo, isNot(contains('localização privada')));
      expect((await store.ler()).single['id'], 'gps-1');
    });

    test(
      'migra a lista legada para SQLite cifrado e preserva banco sem chave',
      () async {
        addTearDown(() async {
          JsonListStore.usarSqliteDeTeste = false;
          await JsonListStore.resetarParaTeste();
        });
        const chave = 'geosync_pontos_localizacao';
        SharedPreferences.setMockInitialValues({
          chave: jsonEncode([
            {'id': 'gps-secreto', 'latitude': -23.0},
          ]),
        });
        JsonListStore.usarSqliteDeTeste = true;
        final store = JsonListStore(chave);

        expect((await store.ler()).single['id'], 'gps-secreto');
        expect(
          (await SharedPreferences.getInstance()).getString(chave),
          isNull,
        );

        final caminho =
            '${await sqflite.getDatabasesPath()}${Platform.pathSeparator}geosync_local.db';
        final db = await sqflite.openDatabase(caminho);
        final row = (await db.query('registros_locais')).single;
        expect(row['payload'], startsWith('enc:v1:'));

        JsonListStore.chaveDeTeste = null;
        await expectLater(store.ler(), throwsA(isA<LocalStorageException>()));
        expect(await db.query('registros_locais'), hasLength(1));
      },
    );

    test('uma transformação que falha não grava estado parcial', () async {
      final store = JsonListStore('transacao');
      await store.gravar([
        {'id': 'original'},
      ]);

      await expectLater(
        store.atualizar<void>((itens) {
          itens.clear();
          throw StateError('falha simulada');
        }),
        throwsA(isA<StateError>()),
      );
      expect((await store.ler()).single['id'], 'original');
    });

    test('política de retenção rejeita valores fora das opções', () async {
      await DataRetentionPolicy.salvar(30);
      expect(DataRetentionPolicy.dias.value, 30);
      await expectLater(DataRetentionPolicy.salvar(365), throwsArgumentError);
    });
  });

  group('PendingQueue', () {
    test('lê ações gravadas pela versão anterior do app', () async {
      SharedPreferences.setMockInitialValues({
        'motorista_acoes_pendentes': jsonEncode([
          {
            'method': 'PATCH',
            'path': 'remessas/3/status',
            'body': {'status': 'Em rota'},
            'criado_em': '2026-09-01T10:00:00.000',
          },
        ]),
      });
      final acoes = await PendingQueue().listar();
      expect(acoes.single.tipo, TipoAcao.generica);
      expect(acoes.single.statusDesejado, 'Em rota');
      expect(acoes.single.id, isNotEmpty);
    });

    test(
      'nova mudança de status substitui a anterior mantendo a base',
      () async {
        final fila = PendingQueue();
        PendingAction status(String valor, String? base) => PendingAction(
          id: gerarIdLocal(),
          tipo: TipoAcao.status,
          metodo: 'PATCH',
          caminho: 'remessas/1/status',
          corpo: {'status': valor},
          remessaId: '1',
          statusBase: base,
          criadoEm: DateTime.now().toUtc(),
        );
        await fila.adicionar(status('Em rota', 'Aguardando coleta'));
        await fila.adicionar(status('Entregue', 'Em rota'));

        final acoes = await fila.listar();
        expect(acoes, hasLength(1));
        expect(acoes.single.statusDesejado, 'Entregue');
        expect(acoes.single.statusBase, 'Aguardando coleta');
      },
    );

    test('retry-after e intervenção sobrevivem à serialização', () async {
      final acao =
          PendingAction(
            id: 'acao-retry',
            metodo: 'PATCH',
            caminho: 'remessas/1/status',
            criadoEm: DateTime.utc(2026, 10, 5),
          ).comNovaTentativa(
            agora: DateTime.utc(2026, 10, 5),
            erro: 'limite',
            espera: const Duration(minutes: 3),
          );
      final reidratada = PendingAction.fromJson(acao.toJson())!;
      expect(
        reidratada.proximaTentativa,
        DateTime.utc(2026, 10, 5).add(const Duration(minutes: 3)),
      );
      expect(reidratada.ultimoErro, 'limite');
      expect(acao.exigirIntervencao('rejeitada').requerIntervencao, isTrue);
    });
  });
}
