import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Executado pelo `flutter test` antes de cada arquivo desta pasta: troca o
/// armazenamento seguro do sistema (Keystore/Keychain) por um em memória.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});
  await testMain();
}
