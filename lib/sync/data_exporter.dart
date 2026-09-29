import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum FormatoExportacao {
  csv('CSV', 'csv', 'text/csv'),
  geoJson('GeoJSON', 'geojson', 'application/geo+json');

  const FormatoExportacao(this.nome, this.extensao, this.mimeType);

  final String nome;
  final String extensao;
  final String mimeType;
}

enum ConjuntoExportacao { localizacoes, remessas }

/// Converte os dados do GeoSync para CSV (planilhas) e GeoJSON (mapas/GIS).
class DataExporter {
  const DataExporter();

  static const _colunasPontos = [
    'id',
    'remessa_id',
    'latitude',
    'longitude',
    'precisao_m',
    'altitude_m',
    'velocidade_ms',
    'direcao_graus',
    'registrado_em_utc',
    'sincronizado',
  ];

  // ============================================================
  // CSV
  // ============================================================

  /// CSV conforme RFC 4180, com BOM UTF-8 para o Excel abrir os acentos.
  String pontosParaCsv(List<LocationPoint> pontos) {
    final linhas = <List<Object?>>[
      _colunasPontos,
      for (final p in pontos)
        [
          p.id,
          p.remessaId,
          p.latitude,
          p.longitude,
          p.precisao,
          p.altitude,
          p.velocidade,
          p.direcao,
          p.registradoEm.toIso8601String(),
          p.sincronizado ? 'sim' : 'nao',
        ],
    ];
    return _csv(linhas);
  }

  String remessasParaCsv(List<Map<String, dynamic>> remessas) {
    const preferidas = [
      'id',
      'codigo',
      'status',
      'origem',
      'destino',
      'previsao_entrega',
      'updated_at',
    ];
    final colunas = <String>[
      ...preferidas.where((c) => remessas.any((r) => r.containsKey(c))),
      ...{
        for (final r in remessas)
          for (final entrada in r.entries)
            if (entrada.value is! Map && entrada.value is! List) entrada.key,
      }.where((c) => !preferidas.contains(c)),
    ];
    return _csv([
      colunas,
      for (final r in remessas) [for (final c in colunas) r[c]],
    ]);
  }

  /// Marca de ordem de bytes UTF-8, para o Excel reconhecer os acentos.
  static final _bom = String.fromCharCode(0xFEFF);

  String _csv(List<List<Object?>> linhas) =>
      '$_bom${linhas.map((l) => l.map(_celula).join(',')).join('\r\n')}\r\n';

  String _celula(Object? valor) {
    if (valor == null) return '';
    if (valor is num) return valor.toString();
    var texto = '$valor';
    // Evita injeção de fórmulas ao abrir o arquivo em planilhas.
    if (texto.isNotEmpty && '=+-@\t\r'.contains(texto[0])) texto = "'$texto";
    if (texto.contains(RegExp(r'[",\r\n]'))) {
      return '"${texto.replaceAll('"', '""')}"';
    }
    return texto;
  }

  // ============================================================
  // GEOJSON
  // ============================================================

  /// `FeatureCollection` (RFC 7946) com um `Point` por leitura e uma
  /// `LineString` com o trajeto de cada remessa. Coordenadas em
  /// `[longitude, latitude]`, conforme a especificação.
  Map<String, dynamic> pontosParaGeoJson(List<LocationPoint> pontos) {
    final ordenados = [...pontos]
      ..sort((a, b) => a.registradoEm.compareTo(b.registradoEm));
    final trajetos = <String, List<LocationPoint>>{};
    for (final p in ordenados) {
      trajetos.putIfAbsent(p.remessaId ?? 'sem_remessa', () => []).add(p);
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final entrada in trajetos.entries)
          if (entrada.value.length >= 2)
            {
              'type': 'Feature',
              'geometry': {
                'type': 'LineString',
                'coordinates': [for (final p in entrada.value) _coordenadas(p)],
              },
              'properties': {
                'tipo': 'trajeto',
                'remessa_id': entrada.key == 'sem_remessa' ? null : entrada.key,
                'pontos': entrada.value.length,
                'inicio': entrada.value.first.registradoEm.toIso8601String(),
                'fim': entrada.value.last.registradoEm.toIso8601String(),
              },
            },
        for (final p in ordenados)
          {
            'type': 'Feature',
            'id': p.id,
            'geometry': {'type': 'Point', 'coordinates': _coordenadas(p)},
            'properties': {
              'tipo': 'leitura',
              'remessa_id': p.remessaId,
              'registrado_em': p.registradoEm.toIso8601String(),
              'precisao_m': p.precisao,
              'velocidade_ms': p.velocidade,
              'direcao_graus': p.direcao,
              'sincronizado': p.sincronizado,
            },
          },
      ],
    };
  }

  /// Remessas com coordenadas de origem/destino viram `Point`s; as demais
  /// entram com `geometry: null`, permitido pela RFC 7946.
  Map<String, dynamic> remessasParaGeoJson(
    List<Map<String, dynamic>> remessas,
  ) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final r in remessas)
          {
            'type': 'Feature',
            'id': r['id'],
            'geometry': _geometriaRemessa(r),
            'properties': {
              for (final e in r.entries)
                if (e.value is! Map && e.value is! List) e.key: e.value,
            },
          },
      ],
    };
  }

  Map<String, dynamic>? _geometriaRemessa(Map<String, dynamic> r) {
    List<double>? ponto(String lat, String lng) {
      final latitude = double.tryParse('${r[lat] ?? ''}');
      final longitude = double.tryParse('${r[lng] ?? ''}');
      return latitude == null || longitude == null
          ? null
          : [longitude, latitude];
    }

    final pontos = [
      ?ponto('origem_latitude', 'origem_longitude'),
      ?ponto('latitude', 'longitude'),
      ?ponto('destino_latitude', 'destino_longitude'),
    ];
    if (pontos.isEmpty) return null;
    if (pontos.length == 1) return {'type': 'Point', 'coordinates': pontos[0]};
    return {'type': 'MultiPoint', 'coordinates': pontos};
  }

  List<double> _coordenadas(LocationPoint p) => [
    p.longitude,
    p.latitude,
    ?p.altitude,
  ];

  String geoJsonParaTexto(Map<String, dynamic> geoJson) =>
      const JsonEncoder.withIndent('  ').convert(geoJson);
}

/// Resultado de uma exportação para exibir ao usuário.
class ResultadoExportacao {
  const ResultadoExportacao({
    required this.registros,
    required this.nomeArquivo,
    required this.compartilhado,
    this.caminho,
  });

  final int registros;
  final String nomeArquivo;

  /// `true` quando o arquivo foi salvo ou compartilhado; `false` quando o
  /// usuário cancelou ou não havia dados.
  final bool compartilhado;

  /// Onde o arquivo foi salvo (apenas em "Salvar arquivo" no computador).
  final String? caminho;
}

/// Escolhe onde salvar o arquivo. Devolve `null` se o usuário cancelar.
typedef EscolherDestino =
    Future<String?> Function(String nomeSugerido, FormatoExportacao formato);

/// Gera o arquivo e o salva no computador ou abre o compartilhamento do
/// sistema (celular).
class ExportService {
  ExportService({
    DataExporter exporter = const DataExporter(),
    LocationStore? pontos,
    SyncEngine? sync,
    EscolherDestino? escolherDestino,
  }) : _exporter = exporter,
       _pontos = pontos ?? LocationStore.instance,
       _sync = sync ?? SyncEngine.instance,
       _escolherDestino = escolherDestino ?? _dialogoSalvar;

  static final instance = ExportService();

  final DataExporter _exporter;
  final LocationStore _pontos;
  final SyncEngine _sync;
  final EscolherDestino _escolherDestino;

  static bool get _desktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// "Salvar arquivo": computador (diálogo Salvar como) e navegador
  /// (download).
  static bool get podeSalvar => kIsWeb || _desktop;

  /// Compartilhamento pelo sistema. No navegador o suporte a arquivos varia,
  /// então lá usamos apenas o download.
  static bool get podeCompartilhar =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.linux;

  /// Quantos registros cada conjunto tem agora no aparelho.
  Future<int> contar(ConjuntoExportacao conjunto) async => switch (conjunto) {
    ConjuntoExportacao.localizacoes => (await _pontos.todos()).length,
    ConjuntoExportacao.remessas => (await _sync.remessasLocais()).length,
  };

  /// Tenta baixar as remessas mais recentes antes de exportar. Sem internet,
  /// segue com o que já está salvo no aparelho.
  Future<void> atualizarRemessas() async {
    try {
      await _sync.sincronizar().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[Export] usando remessas locais: $e');
    }
  }

  /// Monta o conteúdo do arquivo sem compartilhar (útil para testes).
  Future<({String conteudo, int registros})> gerar(
    ConjuntoExportacao conjunto,
    FormatoExportacao formato,
  ) async {
    switch (conjunto) {
      case ConjuntoExportacao.localizacoes:
        final pontos = await _pontos.todos();
        return (
          conteudo: formato == FormatoExportacao.csv
              ? _exporter.pontosParaCsv(pontos)
              : _exporter.geoJsonParaTexto(_exporter.pontosParaGeoJson(pontos)),
          registros: pontos.length,
        );
      case ConjuntoExportacao.remessas:
        final remessas = await _sync.remessasLocais();
        return (
          conteudo: formato == FormatoExportacao.csv
              ? _exporter.remessasParaCsv(remessas)
              : _exporter.geoJsonParaTexto(
                  _exporter.remessasParaGeoJson(remessas),
                ),
          registros: remessas.length,
        );
    }
  }

  /// Salva o arquivo: no computador abre "Salvar como"; no navegador baixa.
  Future<ResultadoExportacao> salvar(
    ConjuntoExportacao conjunto,
    FormatoExportacao formato,
  ) async {
    final dados = await gerar(conjunto, formato);
    final nome = nomeArquivo(conjunto, formato);
    if (dados.registros == 0) return _vazio(nome);
    final arquivo = _arquivo(dados.conteudo, nome, formato);

    if (kIsWeb) {
      // No navegador, saveTo dispara o download do arquivo.
      await arquivo.saveTo(nome);
      return ResultadoExportacao(
        registros: dados.registros,
        nomeArquivo: nome,
        compartilhado: true,
      );
    }
    final destino = await _escolherDestino(nome, formato);
    if (destino == null) {
      return ResultadoExportacao(
        registros: dados.registros,
        nomeArquivo: nome,
        compartilhado: false,
      );
    }
    final caminho = destino.toLowerCase().endsWith('.${formato.extensao}')
        ? destino
        : '$destino.${formato.extensao}';
    await arquivo.saveTo(caminho);
    return ResultadoExportacao(
      registros: dados.registros,
      nomeArquivo: nome,
      compartilhado: true,
      caminho: caminho,
    );
  }

  /// Abre a folha de compartilhamento do sistema com o arquivo gerado.
  Future<ResultadoExportacao> exportar(
    ConjuntoExportacao conjunto,
    FormatoExportacao formato, {
    Rect? origemCompartilhamento,
  }) async {
    final dados = await gerar(conjunto, formato);
    final nome = nomeArquivo(conjunto, formato);
    if (dados.registros == 0) return _vazio(nome);

    final XFile arquivo;
    if (kIsWeb) {
      arquivo = _arquivo(dados.conteudo, nome, formato);
    } else {
      final pasta = await getTemporaryDirectory();
      final file = File('${pasta.path}${Platform.pathSeparator}$nome');
      await file.writeAsBytes(utf8.encode(dados.conteudo), flush: true);
      arquivo = XFile(file.path, name: nome, mimeType: formato.mimeType);
    }

    final resultado = await SharePlus.instance.share(
      ShareParams(
        files: [arquivo],
        fileNameOverrides: [nome],
        subject: 'GeoSync • ${_titulo(conjunto)}',
        sharePositionOrigin: origemCompartilhamento,
      ),
    );
    return ResultadoExportacao(
      registros: dados.registros,
      nomeArquivo: nome,
      compartilhado: resultado.status != ShareResultStatus.dismissed,
    );
  }

  static ResultadoExportacao _vazio(String nome) => ResultadoExportacao(
    registros: 0,
    nomeArquivo: nome,
    compartilhado: false,
  );

  static XFile _arquivo(
    String conteudo,
    String nome,
    FormatoExportacao formato,
  ) => XFile.fromData(
    Uint8List.fromList(utf8.encode(conteudo)),
    name: nome,
    mimeType: formato.mimeType,
  );

  static Future<String?> _dialogoSalvar(
    String nomeSugerido,
    FormatoExportacao formato,
  ) async {
    final local = await getSaveLocation(
      suggestedName: nomeSugerido,
      confirmButtonText: 'Salvar',
      acceptedTypeGroups: [
        XTypeGroup(
          label: formato.nome,
          extensions: [formato.extensao],
          mimeTypes: [formato.mimeType],
        ),
      ],
    );
    return local?.path;
  }

  static String _titulo(ConjuntoExportacao conjunto) =>
      conjunto == ConjuntoExportacao.localizacoes
      ? 'Histórico de localização'
      : 'Remessas';

  /// Ex.: `geosync_localizacoes_20260929_1430.csv`.
  static String nomeArquivo(
    ConjuntoExportacao conjunto,
    FormatoExportacao formato, {
    DateTime? agora,
  }) {
    final data = agora ?? DateTime.now();
    String dois(int v) => v.toString().padLeft(2, '0');
    final carimbo =
        '${data.year}${dois(data.month)}${dois(data.day)}_'
        '${dois(data.hour)}${dois(data.minute)}';
    final prefixo = conjunto == ConjuntoExportacao.localizacoes
        ? 'localizacoes'
        : 'remessas';
    return 'geosync_${prefixo}_$carimbo.${formato.extensao}';
  }
}
