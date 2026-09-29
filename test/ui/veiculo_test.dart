import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/motorista/veiculo_motorista_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSession.salvarVeiculo(
      const VeiculoMotorista(
        modelo: 'Volvo VM 270',
        placa: 'ABC1D23',
        renavam: '12345678901',
        ano: '2024',
        capacidade: '14 toneladas',
      ),
    );
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const VeiculoMotoristaPage()),
    );
  }

  Finder campo(String rotulo) =>
      find.widgetWithText(TextFormField, rotulo).first;

  FilledButton salvar(WidgetTester tester) =>
      tester.widget(find.byType(FilledButton));

  testWidgets('prévia acompanha a edição e a placa fica em maiúsculas', (
    tester,
  ) async {
    await abrir(tester);
    expect(salvar(tester).onPressed, isNull);
    expect(find.text('Tudo salvo'), findsOneWidget);

    await tester.enterText(campo('Placa'), 'xyz9a87');
    await tester.enterText(campo('Modelo'), 'Scania R450');
    await tester.pump();

    expect(find.text('XYZ9A87'), findsNWidgets(2)); // Campo e placa.
    expect(find.text('Scania R450'), findsNWidgets(2)); // Campo e cartão.
    expect(salvar(tester).onPressed, isNotNull);
  });

  testWidgets('placa inválida impede salvar', (tester) async {
    await abrir(tester);
    await tester.enterText(campo('Placa'), 'AB12');
    await tester.pump();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();

    expect(find.text('Placa inválida'), findsOneWidget);
    expect(AppSession.veiculoMotorista.value.placa, 'ABC1D23');
  });

  testWidgets('dados salvos continuam após reiniciar o app', (tester) async {
    await abrir(tester);
    await tester.enterText(campo('Capacidade de carga'), '20 toneladas');
    await tester.pump();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('Dados do veículo salvos.'), findsOneWidget);

    // Simula o app sendo reaberto.
    AppSession.veiculoMotorista.value = const VeiculoMotorista(
      modelo: '',
      placa: '',
      renavam: '',
      ano: '',
      capacidade: '',
    );
    await tester.runAsync(AppSession.restaurar);
    expect(AppSession.veiculoMotorista.value.capacidade, '20 toneladas');
    expect(AppSession.veiculoMotorista.value.modelo, 'Volvo VM 270');
  });
}
