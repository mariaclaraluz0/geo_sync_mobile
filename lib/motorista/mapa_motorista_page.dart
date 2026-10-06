import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/rota_otimizacao_service.dart';
import 'package:mobile/sync/background_location_service.dart';
import 'package:mobile/widgets/responsive_content.dart';

class MapaMotoristaPage extends StatefulWidget {
  const MapaMotoristaPage({super.key, this.remessaInicial});
  final String? remessaInicial;

  @override
  State<MapaMotoristaPage> createState() => _MapaMotoristaPageState();
}

class _MapaMotoristaPageState extends State<MapaMotoristaPage> {
  static const _azul = Color(0xFF0C46FF);
  late String _selecionada;
  List<_Remessa> _remessas = [];
  bool _carregandoRemessas = true;
  bool _falhaRemessas = false;
  latlong2.LatLng? _localizacao;
  final MapController _mapController = MapController();
  final _rastreamento = BackgroundLocationService.instance;

  @override
  void initState() {
    super.initState();
    _selecionada = widget.remessaInicial ?? '';
    _carregarLocalizacao();
    final ultimo = _rastreamento.ultimaPosicao.value;
    if (ultimo != null) {
      _localizacao = latlong2.LatLng(ultimo.latitude, ultimo.longitude);
    }
    _rastreamento.ativo.addListener(_aoMudarRastreamento);
    _rastreamento.ultimaPosicao.addListener(_aoReceberPosicao);
    _carregarRemessas();
  }

  @override
  void dispose() {
    _rastreamento.ativo.removeListener(_aoMudarRastreamento);
    _rastreamento.ultimaPosicao.removeListener(_aoReceberPosicao);
    super.dispose();
  }

  Future<void> _carregarRemessas() async {
    if (mounted) {
      setState(() {
        _carregandoRemessas = true;
        _falhaRemessas = false;
      });
    }
    try {
      final dados = await ApiService.instance.minhasRemessas(
        forceRefresh: true,
      );
      final remessas = dados
          .whereType<Map>()
          .map(_Remessa.fromApi)
          .where((r) => r.ativa)
          .toList();
      if (!mounted) return;
      setState(() {
        _remessas = remessas;
        _carregandoRemessas = false;
        _selecionada = _remessas.any((r) => r.codigo == _selecionada)
            ? _selecionada
            : _remessas.isEmpty
            ? ''
            : _remessas.first.codigo;
      });
    } on ApiException {
      if (mounted) {
        setState(() {
          _carregandoRemessas = false;
          _falhaRemessas = true;
        });
      }
    }
  }

  Future<void> _carregarLocalizacao() async {
    try {
      final locais = await ApiService.instance.localizacoes();
      final validas = locais
          .whereType<Map>()
          .where(
            (item) => item['latitude'] != null && item['longitude'] != null,
          )
          .toList();
      validas.sort((a, b) {
        final dataA = DateTime.tryParse(
          '${a['registrado_em'] ?? a['created_at'] ?? ''}',
        );
        final dataB = DateTime.tryParse(
          '${b['registrado_em'] ?? b['created_at'] ?? ''}',
        );
        if (dataA == null) return dataB == null ? 0 : 1;
        if (dataB == null) return -1;
        return dataB.compareTo(dataA);
      });
      final local = validas.isEmpty ? <String, dynamic>{} : validas.first;
      final latitude = double.tryParse('${local['latitude']}');
      final longitude = double.tryParse('${local['longitude']}');
      if (!mounted ||
          latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return;
      }
      final dataApi = DateTime.tryParse(
        '${local['registrado_em'] ?? local['created_at'] ?? ''}',
      );
      final pontoAtual = _rastreamento.ultimaPosicao.value;
      if (pontoAtual != null &&
          (dataApi == null || pontoAtual.registradoEm.isAfter(dataApi))) {
        return;
      }
      setState(() => _localizacao = latlong2.LatLng(latitude, longitude));
    } on ApiException {
      // O mapa mantém a rota selecionada mesmo sem localização atual.
    }
  }

  _Remessa? get _remessa {
    for (final item in _remessas) {
      if (item.codigo == _selecionada) return item;
    }
    return null;
  }

  bool get _rastreando => _rastreamento.ativo.value;

  void _aoMudarRastreamento() {
    if (mounted) setState(() {});
  }

  void _aoReceberPosicao() {
    final ponto = _rastreamento.ultimaPosicao.value;
    if (ponto == null || !mounted) return;
    final local = latlong2.LatLng(ponto.latitude, ponto.longitude);
    setState(() => _localizacao = local);
    _mapController.move(local, 14);
  }

  RotaOtimizada _calcularRotaOtimizada() {
    final paradas = _remessas
        .where((item) => item.ativa)
        .map(
          (item) => RotaParada(
            codigo: item.codigo,
            destino: item.destino,
            distanciaKm: _distanciaEmKm(item.distancia),
            status: item.status,
            progresso: item.progresso,
            latitude: item.latitude,
            longitude: item.longitude,
          ),
        )
        .toList();
    return RotaOtimizacaoService.otimizar(
      paradas,
      origemLatitude: _localizacao?.latitude,
      origemLongitude: _localizacao?.longitude,
    );
  }

  double _distanciaEmKm(String valor) {
    final limpeza = valor.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (limpeza.isEmpty) return 0;
    return double.tryParse(limpeza.replaceFirst(',', '.')) ?? 0;
  }

  void _selecionar(_Remessa remessa) {
    setState(() => _selecionada = remessa.codigo);
    if (_rastreando) _rastreamento.trocarRemessa(remessa.id);
  }

  Future<void> _alternarRastreamento() async {
    if (_rastreando) {
      await _rastreamento.parar();
      return;
    }
    final remessa = _remessa;
    if (remessa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma remessa para rastrear.')),
      );
      return;
    }
    final resultado = await _rastreamento.iniciar(remessaId: remessa.id);
    if (!mounted) return;
    final mensagem = switch (resultado) {
      ResultadoRastreamento.iniciado =>
        'Rastreamento ativo. Ele continua mesmo com o app minimizado.',
      ResultadoRastreamento.desativadoNasConfiguracoes =>
        'Ative "Localização" nas Configurações para permitir o rastreamento.',
      ResultadoRastreamento.servicoDesligado =>
        'Ative o serviço de localização para iniciar o rastreamento.',
      ResultadoRastreamento.permissaoNegada =>
        'Permissão de localização não concedida.',
      ResultadoRastreamento.permissaoNegadaPermanentemente =>
        'Permissão de localização bloqueada. Libere-a nas configurações do aparelho.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        action:
            resultado == ResultadoRastreamento.permissaoNegadaPermanentemente
            ? SnackBarAction(
                label: 'Abrir',
                onPressed: Geolocator.openAppSettings,
              )
            : resultado == ResultadoRastreamento.servicoDesligado
            ? SnackBarAction(
                label: 'Ativar',
                onPressed: Geolocator.openLocationSettings,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remessa = _remessa;
    final scheme = Theme.of(context).colorScheme;
    if (remessa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rotas e remessas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _carregandoRemessas ? LucideIcons.refreshCw : LucideIcons.map,
                  size: 36,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _carregandoRemessas
                      ? 'Carregando suas remessas...'
                      : _falhaRemessas
                      ? 'Não foi possível carregar as remessas.'
                      : 'Não há remessas ativas para exibir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_carregandoRemessas && _falhaRemessas) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _carregarRemessas,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rotas e remessas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Acompanhe sua operação',
              style: TextStyle(color: Color(0xFF718096), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Compartilhar localização',
            icon: const Icon(LucideIcons.radio),
            onPressed: () async {
              final local = _localizacao;
              if (local == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A localização ainda não está disponível.'),
                  ),
                );
                return;
              }
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'https://maps.google.com/?q=${local.latitude},${local.longitude}',
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link da localização copiado.')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Centralizar localização',
            icon: const Icon(LucideIcons.locateFixed),
            onPressed: () {
              final local = _localizacao;
              if (local != null) _mapController.move(local, 14);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1280,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _Mapa(
                remessa: remessa,
                controller: _mapController,
                localizacao: _localizacao,
              ),
            ),
            if (_remessas.any((item) => item.ativa))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _RotaOtimizadaCard(rota: _calcularRotaOtimizada()),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Minhas remessas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_remessas.length} ativas',
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _remessas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (_, index) => _CartaoRemessa(
                          remessa: _remessas[index],
                          selecionada: _remessas[index].codigo == _selecionada,
                          onTap: () => _selecionar(_remessas[index]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _alternarRastreamento,
              icon: Icon(
                _rastreando ? LucideIcons.pause : LucideIcons.navigation,
              ),
              label: Text(
                _rastreando ? 'Pausar rastreamento' : 'Iniciar rastreamento',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotaOtimizadaCard extends StatelessWidget {
  const _RotaOtimizadaCard({required this.rota});

  final RotaOtimizada rota;

  @override
  Widget build(BuildContext context) {
    final ordem = rota.ordem.length > 1
        ? rota.ordem
              .map((item) => item.codigo)
              .toList()
              .asMap()
              .entries
              .map((entry) => '${entry.key + 1}. ${entry.value}')
              .join('  •  ')
        : rota.ordem.isEmpty
        ? 'Sem remessas ativas'
        : '1. ${rota.ordem.first.codigo}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.route, color: Color(0xFF0C46FF), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Sugestão de rota',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rota.distanciaTotalKm > 0
                      ? '${rota.distanciaTotalKm.toStringAsFixed(1)} km'
                      : 'Não informado',
                  style: const TextStyle(
                    color: Color(0xFF0C46FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rota.aproximada
                ? 'Estimativa aproximada: localização atual ou coordenadas das remessas indisponíveis.'
                : 'Distâncias em linha reta; o trajeto por ruas pode ser maior.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            ordem,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Destino atual',
                  value: rota.destinoAtual,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricItem(
                  label: 'Próximo',
                  value: rota.proximoDestino,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Tempo estimado',
                  value: rota.tempoEstimadoMin > 0
                      ? '${rota.tempoEstimadoMin} min'
                      : 'Não informado',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricItem(
                  label: 'Paradas',
                  value: '${rota.ordem.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.remessa,
    required this.controller,
    required this.localizacao,
  });
  final _Remessa remessa;
  final MapController controller;
  final latlong2.LatLng? localizacao;

  @override
  Widget build(BuildContext context) {
    final cor = remessa.status == 'Atenção'
        ? const Color(0xFFDC2626)
        : remessa.status == 'Aguardando coleta'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF16A34A);
    final destino = remessa.latitude != null && remessa.longitude != null
        ? latlong2.LatLng(remessa.latitude!, remessa.longitude!)
        : null;
    final centro = localizacao ?? destino;
    if (centro == null) {
      return Container(
        height: (MediaQuery.sizeOf(context).height * 0.34).clamp(160.0, 260.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aguardando coordenadas do GPS ou da remessa para carregar o mapa.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      // Proporcional à tela: 260 px em celulares comuns, menos nos pequenos.
      height: (MediaQuery.sizeOf(context).height * 0.34).clamp(160.0, 260.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECE5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: centro,
              initialZoom: localizacao == null ? 12 : 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.geosync.mobile',
              ),
              if (localizacao != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: localizacao!,
                      width: 46,
                      height: 46,
                      child: _Marcador(
                        icone: LucideIcons.truck,
                        cor: const Color(0xFF0C46FF),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A172033),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.truck,
                      color: Color(0xFF0C46FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remessa.codigo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remessa.destino,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        remessa.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${remessa.distancia} • chegada ${remessa.previsao}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.icone, required this.cor});
  final IconData icone;
  final Color cor;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: cor,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: cor.withValues(alpha: .35), blurRadius: 10)],
    ),
    child: Icon(icone, color: Colors.white, size: 21),
  );
}

class _CartaoRemessa extends StatelessWidget {
  const _CartaoRemessa({
    required this.remessa,
    required this.selecionada,
    required this.onTap,
  });
  final _Remessa remessa;
  final bool selecionada;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selecionada ? const Color(0xFFE9EEFF) : const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selecionada
                ? const Color(0xFF0C46FF)
                : const Color(0xFFE8ECF3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 40,
              decoration: BoxDecoration(
                color: remessa.status == 'Atenção'
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF0C46FF),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remessa.codigo,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    remessa.rota,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: remessa.progresso,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF0C46FF),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF718096)),
          ],
        ),
      ),
    ),
  );
}

class _Remessa {
  const _Remessa(
    this.codigo,
    this.destino,
    this.rota,
    this.distancia,
    this.previsao,
    this.status,
    this.progresso, {
    this.id,
    this.latitude,
    this.longitude,
  });
  factory _Remessa.fromApi(Map value) {
    final progress = value['progresso'] ?? value['progress'] ?? 0;
    return _Remessa(
      '${value['codigo'] ?? value['code'] ?? value['id'] ?? '-'}',
      '${value['destino'] ?? value['destination'] ?? '-'}',
      '${value['rota'] ?? value['origem'] ?? value['origin'] ?? '-'} → ${value['destino'] ?? value['destination'] ?? '-'}',
      '${value['distancia'] ?? value['distance'] ?? '-'}',
      '${value['eta'] ?? value['previsao_entrega'] ?? '-'}',
      '${value['status'] ?? value['situacao'] ?? 'Aguardando coleta'}',
      progress is num ? progress.toDouble().clamp(0, 1).toDouble() : 0,
      id: value['id'] ?? value['remessa_id'],
      latitude: _coordenada(value['latitude'] ?? value['lat']),
      longitude: _coordenada(
        value['longitude'] ?? value['lng'] ?? value['lon'],
      ),
    );
  }
  final String codigo, destino, rota, distancia, previsao, status;
  final double progresso;
  final Object? id;
  final double? latitude, longitude;
  bool get ativa =>
      !{'entregue', 'cancelada'}.contains(status.trim().toLowerCase());

  static double? _coordenada(Object? valor) =>
      valor is num ? valor.toDouble() : double.tryParse('${valor ?? ''}');
}
