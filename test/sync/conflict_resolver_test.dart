import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/sync/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();
  final base = DateTime.utc(2026, 9, 28, 10);
  final local = DateTime.utc(2026, 9, 28, 10, 5);

  ResolucaoConflito resolver_({
    required String statusLocal,
    required String? statusServidor,
    DateTime? atualizadoServidor,
    String? statusBase = 'Aguardando coleta',
    DateTime? atualizadoBase,
    DateTime? alteradoEm,
  }) => resolver.resolverStatus(
    statusLocal: statusLocal,
    alteradoEm: alteradoEm ?? local,
    statusServidor: statusServidor,
    atualizadoServidor: atualizadoServidor,
    statusBase: statusBase,
    atualizadoBase: atualizadoBase ?? base,
  );

  test('sem mudança no servidor, a alteração local é enviada', () {
    final r = resolver_(
      statusLocal: 'Em rota',
      statusServidor: 'Aguardando coleta',
      atualizadoServidor: base,
    );
    expect(r.enviarLocal, isTrue);
    expect(r.conflito, isFalse);
  });

  test('alteração idêntica à do servidor não é reenviada', () {
    final r = resolver_(
      statusLocal: 'Em rota',
      statusServidor: 'Em rota',
      atualizadoServidor: base.add(const Duration(minutes: 1)),
    );
    expect(r.enviarLocal, isFalse);
    expect(r.conflito, isFalse);
  });

  test('status final do servidor sempre vence', () {
    for (final finalServidor in ['Entregue', 'Cancelada']) {
      final r = resolver_(
        statusLocal: 'Em rota',
        statusServidor: finalServidor,
        atualizadoServidor: base.add(const Duration(minutes: 1)),
        alteradoEm: base.add(const Duration(hours: 1)),
      );
      expect(r.vencedor, Vencedor.servidor, reason: finalServidor);
      expect(r.conflito, isTrue);
    }
  });

  test('status não regride', () {
    final r = resolver_(
      statusLocal: 'Aguardando coleta',
      statusBase: 'Aguardando coleta',
      statusServidor: 'Em rota',
      atualizadoServidor: base.add(const Duration(minutes: 1)),
    );
    expect(r.vencedor, Vencedor.servidor);
  });

  test('passo mais avançado local vence', () {
    final r = resolver_(
      statusLocal: 'Entregue',
      statusServidor: 'Alerta',
      atualizadoServidor: base.add(const Duration(hours: 1)),
    );
    expect(r.vencedor, Vencedor.local);
    expect(r.conflito, isTrue);
  });

  test('empate de progresso: vence a escrita mais recente', () {
    final servidorAntes = resolver_(
      statusLocal: 'Alerta',
      statusBase: 'Aguardando coleta',
      statusServidor: 'Em rota',
      atualizadoServidor: base.add(const Duration(minutes: 1)),
    );
    expect(servidorAntes.vencedor, Vencedor.local);

    final servidorDepois = resolver_(
      statusLocal: 'Alerta',
      statusBase: 'Aguardando coleta',
      statusServidor: 'Em rota',
      atualizadoServidor: local.add(const Duration(minutes: 1)),
    );
    expect(servidorDepois.vencedor, Vencedor.servidor);
  });

  test('sem updated_at, compara com o status que o aparelho conhecia', () {
    final semMudanca = resolver.resolverStatus(
      statusLocal: 'Em rota',
      alteradoEm: local,
      statusServidor: 'Aguardando coleta',
      statusBase: 'Aguardando coleta',
    );
    expect(semMudanca.conflito, isFalse);

    final mudou = resolver.resolverStatus(
      statusLocal: 'Em rota',
      alteradoEm: local,
      statusServidor: 'Cancelada',
      statusBase: 'Aguardando coleta',
    );
    expect(mudou.vencedor, Vencedor.servidor);
  });

  test('remessa ausente no servidor: deixa o servidor responder', () {
    final r = resolver_(statusLocal: 'Em rota', statusServidor: null);
    expect(r.enviarLocal, isTrue);
  });
}
