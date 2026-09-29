import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/location_point.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parâmetros de captura, derivados do modo de economia de bateria.
@immutable
class ConfiguracaoCaptura {
  const ConfiguracaoCaptura({required this.economia});

  final bool economia;

  /// Distância mínima (m) entre leituras entregues pelo sistema.
  int get filtroDistancia => economia ? 60 : 20;

  /// Intervalo mínimo entre pontos gravados.
  Duration get intervaloMinimo => Duration(seconds: economia ? 60 : 15);

  /// Intervalo entre envios ao servidor durante o rastreamento.
  Duration get intervaloEnvio => Duration(seconds: economia ? 120 : 30);

  /// Leituras com precisão pior que isso (m) são descartadas.
  double get precisaoMaxima => 100;
}

enum ResultadoRastreamento {
  iniciado,
  desativadoNasConfiguracoes,
  servicoDesligado,
  permissaoNegada,
  permissaoNegadaPermanentemente,
}

/// Fonte de posições. Em produção usa o [Geolocator]; nos testes é trocada
/// por uma stream controlada.
typedef FonteDeLocalizacao =
    Stream<LocationPoint> Function(ConfiguracaoCaptura config);

typedef VerificadorDePermissao = Future<ResultadoRastreamento> Function();

/// Captura a localização do motorista mesmo com o app em segundo plano.
///
/// - **Android**: roda como *foreground service* (notificação fixa
///   "GeoSync está rastreando"), que o sistema não encerra ao minimizar o
///   app e não exige a permissão de localização "o tempo todo".
/// - **iOS**: usa `allowsBackgroundLocationUpdates` com o indicador azul na
///   barra de status (requer `UIBackgroundModes: location`).
///
/// Cada leitura é gravada no [LocationStore] antes de qualquer envio, então
/// nada se perde sem internet; o envio acontece em lotes pelo [SyncEngine].
class BackgroundLocationService {
  BackgroundLocationService({
    FonteDeLocalizacao? fonte,
    VerificadorDePermissao? verificarPermissao,
    LocationStore? store,
    SyncEngine? sync,
    DateTime Function()? relogio,
  }) : _fonte = fonte ?? _fonteGeolocator,
       _verificarPermissao = verificarPermissao ?? _permissaoGeolocator,
       _store = store ?? LocationStore.instance,
       _sync = sync ?? SyncEngine.instance,
       _relogio = relogio ?? DateTime.now;

  static final instance = BackgroundLocationService();

  static const _ativoKey = 'geosync_rastreamento_ativo';
  static const _remessaKey = 'geosync_rastreamento_remessa';

  final FonteDeLocalizacao _fonte;
  final VerificadorDePermissao _verificarPermissao;
  final LocationStore _store;
  final SyncEngine _sync;
  final DateTime Function() _relogio;

  final ativo = ValueNotifier<bool>(false);
  final ultimaPosicao = ValueNotifier<LocationPoint?>(null);
  final erro = ValueNotifier<String?>(null);

  StreamSubscription<LocationPoint>? _assinatura;
  String? _remessaId;
  LocationPoint? _ultimoGravado;
  DateTime? _ultimoEnvio;
  bool _ouvindoSessao = false;

  String? get remessaId => _remessaId;

  Future<ResultadoRastreamento> iniciar({Object? remessaId}) async {
    _remessaId = remessaId?.toString();
    if (ativo.value) {
      await _salvarEstado();
      return ResultadoRastreamento.iniciado;
    }
    if (!AppSession.configuracoesMotorista.value.localizacao) {
      return ResultadoRastreamento.desativadoNasConfiguracoes;
    }
    final permissao = await _verificarPermissao();
    if (permissao != ResultadoRastreamento.iniciado) return permissao;

    _ouvirMudancas();
    _iniciarStream();
    ativo.value = true;
    erro.value = null;
    await _salvarEstado();
    return ResultadoRastreamento.iniciado;
  }

  /// Associa os próximos pontos a outra remessa sem reiniciar o GPS.
  Future<void> trocarRemessa(Object? remessaId) async {
    _remessaId = remessaId?.toString();
    if (ativo.value) await _salvarEstado();
  }

  Future<void> parar() async {
    await _assinatura?.cancel();
    _assinatura = null;
    _ultimoGravado = null;
    final estavaAtivo = ativo.value;
    ativo.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ativoKey);
    await prefs.remove(_remessaKey);
    if (estavaAtivo) unawaited(_enviar());
  }

  /// Retoma o rastreamento se ele estava ativo quando o app foi fechado.
  Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_ativoKey) != true) return;
    if (!AppSession.autenticada || AppSession.tipoUsuario != 'Motorista') {
      await parar();
      return;
    }
    final resultado = await iniciar(remessaId: prefs.getString(_remessaKey));
    if (resultado != ResultadoRastreamento.iniciado) await parar();
  }

  void _iniciarStream() {
    final config = ConfiguracaoCaptura(
      economia: AppSession.configuracoesMotorista.value.modoEconomia,
    );
    _assinatura = _fonte(config).listen(
      (ponto) => unawaited(_receber(ponto, config)),
      onError: (Object e) {
        debugPrint('[GPS] erro: $e');
        erro.value = e is PermissionDeniedException
            ? 'A permissão de localização foi revogada.'
            : 'Falha ao obter a localização.';
        if (e is PermissionDeniedException) unawaited(parar());
      },
    );
  }

  Future<void> _receber(
    LocationPoint leitura,
    ConfiguracaoCaptura config,
  ) async {
    if ((leitura.precisao ?? 0) > config.precisaoMaxima) return;
    if (!_deveGravar(leitura, config)) return;

    final ponto = LocationPoint.capturado(
      latitude: leitura.latitude,
      longitude: leitura.longitude,
      registradoEm: leitura.registradoEm,
      remessaId: _remessaId,
      precisao: leitura.precisao,
      altitude: leitura.altitude,
      velocidade: leitura.velocidade,
      direcao: leitura.direcao,
    );
    _ultimoGravado = ponto;
    ultimaPosicao.value = ponto;
    await _store.adicionar(ponto);

    final agora = _relogio();
    if (_ultimoEnvio == null ||
        agora.difference(_ultimoEnvio!) >= config.intervaloEnvio) {
      _ultimoEnvio = agora;
      await _enviar();
    } else {
      await _sync.atualizarContadores();
    }
  }

  /// Grava se passou o intervalo mínimo ou se houve deslocamento grande
  /// (ex.: curvas em alta velocidade), evitando pontos redundantes.
  bool _deveGravar(LocationPoint leitura, ConfiguracaoCaptura config) {
    final anterior = _ultimoGravado;
    if (anterior == null) return true;
    final tempo = leitura.registradoEm.difference(anterior.registradoEm);
    if (tempo >= config.intervaloMinimo) return true;
    final distancia = Geolocator.distanceBetween(
      anterior.latitude,
      anterior.longitude,
      leitura.latitude,
      leitura.longitude,
    );
    return distancia >= config.filtroDistancia * 5;
  }

  Future<void> _enviar() async {
    try {
      await _sync.enviarPontos();
    } catch (e) {
      debugPrint('[GPS] envio adiado: $e');
    } finally {
      await _sync.atualizarContadores();
    }
  }

  Future<void> _salvarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ativoKey, true);
    if (_remessaId == null) {
      await prefs.remove(_remessaKey);
    } else {
      await prefs.setString(_remessaKey, _remessaId!);
    }
  }

  /// Para automaticamente ao sair da conta ou desligar a localização.
  void _ouvirMudancas() {
    if (_ouvindoSessao) return;
    _ouvindoSessao = true;
    AppSession.sessaoAtualizada.addListener(() {
      if (!AppSession.autenticada && ativo.value) unawaited(parar());
    });
    var economiaAtual = AppSession.configuracoesMotorista.value.modoEconomia;
    AppSession.configuracoesMotorista.addListener(() {
      final config = AppSession.configuracoesMotorista.value;
      if (!ativo.value) return;
      if (!config.localizacao) {
        unawaited(parar());
      } else if (config.modoEconomia != economiaAtual) {
        // Reinicia o GPS com a nova frequência de captura.
        unawaited(_assinatura?.cancel());
        _iniciarStream();
      }
      economiaAtual = config.modoEconomia;
    });
  }

  // ============================================================
  // IMPLEMENTAÇÃO PADRÃO (GEOLOCATOR)
  // ============================================================

  static Future<ResultadoRastreamento> _permissaoGeolocator() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return ResultadoRastreamento.servicoDesligado;
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    return switch (permissao) {
      LocationPermission.deniedForever =>
        ResultadoRastreamento.permissaoNegadaPermanentemente,
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        ResultadoRastreamento.permissaoNegada,
      _ => ResultadoRastreamento.iniciado,
    };
  }

  static Stream<LocationPoint> _fonteGeolocator(ConfiguracaoCaptura config) {
    final precisao = config.economia
        ? LocationAccuracy.medium
        : LocationAccuracy.high;
    final LocationSettings settings;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: precisao,
        distanceFilter: config.filtroDistancia,
        intervalDuration: config.intervaloMinimo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GeoSync está rastreando sua entrega',
          notificationText:
              'Sua localização é enviada ao cliente enquanto a entrega estiver ativa.',
          notificationChannelName: 'Rastreamento de entregas',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: precisao,
        distanceFilter: config.filtroDistancia,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: config.economia,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: precisao,
        distanceFilter: config.filtroDistancia,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => LocationPoint(
        id: '',
        latitude: p.latitude,
        longitude: p.longitude,
        registradoEm: p.timestamp.toUtc(),
        precisao: p.accuracy,
        altitude: p.altitude,
        velocidade: p.speed,
        direcao: p.heading,
      ),
    );
  }
}
