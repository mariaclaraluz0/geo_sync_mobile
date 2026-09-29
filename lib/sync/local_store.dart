import 'dart:async';
import 'dart:convert';

import 'package:mobile/sync/location_point.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Lê e grava listas JSON no SharedPreferences, tolerando dados corrompidos.
class JsonListStore {
  JsonListStore(this.chave);

  final String chave;
  final _mutex = _Mutex();

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
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(chave);
    if (salvo == null) return [];
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

  Future<void> _gravar(List<Map<String, dynamic>> itens) async {
    final prefs = await SharedPreferences.getInstance();
    if (itens.isEmpty) {
      await prefs.remove(chave);
    } else {
      await prefs.setString(chave, jsonEncode(itens));
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
    // …e só então os pendentes mais antigos, para nunca crescer sem limite.
    if (excesso > 0) itens.removeRange(0, excesso);
  }
}
