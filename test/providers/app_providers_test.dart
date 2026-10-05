import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app_providers.dart';
import 'package:mobile/app_session.dart';

void main() {
  test('estado de sessão observa mudanças de tema pelo Riverpod', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final antes = container.read(appSessionProvider).modoEscuro;

    AppSession.modoEscuro.value = !antes;

    expect(container.read(appSessionProvider).modoEscuro, !antes);
    AppSession.modoEscuro.value = antes;
  });
}
