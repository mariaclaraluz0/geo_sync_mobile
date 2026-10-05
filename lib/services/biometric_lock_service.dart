import 'package:local_auth/local_auth.dart';

class BiometricLockService {
  BiometricLockService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<bool> get disponivel => _authentication.isDeviceSupported();

  Future<bool> autenticar() => _authentication.authenticate(
    localizedReason: 'Confirme sua identidade para abrir o GeoSync.',
    persistAcrossBackgrounding: true,
  );
}
