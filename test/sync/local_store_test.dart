import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/pending_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
      'respeita o limite descartando sincronizados antes dos pendentes',
      () async {
        final store = LocationStore(limite: 3);
        final a = ponto(1), b = ponto(2), c = ponto(3);
        for (final p in [a, b, c]) {
          await store.adicionar(p);
        }
        await store.marcarSincronizados([b.id]);
        await store.adicionar(ponto(4));
        expect((await store.todos()).map((p) => p.id), isNot(contains(b.id)));

        await store.adicionar(ponto(5));
        final ids = (await store.todos()).map((p) => p.id).toList();
        expect(ids, hasLength(3));
        expect(ids, isNot(contains(a.id)));
      },
    );

    test('ignora dados corrompidos', () async {
      SharedPreferences.setMockInitialValues({
        'geosync_pontos_localizacao': 'não é json',
      });
      expect(await LocationStore().todos(), isEmpty);
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
  });
}
