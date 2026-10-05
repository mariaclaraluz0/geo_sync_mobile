import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Database>? _databaseFuture;

bool get _usaSqlite =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

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
        return registros
            .map((row) => jsonDecode(row['payload']! as String))
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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
            'payload': jsonEncode(itens[i]),
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
    return _decodificar(salvo);
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
            'payload': jsonEncode(itens[i]),
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
      await prefs.setString(chave, jsonEncode(itens));
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
