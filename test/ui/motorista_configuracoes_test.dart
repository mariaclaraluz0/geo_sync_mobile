import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSession.iniciarSessao(
      token: 'token-teste',
      tipoUsuario: 'Motorista',
      email: 'motorista@geosync.com',
    );
    await AppSession.salvarConfiguracoes(const ConfiguracoesMotorista());
    await AppSession.definirNotificacoesAtivas(true);
  });

  testWidgets('confirma a gravação das preferências depois de salvar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ConfiguracoesMotoristaPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Economia de bateria'), 200);
    await tester.ensureVisible(find.text('Economia de bateria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Economia de bateria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('motorista_modo_economia'), isTrue);
    expect(AppSession.configuracoesMotorista.value.modoEconomia, isTrue);
    expect(find.text('Preferências salvas com sucesso.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
