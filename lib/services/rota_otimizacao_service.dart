class RotaParada {
  const RotaParada({
    required this.codigo,
    required this.destino,
    required this.distanciaKm,
    required this.status,
    required this.progresso,
  });

  final String codigo;
  final String destino;
  final double distanciaKm;
  final String status;
  final double progresso;
}

class RotaOtimizada {
  const RotaOtimizada({
    required this.ordem,
    required this.distanciaTotalKm,
    required this.tempoEstimadoMin,
    required this.destinoAtual,
    required this.proximoDestino,
    required this.distanciasEntreParadasKm,
  });

  final List<RotaParada> ordem;
  final double distanciaTotalKm;
  final int tempoEstimadoMin;
  final String destinoAtual;
  final String proximoDestino;
  final List<double> distanciasEntreParadasKm;
}

class RotaOtimizacaoService {
  /// Algoritmo: vizinho mais próximo com melhoria 2-opt.
  ///
  /// Em produção real, a rota ideal deve vir de um backend de mapas/rotas
  /// (Google Maps Directions, OSRM, GraphHopper etc.). Neste app, o cálculo
  /// local usa a distância restante já conhecida como proxy para ordenar as
  /// remessas mais próximas e reduzir o desvio total da rota.
  static RotaOtimizada otimizar(List<RotaParada> paradas) {
    if (paradas.isEmpty) {
      return const RotaOtimizada(
        ordem: <RotaParada>[],
        distanciaTotalKm: 0,
        tempoEstimadoMin: 0,
        destinoAtual: 'Sem rota',
        proximoDestino: 'Sem rota',
        distanciasEntreParadasKm: <double>[],
      );
    }

    final entradas = List<RotaParada>.from(paradas);
    final ordenada = _aplicarVizinhoMaisProximo(entradas);
    final melhor = _aplicar2Opt(ordenada);

    final distancias = <double>[];
    double total = 0;

    for (var i = 0; i < melhor.length - 1; i++) {
      final atual = melhor[i];
      final seguinte = melhor[i + 1];
      final trecho = _distanciaEntreParadas(atual, seguinte);
      distancias.add(trecho);
      total += trecho;
    }

    final destinoAtual = melhor.first.destino;
    final proximoDestino = melhor.length > 1 ? melhor[1].destino : destinoAtual;
    final tempoEstimadoMin = _tempoEstimado(total);

    return RotaOtimizada(
      ordem: melhor,
      distanciaTotalKm: total,
      tempoEstimadoMin: tempoEstimadoMin,
      destinoAtual: destinoAtual,
      proximoDestino: proximoDestino,
      distanciasEntreParadasKm: distancias,
    );
  }

  static List<RotaParada> _aplicarVizinhoMaisProximo(List<RotaParada> entradas) {
    final restantes = List<RotaParada>.from(entradas);
    final ordem = <RotaParada>[];

    var atual = _proximoDaOrigem(restantes);
    ordem.add(atual);
    restantes.remove(atual);

    while (restantes.isNotEmpty) {
      final proximo = restantes.reduce((melhor, item) {
        final a = _distanciaEntreParadas(atual, melhor);
        final b = _distanciaEntreParadas(atual, item);
        return b < a ? item : melhor;
      });

      ordem.add(proximo);
      restantes.remove(proximo);
      atual = proximo;
    }

    return ordem;
  }

  static RotaParada _proximoDaOrigem(List<RotaParada> paradas) {
    return paradas.reduce(
      (melhor, atual) => atual.distanciaKm < melhor.distanciaKm ? atual : melhor,
    );
  }

  static List<RotaParada> _aplicar2Opt(List<RotaParada> ordem) {
    var melhor = List<RotaParada>.from(ordem);
    var melhorCusto = _custoRota(melhor);
    var melhorou = true;

    while (melhorou) {
      melhorou = false;
      for (var i = 0; i < melhor.length - 1; i++) {
        for (var j = i + 1; j < melhor.length; j++) {
          final tentativa = List<RotaParada>.from(melhor);
          final trecho = tentativa.sublist(i, j + 1).reversed.toList();
          tentativa.replaceRange(i, j + 1, trecho);
          final custo = _custoRota(tentativa);
          if (custo < melhorCusto) {
            melhor = tentativa;
            melhorCusto = custo;
            melhorou = true;
          }
        }
      }
    }

    return melhor;
  }

  static double _custoRota(List<RotaParada> rota) {
    if (rota.length < 2) return 0;
    var custo = 0.0;
    for (var i = 0; i < rota.length - 1; i++) {
      custo += _distanciaEntreParadas(rota[i], rota[i + 1]);
    }
    return custo;
  }

  static double _distanciaEntreParadas(RotaParada origem, RotaParada destino) {
    final base = (origem.distanciaKm + destino.distanciaKm) / 2;
    final diferenca = (origem.distanciaKm - destino.distanciaKm).abs();
    return (base * 0.65) + (diferenca * 0.35);
  }

  static int _tempoEstimado(double distanciaKm) {
    if (distanciaKm <= 0) return 0;
    const velocidadeMedia = 28.0; // km/h
    return ((distanciaKm / velocidadeMedia) * 60).round();
  }
}
