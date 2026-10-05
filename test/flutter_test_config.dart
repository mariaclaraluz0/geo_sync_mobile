import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Executado pelo `flutter test` antes de cada arquivo desta pasta: troca o
/// armazenamento seguro do sistema (Keystore/Keychain) por um em memória.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  sqflite.databaseFactory = databaseFactoryFfi;
  JsonListStore.usarSqliteDeTeste = false;
  FlutterSecureStorage.setMockInitialValues({});
  await testMain();
}
