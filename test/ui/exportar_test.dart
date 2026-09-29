import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/motorista/sincronizacao_widgets.dart';
import 'package:mobile/sync/data_exporter.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory pasta;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      SyncEngine.cacheRemessasKey: jsonEncode([
        {'id': 1, 'codigo': 'GS-1', 'status': 'Em rota'},
      ]),
    });
    pasta = await Directory.systemTemp.createTemp('geosync_export_');
  });

  tearDown(() => pasta.delete(recursive: true));

  Future<LocationStore> storeCom(int pontos) async {
    final store = LocationStore();
    await store.limparTudo();
    for (var i = 0; i < pontos; i++) {
      await store.adicionar(
        LocationPoint.capturado(
          latitude: -23.5 - i / 100,
          longitude: -46.6,
          remessaId: '1',
          registradoEm: DateTime.utc(2026, 9, 29, 10, i),
        ),
      );
    }
    return store;
  }

  group('ExportService.salvar', () {
    test('grava o arquivo no local escolhido', () async {
      final destino = '${pasta.path}${Platform.pathSeparator}trajeto';
      final servico = ExportService(
        pontos: await storeCom(3),
        escolherDestino: (nome, formato) async {
          expect(nome, startsWith('geosync_localizacoes_'));
          expect(nome, endsWith('.csv'));
          return destino; // Sem extensão: o serviço completa.
        },
      );

      final resultado = await servico.salvar(
        ConjuntoExportacao.localizacoes,
        FormatoExportacao.csv,
      );

      expect(resultado.compartilhado, isTrue);
      expect(resultado.caminho, '$destino.csv');
      final linhas = (await File(
        '$destino.csv',
      ).readAsString()).trim().split('\r\n');
      expect(linhas, hasLength(4)); // Cabeçalho + 3 pontos.
    });

    test('cancelar o diálogo não grava nada', () async {
      final servico = ExportService(
        pontos: await storeCom(1),
        escolherDestino: (_, _) async => null,
      );
      final resultado = await servico.salvar(
        ConjuntoExportacao.localizacoes,
        FormatoExportacao.geoJson,
      );
      expect(resultado.compartilhado, isFalse);
      expect(pasta.listSync(), isEmpty);
    });

    test('sem dados, não abre o diálogo', () async {
      var abriu = false;
      final servico = ExportService(
        pontos: await storeCom(0),
        escolherDestino: (_, _) async {
          abriu = true;
          return null;
        },
      );
      final resultado = await servico.salvar(
        ConjuntoExportacao.localizacoes,
        FormatoExportacao.csv,
      );
      expect(resultado.registros, 0);
      expect(abriu, isFalse);
    });
  });

  group('Folha Exportar dados', () {
    Future<void> abrir(WidgetTester tester, ExportService servico) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: ExportarDadosSheet(servico: servico)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mostra quantos registros cada conjunto tem', (tester) async {
      final store = await tester.runAsync(() => storeCom(2));
      await abrir(tester, ExportService(pontos: store));

      expect(find.text('2 pontos'), findsOneWidget);
      expect(find.text('1 remessa'), findsOneWidget);
      expect(find.textContaining('geosync_localizacoes_'), findsOneWidget);
    });

    testWidgets('sem localizações, explica o motivo e desativa as ações', (
      tester,
    ) async {
      final store = await tester.runAsync(() => storeCom(0));
      await abrir(tester, ExportService(pontos: store));

      expect(
        find.textContaining('Ainda não há localizações registradas'),
        findsOneWidget,
      );
      final botao = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(botao.onPressed, isNull);

      // Remessas tem dados: as ações voltam a ficar disponíveis.
      await tester.tap(find.text('Remessas'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('no computador, "Salvar arquivo" grava o GeoJSON', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final destino = '${pasta.path}${Platform.pathSeparator}rota.geojson';
      final store = await tester.runAsync(() => storeCom(2));
      await abrir(
        tester,
        ExportService(pontos: store, escolherDestino: (_, _) async => destino),
      );

      await tester.tap(find.text('GeoJSON'));
      await tester.pump();
      await tester.tap(find.text('Salvar arquivo'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final json = jsonDecode(
        (await tester.runAsync(() => File(destino).readAsString()))!,
      );
      expect(json['type'], 'FeatureCollection');
      expect(find.text('Compartilhar'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
