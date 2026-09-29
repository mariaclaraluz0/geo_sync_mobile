import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/sync/data_exporter.dart';
import 'package:mobile/sync/location_point.dart';

void main() {
  const exporter = DataExporter();

  LocationPoint ponto(
    String id,
    double lat,
    double lng,
    int minuto, {
    String? remessa = '10',
    double? altitude,
  }) => LocationPoint(
    id: id,
    remessaId: remessa,
    latitude: lat,
    longitude: lng,
    altitude: altitude,
    registradoEm: DateTime.utc(2026, 9, 28, 8, minuto),
    precisao: 5,
  );

  group('CSV', () {
    test('tem BOM, cabeçalho e uma linha por ponto com CRLF', () {
      final csv = exporter.pontosParaCsv([
        ponto('a', -23.5, -46.6, 0),
        ponto('b', -23.6, -46.7, 1, remessa: null),
      ]);
      expect(
        csv,
        startsWith(
          '${String.fromCharCode(0xFEFF)}id,remessa_id,latitude,longitude',
        ),
      );
      final linhas = csv.substring(1).trim().split('\r\n');
      expect(linhas, hasLength(3));
      expect(linhas[1], 'a,10,-23.5,-46.6,5.0,,,,2026-09-28T08:00:00.000Z,nao');
      expect(linhas[2].split(',')[1], isEmpty);
    });

    test('escapa vírgulas, aspas e quebras de linha (RFC 4180)', () {
      final csv = exporter.remessasParaCsv([
        {'id': 1, 'destino': 'Rua A, 10', 'obs': 'disse "ok"\nfim'},
      ]);
      expect(csv, contains('"Rua A, 10"'));
      expect(csv, contains('"disse ""ok""\nfim"'));
    });

    test('neutraliza fórmulas, mas mantém números negativos', () {
      final csv = exporter.remessasParaCsv([
        {'id': 1, 'codigo': '=HYPERLINK("x")', 'latitude': -23.5},
      ]);
      expect(csv, contains("\"'=HYPERLINK(\"\"x\"\")\""));
      expect(csv, contains(',-23.5'));
    });

    test('ordena colunas conhecidas primeiro e ignora objetos aninhados', () {
      final csv = exporter.remessasParaCsv([
        {
          'extra': 'x',
          'status': 'Em rota',
          'id': 1,
          'cliente': {'nome': 'A'},
        },
      ]);
      expect(csv.substring(1).split('\r\n').first, 'id,status,extra');
    });
  });

  group('GeoJSON', () {
    test('gera Points e um LineString por remessa em [lng, lat]', () {
      final geo = exporter.pontosParaGeoJson([
        ponto('b', -23.6, -46.7, 1),
        ponto('a', -23.5, -46.6, 0, altitude: 760),
        ponto('c', -22.9, -47.0, 2, remessa: '11'),
      ]);
      final features = geo['features'] as List;
      expect(geo['type'], 'FeatureCollection');

      final linhas = features.where(
        (f) => f['geometry']['type'] == 'LineString',
      );
      expect(linhas, hasLength(1)); // Remessa 11 tem só um ponto.
      final linha = linhas.single;
      expect(linha['properties']['remessa_id'], '10');
      expect(linha['geometry']['coordinates'], [
        [-46.6, -23.5, 760.0],
        [-46.7, -23.6],
      ]);

      final pontos = features.where((f) => f['geometry']['type'] == 'Point');
      expect(pontos.map((f) => f['id']), ['a', 'b', 'c']);
    });

    test('é JSON válido e serializável', () {
      final texto = exporter.geoJsonParaTexto(
        exporter.pontosParaGeoJson([ponto('a', 1, 2, 0)]),
      );
      expect(() => jsonDecode(texto), returnsNormally);
    });

    test('remessas sem coordenadas têm geometry nula', () {
      final geo = exporter.remessasParaGeoJson([
        {'id': 1, 'status': 'Em rota'},
        {'id': 2, 'latitude': '-23.5', 'longitude': '-46.6'},
        {
          'id': 3,
          'origem_latitude': -23.5,
          'origem_longitude': -46.6,
          'destino_latitude': -22.9,
          'destino_longitude': -47.0,
        },
      ]);
      final features = geo['features'] as List;
      expect(features[0]['geometry'], isNull);
      expect(features[1]['geometry'], {
        'type': 'Point',
        'coordinates': [-46.6, -23.5],
      });
      expect(features[2]['geometry']['type'], 'MultiPoint');
    });
  });
}
