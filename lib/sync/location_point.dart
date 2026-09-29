import 'dart:math';

/// Uma posição capturada pelo GPS do motorista.
///
/// Cada ponto é salvo localmente antes de ser enviado (offline-first) e
/// carrega um [id] único gerado no aparelho, enviado como `client_id` para
/// que o servidor possa descartar reenvios duplicados.
class LocationPoint {
  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.registradoEm,
    this.remessaId,
    this.precisao,
    this.altitude,
    this.velocidade,
    this.direcao,
    this.sincronizado = false,
  });

  factory LocationPoint.capturado({
    required double latitude,
    required double longitude,
    DateTime? registradoEm,
    String? remessaId,
    double? precisao,
    double? altitude,
    double? velocidade,
    double? direcao,
  }) => LocationPoint(
    id: gerarIdLocal(),
    latitude: latitude,
    longitude: longitude,
    registradoEm: (registradoEm ?? DateTime.now()).toUtc(),
    remessaId: remessaId,
    precisao: precisao,
    altitude: altitude,
    velocidade: velocidade,
    direcao: direcao,
  );

  final String id;
  final String? remessaId;
  final double latitude;
  final double longitude;

  /// Sempre em UTC.
  final DateTime registradoEm;

  /// Raio de precisão em metros.
  final double? precisao;
  final double? altitude;

  /// Velocidade em m/s.
  final double? velocidade;

  /// Direção em graus (0 = norte).
  final double? direcao;
  final bool sincronizado;

  LocationPoint copyWith({bool? sincronizado}) => LocationPoint(
    id: id,
    remessaId: remessaId,
    latitude: latitude,
    longitude: longitude,
    registradoEm: registradoEm,
    precisao: precisao,
    altitude: altitude,
    velocidade: velocidade,
    direcao: direcao,
    sincronizado: sincronizado ?? this.sincronizado,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'remessa_id': remessaId,
    'latitude': latitude,
    'longitude': longitude,
    'registrado_em': registradoEm.toIso8601String(),
    'precisao': precisao,
    'altitude': altitude,
    'velocidade': velocidade,
    'direcao': direcao,
    'sincronizado': sincronizado,
  };

  /// Corpo enviado para `POST /localizacao`.
  Map<String, dynamic> toApi() => {
    'client_id': id,
    'remessa_id': ?_idNumerico(remessaId),
    'latitude': latitude,
    'longitude': longitude,
    'precisao': ?precisao,
    'altitude': ?altitude,
    'velocidade': ?velocidade,
    'direcao': ?direcao,
    'registrado_em': registradoEm.toIso8601String(),
  };

  static LocationPoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final latitude = _double(json['latitude']);
    final longitude = _double(json['longitude']);
    final registradoEm = DateTime.tryParse('${json['registrado_em']}');
    final id = json['id'];
    if (latitude == null ||
        longitude == null ||
        registradoEm == null ||
        id is! String) {
      return null;
    }
    final remessa = json['remessa_id'];
    return LocationPoint(
      id: id,
      remessaId: remessa == null ? null : '$remessa',
      latitude: latitude,
      longitude: longitude,
      registradoEm: registradoEm.toUtc(),
      precisao: _double(json['precisao']),
      altitude: _double(json['altitude']),
      velocidade: _double(json['velocidade']),
      direcao: _double(json['direcao']),
      sincronizado: json['sincronizado'] == true,
    );
  }

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

  /// Mantém IDs numéricos como número no JSON enviado ao Laravel.
  static Object? _idNumerico(String? id) =>
      id == null ? null : (int.tryParse(id) ?? id);
}

final _random = Random.secure();

/// Identificador único gerado no aparelho (tempo + aleatório).
String gerarIdLocal() {
  final tempo = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final aleatorio = List.generate(
    8,
    (_) => _random.nextInt(36).toRadixString(36),
  ).join();
  return '$tempo-$aleatorio';
}
