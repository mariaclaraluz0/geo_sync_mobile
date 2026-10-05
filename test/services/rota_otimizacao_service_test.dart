import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/rota_otimizacao_service.dart';

void main() {
  RotaParada parada(String codigo, double latitude, double longitude) =>
      RotaParada(
        codigo: codigo,
        destino: codigo,
        distanciaKm: 0,
        status: 'Em rota',
        progresso: 0,
        latitude: latitude,
        longitude: longitude,
      );

  test('ordena por coordenadas partindo da posição do motorista', () {
    final rota = RotaOtimizacaoService.otimizar(
      [parada('longe', -22.9, -43.2), parada('perto', -23.55, -46.63)],
      origemLatitude: -23.55,
      origemLongitude: -46.64,
    );

    expect(rota.ordem.first.codigo, 'perto');
    expect(rota.aproximada, isFalse);
    expect(rota.distanciaTotalKm, greaterThan(0));
  });

  test('identifica sugestão aproximada quando faltam coordenadas', () {
    final rota = RotaOtimizacaoService.otimizar([
      RotaParada(
        codigo: 'GS-1',
        destino: 'Destino',
        distanciaKm: 8,
        status: 'Em rota',
        progresso: 0,
      ),
    ]);

    expect(rota.aproximada, isTrue);
    expect(rota.ordem.single.codigo, 'GS-1');
  });

  test('rota vazia tem métricas zeradas', () {
    final rota = RotaOtimizacaoService.otimizar(const []);
    expect(rota.ordem, isEmpty);
    expect(rota.distanciaTotalKm, 0);
  });
}
