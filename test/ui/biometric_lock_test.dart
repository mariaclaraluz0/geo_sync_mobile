import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/biometric_lock_service.dart';
import 'package:mobile/widgets/biometric_lock_gate.dart';
import 'package:mobile/widgets/biometric_lock_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BiometricLockServiceFake extends BiometricLockService {
  bool supported = true;
  bool authenticationResult = true;
  int authenticationCalls = 0;

  @override
  Future<bool> get disponivel async => supported;

  @override
  Future<bool> autenticar() async {
    authenticationCalls++;
    return authenticationResult;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSession.definirBloqueioBiometrico(false);
  });

  testWidgets('ativa o bloqueio somente após autenticação local', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final service = _BiometricLockServiceFake();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BiometricLockTile(service: service)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(service.authenticationCalls, 1);
    expect(AppSession.bloqueioBiometricoAtivo.value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('bloqueio_biometrico_ativo'), isTrue);
  });

  testWidgets('mantém o app bloqueado até a autenticação ser concluída', (
    tester,
  ) async {
    final service = _BiometricLockServiceFake()..authenticationResult = false;
    await AppSession.iniciarSessao(
      token: 'token-teste',
      tipoUsuario: 'Cliente',
      email: 'cliente@geosync.com',
    );
    await AppSession.definirBloqueioBiometrico(true);

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricLockGate(
          service: service,
          child: const Text('Área protegida'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear GeoSync'), findsOneWidget);
    expect(find.text('Área protegida'), findsNothing);

    service.authenticationResult = true;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Área protegida'), findsOneWidget);
    expect(find.text('Desbloquear GeoSync'), findsNothing);
  });

  testWidgets('permite sair e voltar ao login sem expor a sessão', (
    tester,
  ) async {
    final service = _BiometricLockServiceFake()..authenticationResult = false;
    await AppSession.iniciarSessao(
      token: 'token-teste',
      tipoUsuario: 'Cliente',
      email: 'cliente@geosync.com',
    );
    await AppSession.definirBloqueioBiometrico(true);

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricLockGate(
          service: service,
          child: const Text('Área protegida'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair e usar senha da conta'));
    await tester.pumpAndSettle();

    expect(AppSession.autenticada, isFalse);
    expect(AppSession.bloqueioBiometricoAtivo.value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('bloqueio_biometrico_ativo'), isFalse);
  });
}
