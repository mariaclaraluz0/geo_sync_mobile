/// Regras de resolução de conflitos entre alterações feitas offline no
/// aparelho e o estado atual no servidor.
///
/// Há conflito quando o registro mudou no servidor depois que o motorista
/// fez a alteração local (o `updated_at` do servidor é mais novo que o
/// `updated_at` que o aparelho conhecia). A estratégia é:
///
/// 1. **Status de remessa**: segue o ciclo de vida
///    `Aguardando coleta → Em rota → Entregue`. Um status nunca regride;
///    status finais (`Entregue`, `Cancelada`) já gravados no servidor sempre
///    prevalecem. Em empate de progresso vence a escrita mais recente.
library;

enum Vencedor { local, servidor }

class ResolucaoConflito {
  const ResolucaoConflito(this.vencedor, this.motivo, {this.conflito = true});

  /// Nenhuma divergência: a alteração local pode ser enviada.
  const ResolucaoConflito.semConflito()
    : vencedor = Vencedor.local,
      motivo = 'Sem alterações concorrentes no servidor',
      conflito = false;

  /// A alteração local já está refletida no servidor.
  const ResolucaoConflito.jaAplicada()
    : vencedor = Vencedor.servidor,
      motivo = 'A alteração já estava aplicada no servidor',
      conflito = false;

  final Vencedor vencedor;
  final String motivo;

  /// `false` quando não houve divergência real (nada a registrar no log).
  final bool conflito;

  bool get enviarLocal => vencedor == Vencedor.local;
}

class ConflictResolver {
  const ConflictResolver();

  static const statusFinais = {'Entregue', 'Cancelada'};

  /// Progresso de cada status no ciclo de vida da remessa.
  static const _progresso = {
    'Pendente': 0,
    'Aguardando coleta': 0,
    'Em rota': 1,
    'Alerta': 1,
    'Entregue': 2,
    'Cancelada': 2,
  };

  static int progresso(String? status) => _progresso[status] ?? 0;

  /// Decide se a mudança de status feita offline deve ser enviada.
  ///
  /// - [statusBase]/[atualizadoBase]: o que o aparelho conhecia ao alterar.
  /// - [statusLocal]/[alteradoEm]: a alteração feita offline.
  /// - [statusServidor]/[atualizadoServidor]: estado atual no servidor.
  ResolucaoConflito resolverStatus({
    required String statusLocal,
    required DateTime alteradoEm,
    required String? statusServidor,
    DateTime? atualizadoServidor,
    String? statusBase,
    DateTime? atualizadoBase,
  }) {
    // Remessa não encontrada no servidor: deixa o servidor responder.
    if (statusServidor == null) return const ResolucaoConflito.semConflito();
    if (statusServidor == statusLocal) {
      return const ResolucaoConflito.jaAplicada();
    }

    final servidorMudou = _servidorMudou(
      statusBase: statusBase,
      statusServidor: statusServidor,
      atualizadoBase: atualizadoBase,
      atualizadoServidor: atualizadoServidor,
    );
    if (!servidorMudou) return const ResolucaoConflito.semConflito();

    if (statusFinais.contains(statusServidor)) {
      return ResolucaoConflito(
        Vencedor.servidor,
        'A remessa já foi marcada como "$statusServidor" no servidor',
      );
    }

    final pLocal = progresso(statusLocal);
    final pServidor = progresso(statusServidor);
    if (pLocal > pServidor) {
      return ResolucaoConflito(
        Vencedor.local,
        '"$statusLocal" é um passo mais avançado que "$statusServidor"',
      );
    }
    if (pLocal < pServidor) {
      return ResolucaoConflito(
        Vencedor.servidor,
        'O status não pode regredir de "$statusServidor" para "$statusLocal"',
      );
    }
    return _ultimaEscrita(alteradoEm, atualizadoServidor);
  }

  bool _servidorMudou({
    required String? statusBase,
    required String statusServidor,
    DateTime? atualizadoBase,
    DateTime? atualizadoServidor,
  }) {
    if (atualizadoBase != null && atualizadoServidor != null) {
      return atualizadoServidor.isAfter(atualizadoBase);
    }
    // Sem carimbo de tempo, compara com o status que o aparelho conhecia.
    return statusBase == null || statusBase != statusServidor;
  }

  ResolucaoConflito _ultimaEscrita(DateTime local, DateTime? servidor) {
    if (servidor == null || !servidor.isAfter(local)) {
      return const ResolucaoConflito(
        Vencedor.local,
        'Alteração do aparelho é a mais recente',
      );
    }
    return const ResolucaoConflito(
      Vencedor.servidor,
      'Alteração do servidor é a mais recente',
    );
  }
}
