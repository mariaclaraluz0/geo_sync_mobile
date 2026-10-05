import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:path/path.dart' as p;
import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Database>? _databaseFuture;
Future<SecretKey>? _chaveBancoFuture;
const _cofre = FlutterSecureStorage();
const _chaveBancoId = 'geosync_local_db_key_v1';
final _aes = AesGcm.with256bits();
SecretKey? _chaveDeTeste;

Future<SecretKey> _chaveBanco() => _chaveBancoFuture ??= () async {
  if (_chaveDeTeste != null) return _chaveDeTeste!;
  var valor = await _cofre.read(key: _chaveBancoId);
  if (valor == null) {
    final preferencias = await SharedPreferences.getInstance();
    final preferenciasCriptografadas = preferencias.getKeys().any((key) {
      final dado = preferencias.get(key);
      return dado is String && dado.startsWith('enc:v1:');
    });
    var bancoCriptografado = false;
    final diretorio = await getDatabasesPath();
    final caminho = p.join(diretorio, 'geosync_local.db');
    if (await databaseExists(caminho) && _databaseFuture != null) {
      final registros = await _databaseFuture!.then(
        (db) => db.query('registros_locais', columns: ['payload'], limit: 1),
      );
      bancoCriptografado = registros.any(
        (row) => (row['payload'] as String?)?.startsWith('enc:v1:') ?? false,
      );
    }
    if (preferenciasCriptografadas || bancoCriptografado) {
      throw const LocalStorageException(
        'A chave do armazenamento local não está disponível. '
        'Os dados foram preservados; entre novamente ou restaure o cofre do aparelho.',
      );
    }
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    valor = base64UrlEncode(bytes);
    await _cofre.write(key: _chaveBancoId, value: valor);
  }
  return SecretKey(base64Url.decode(base64Url.normalize(valor)));
}();

Future<String> _proteger(String texto) async {
  final box = await _aes.encrypt(
    utf8.encode(texto),
    secretKey: await _chaveBanco(),
  );
  return 'enc:v1:${base64UrlEncode(utf8.encode(jsonEncode({'nonce': base64UrlEncode(box.nonce), 'ciphertext': base64UrlEncode(box.cipherText), 'mac': base64UrlEncode(box.mac.bytes)})))}';
}

Future<String> _desproteger(String payload) async {
  if (!payload.startsWith('enc:v1:')) return payload;
  final envelope =
      jsonDecode(
            utf8.decode(base64Url.decode(payload.substring('enc:v1:'.length))),
          )
          as Map<String, dynamic>;
  final box = SecretBox(
    base64Url.decode(envelope['ciphertext'] as String),
    nonce: base64Url.decode(envelope['nonce'] as String),
    mac: Mac(base64Url.decode(envelope['mac'] as String)),
  );
  return utf8.decode(await _aes.decrypt(box, secretKey: await _chaveBanco()));
}

bool? _usarSqliteDeTeste;

bool get _usaSqlite =>
    _usarSqliteDeTeste ??
    (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS));

Future<Database> _abrirBanco() => _databaseFuture ??= () async {
  final diretorio = await getDatabasesPath();
  return openDatabase(
    p.join(diretorio, 'geosync_local.db'),
    version: 1,
    onCreate: (db, version) => db.execute('''
      CREATE TABLE registros_locais (
        store_key TEXT NOT NULL,
        item_index INTEGER NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (store_key, item_index)
      )
    '''),
  );
}();

/// Serializa operações assíncronas para evitar que duas escritas
/// concorrentes (ex.: captura de GPS e envio ao servidor) se sobrescrevam.
///
/// Só aguarda quando há uma operação realmente em andamento; não encadeia
/// em futures já concluídos, que poderiam pertencer a outra zona.
class _Mutex {
  Completer<void>? _ultima;

  Future<T> run<T>(Future<T> Function() acao) async {
    final anterior = _ultima;
    final atual = Completer<void>();
    _ultima = atual;
    try {
      if (anterior != null && !anterior.isCompleted) await anterior.future;
      return await acao();
    } finally {
      atual.complete();
      if (identical(_ultima, atual)) _ultima = null;
    }
  }
}

/// Armazena listas em SQLite nos dispositivos móveis e migra o formato JSON
/// legado automaticamente. Web e desktop sem suporte nativo usam preferências.
class JsonListStore {
  JsonListStore(this.chave) : _mutex = _mutexes.putIfAbsent(chave, _Mutex.new);

  static final Map<String, _Mutex> _mutexes = {};

  @visibleForTesting
  static set chaveDeTeste(SecretKey? value) {
    _chaveDeTeste = value;
    _chaveBancoFuture = null;
  }

  @visibleForTesting
  static set usarSqliteDeTeste(bool? valor) => _usarSqliteDeTeste = valor;

  @visibleForTesting
  static Future<void> resetarParaTeste() async {
    final aberto = _databaseFuture;
    if (aberto != null) {
      try {
        await (await aberto).close();
      } catch (_) {
        // O banco ainda pode não ter sido inicializado pelo factory de teste.
      }
    }
    _databaseFuture = null;
    _chaveBancoFuture = null;
    _mutexes.clear();
    final diretorio = await getDatabasesPath();
    await deleteDatabase(p.join(diretorio, 'geosync_local.db'));
  }

  final String chave;
  final _Mutex _mutex;

  Future<List<Map<String, dynamic>>> ler() => _mutex.run(_ler);

  Future<void> gravar(List<Map<String, dynamic>> itens) =>
      _mutex.run(() => _gravar(itens));

  /// Lê, transforma e grava de forma atômica em relação a outras chamadas.
  Future<T> atualizar<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> itens) alterar,
  ) => _mutex.run(() async {
    final itens = await _ler();
    final resultado = await alterar(itens);
    await _gravar(itens);
    return resultado;
  });

  Future<List<Map<String, dynamic>>> _ler() async {
    if (_usaSqlite) {
      final db = await _abrirBanco();
      final registros = await db.query(
        'registros_locais',
        columns: ['payload'],
        where: 'store_key = ?',
        whereArgs: [chave],
        orderBy: 'item_index ASC',
      );
      if (registros.isNotEmpty) {
        final itens = <Map<String, dynamic>>[];
        for (var i = 0; i < registros.length; i++) {
          final payload = registros[i]['payload']! as String;
          final claro = await _desproteger(payload);
          final decoded = jsonDecode(claro);
          if (decoded is Map) itens.add(Map<String, dynamic>.from(decoded));
          if (!payload.startsWith('enc:v1:')) {
            await db.update(
              'registros_locais',
              {'payload': await _proteger(claro)},
              where: 'store_key = ? AND item_index = ?',
              whereArgs: [chave, i],
            );
          }
        }
        return itens;
      }
      // Migração preguiçosa: mantém a fonte antiga até a transação SQL
      // terminar, para que uma falha nunca apague dados ainda não copiados.
      final prefs = await SharedPreferences.getInstance();
      final legado = prefs.getString(chave);
      if (legado == null) return [];
      final itens = _decodificar(legado);
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var i = 0; i < itens.length; i++) {
          batch.insert('registros_locais', {
            'store_key': chave,
            'item_index': i,
            'payload': await _proteger(jsonEncode(itens[i])),
          });
        }
        await batch.commit(noResult: true);
      });
      await prefs.remove(chave);
      return itens;
    }
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(chave);
    if (salvo == null) return [];
    final claro = await _desproteger(salvo);
    final itens = _decodificar(claro);
    if (!salvo.startsWith('enc:v1:') && itens.isNotEmpty) {
      await prefs.setString(chave, await _proteger(salvo));
    }
    return itens;
  }

  Future<void> _gravar(List<Map<String, dynamic>> itens) async {
    if (_usaSqlite) {
      final db = await _abrirBanco();
      await db.transaction((txn) async {
        await txn.delete(
          'registros_locais',
          where: 'store_key = ?',
          whereArgs: [chave],
        );
        if (itens.isEmpty) return;
        final batch = txn.batch();
        for (var i = 0; i < itens.length; i++) {
          batch.insert('registros_locais', {
            'store_key': chave,
            'item_index': i,
            'payload': await _proteger(jsonEncode(itens[i])),
          });
        }
        await batch.commit(noResult: true);
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (itens.isEmpty) {
      await prefs.remove(chave);
    } else {
      await prefs.setString(chave, await _proteger(jsonEncode(itens)));
    }
  }

  List<Map<String, dynamic>> _decodificar(String salvo) {
    try {
      final decoded = jsonDecode(salvo);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on FormatException {
      return [];
    }
  }
}

/// Armazena localmente os pontos de GPS capturados.
class LocationStore {
  LocationStore({this.limite = 5000})
    : _store = JsonListStore('geosync_pontos_localizacao');

  static final instance = LocationStore();

  /// Máximo de pontos mantidos no aparelho. Ao exceder, os pontos já
  /// sincronizados mais antigos são descartados primeiro.
  final int limite;
  final JsonListStore _store;

  Future<void> adicionar(LocationPoint ponto) => _store.atualizar((itens) {
    itens.add(ponto.toJson());
    _aplicarLimite(itens);
  });

  Future<List<LocationPoint>> todos() async =>
      (await _store.ler()).map(LocationPoint.fromJson).nonNulls.toList()
        ..sort((a, b) => a.registradoEm.compareTo(b.registradoEm));

  Future<List<LocationPoint>> pendentes({int? limite}) async {
    final lista = (await todos()).where((p) => !p.sincronizado);
    return (limite == null ? lista : lista.take(limite)).toList();
  }

  Future<int> contarPendentes() async =>
      (await _store.ler()).where((p) => p['sincronizado'] != true).length;

  Future<void> marcarSincronizados(Iterable<String> ids) {
    final conjunto = ids.toSet();
    if (conjunto.isEmpty) return Future.value();
    return _store.atualizar((itens) {
      for (final item in itens) {
        if (conjunto.contains(item['id'])) item['sincronizado'] = true;
      }
    });
  }

  /// Remove pontos já enviados, registrados antes de [antesDe].
  Future<int> limparSincronizados({DateTime? antesDe}) =>
      _store.atualizar((itens) {
        final tamanhoInicial = itens.length;
        itens.removeWhere((item) {
          if (item['sincronizado'] != true) return false;
          if (antesDe == null) return true;
          final data = DateTime.tryParse('${item['registrado_em']}');
          return data != null && data.isBefore(antesDe);
        });
        return tamanhoInicial - itens.length;
      });

  Future<void> limparTudo() => _store.gravar([]);

  void _aplicarLimite(List<Map<String, dynamic>> itens) {
    var excesso = itens.length - limite;
    if (excesso <= 0) return;
    // Primeiro descarta os sincronizados mais antigos…
    itens.removeWhere((item) {
      if (excesso <= 0 || item['sincronizado'] != true) return false;
      excesso--;
      return true;
    });
    // Pontos ainda não enviados são dados operacionais: nunca os descarte
    // silenciosamente. Falhe a gravação para que a captura possa ser
    // registrada como erro e investigada, preservando todos os pendentes.
    if (excesso > 0) {
      throw StateError(
        'Limite local atingido; existem $excesso pontos de GPS pendentes. '
        'Sincronize antes de capturar mais pontos.',
      );
    }
  }
}

/// Preferência de retenção para pontos de GPS que já foram sincronizados.
class DataRetentionPolicy {
  DataRetentionPolicy._();

  static const opcoesEmDias = [1, 7, 30];
  static const _chave = 'geosync_retencao_gps_dias';
  static final dias = ValueNotifier<int>(7);

  static Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getInt(_chave) ?? 7;
    dias.value = opcoesEmDias.contains(valor) ? valor : 7;
  }

  static Future<void> salvar(int valor) async {
    if (!opcoesEmDias.contains(valor)) {
      throw ArgumentError.value(valor, 'valor', 'Retenção não permitida.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chave, valor);
    dias.value = valor;
  }
}
