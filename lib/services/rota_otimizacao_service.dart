import 'dart:math' as math;

class RotaParada {
  const RotaParada({
    required this.codigo,
    required this.destino,
    required this.distanciaKm,
    required this.status,
    required this.progresso,
    this.latitude,
    this.longitude,
  });

  final String codigo;
  final String destino;

  /// Distância em linha reta desde o motorista, usada apenas como fallback.
  final double distanciaKm;
  final String status;
  final double progresso;
  final double? latitude;
  final double? longitude;

  bool get possuiCoordenadas =>
      latitude != null && longitude != null &&
      latitude! >= -90 && latitude! <= 90 &&
      longitude! >= -180 && longitude! <= 180;
}

class RotaOtimizada {
  const RotaOtimizada({
    required this.ordem,
    required this.distanciaTotalKm,
    required this.tempoEstimadoMin,
    required this.destinoAtual,
    required this.proximoDestino,
    required this.distanciasEntreParadasKm,
    required this.aproximada,
  });

  final List<RotaParada> ordem;
  final double distanciaTotalKm;
  final int tempoEstimadoMin;
  final String destinoAtual;
  final String proximoDestino;
  final List<double> distanciasEntreParadasKm;

  /// True quando pelo menos uma parada não tem coordenadas válidas.
  final bool aproximada;
}

/// Ordena paradas por distância geográfica em linha reta.
///
/// Isso não substitui uma matriz de distâncias por ruas fornecida por um
/// backend de rotas. O resultado e o tempo são aproximações offline.
class RotaOtimizacaoService {
  static const _raioTerraKm = 6371.0;

  static RotaOtimizada otimizar(
    List<RotaParada> paradas, {
    double? origemLatitude,
    double? origemLongitude,
  }) {
    if (paradas.isEmpty) {
      return const RotaOtimizada(
        ordem: <RotaParada>[],
        distanciaTotalKm: 0,
        tempoEstimadoMin: 0,
        destinoAtual: 'Sem rota',
        proximoDestino: 'Sem rota',
        distanciasEntreParadasKm: <double>[],
        aproximada: true,
      );
    }

    final coordenadasCompletas = paradas.every((p) => p.possuiCoordenadas);
    final origemValida = _coordenadaValida(origemLatitude, origemLongitude);
    final aproximada = !coordenadasCompletas || !origemValida;

    final restantes = List<RotaParada>.of(paradas);
    final ordem = <RotaParada>[];
    var atualLat = origemValida ? origemLatitude! : null;
    var atualLon = origemValida ? origemLongitude! : null;

    while (restantes.isNotEmpty) {
      restantes.sort((a, b) {
        final da = _distancia(atualLat, atualLon, a);
        final db = _distancia(atualLat, atualLon, b);
        return da.compareTo(db);
      });
      final proxima = restantes.removeAt(0);
      ordem.add(proxima);
      atualLat = proxima.latitude;
      atualLon = proxima.longitude;
    }

    if (coordenadasCompletas && origemValida && ordem.length >= 3) {
      _aplicar2Opt(ordem, origemLatitude!, origemLongitude!);
    }

    final distancias = <double>[];
    atualLat = origemValida ? origemLatitude! : null;
    atualLon = origemValida ? origemLongitude! : null;
    var total = 0.0;
    for (final parada in ordem) {
      final trecho = _distancia(atualLat, atualLon, parada);
      distancias.add(trecho);
      total += trecho;
      atualLat = parada.latitude;
      atualLon = parada.longitude;
    }

    return RotaOtimizada(
      ordem: List.unmodifiable(ordem),
      distanciaTotalKm: total,
      tempoEstimadoMin: _tempoEstimado(total),
      destinoAtual: ordem.first.destino,
      proximoDestino: ordem.length > 1 ? ordem[1].destino : ordem.first.destino,
      distanciasEntreParadasKm: List.unmodifiable(distancias),
      aproximada: aproximada,
    );
  }

  static bool _coordenadaValida(double? latitude, double? longitude) =>
      latitude != null && longitude != null &&
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180;

  static double _distancia(double? lat, double? lon, RotaParada destino) {
    if (_coordenadaValida(lat, lon) && destino.possuiCoordenadas) {
      final lat1 = _rad(lat!);
      final lat2 = _rad(destino.latitude!);
      final dLat = lat2 - lat1;
      final dLon = _rad(destino.longitude! - lon!);
      final a = math.pow(math.sin(dLat / 2), 2) +
          math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
      return _raioTerraKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    }
    // Não inventa uma distância entre dois destinos sem coordenadas.
    return destino.distanciaKm.isFinite && destino.distanciaKm >= 0
        ? destino.distanciaKm
        : 0;
  }

  static void _aplicar2Opt(
    List<RotaParada> ordem,
    double origemLatitude,
    double origemLongitude,
  ) {
    var melhorou = true;
    while (melhorou) {
      melhorou = false;
      for (var i = 0; i < ordem.length - 1; i++) {
        for (var j = i + 1; j < ordem.length; j++) {
          final anteriorLatitude = i == 0
              ? origemLatitude
              : ordem[i - 1].latitude!;
          final anteriorLongitude = i == 0
              ? origemLongitude
              : ordem[i - 1].longitude!;
          final proximaLatitude = ordem[j].latitude!;
          final proximaLongitude = ordem[j].longitude!;
          final atualLatitude = ordem[i].latitude!;
          final atualLongitude = ordem[i].longitude!;
          final depoisLatitude = j + 1 < ordem.length
              ? ordem[j + 1].latitude!
              : null;
          final depoisLongitude = j + 1 < ordem.length
              ? ordem[j + 1].longitude!
              : null;
          final antes =
              _distanciaPontos(
                anteriorLatitude,
                anteriorLongitude,
                atualLatitude,
                atualLongitude,
              ) +
              (depoisLatitude == null
                  ? 0
                  : _distanciaPontos(
                      proximaLatitude,
                      proximaLongitude,
                      depoisLatitude,
                      depoisLongitude!,
                    ));
          final depois =
              _distanciaPontos(
                anteriorLatitude,
                anteriorLongitude,
                proximaLatitude,
                proximaLongitude,
              ) +
              (depoisLatitude == null
                  ? 0
                  : _distanciaPontos(
                      atualLatitude,
                      atualLongitude,
                      depoisLatitude,
                      depoisLongitude!,
                    ));
          if (depois + 0.000001 < antes) {
            final invertido = ordem.sublist(i, j + 1).reversed.toList();
            ordem.replaceRange(i, j + 1, invertido);
            melhorou = true;
          }
        }
      }
    }
  }

  static double _distanciaPontos(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final radLat1 = _rad(lat1);
    final radLat2 = _rad(lat2);
    final dLat = radLat2 - radLat1;
    final dLon = _rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(radLat1) * math.cos(radLat2) * math.pow(math.sin(dLon / 2), 2);
    return _raioTerraKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double graus) => graus * math.pi / 180;

  static int _tempoEstimado(double distanciaKm) {
    if (distanciaKm <= 0) return 0;
    const velocidadeMediaKmH = 28.0;
    return ((distanciaKm / velocidadeMediaKmH) * 60).round();
  }
}
