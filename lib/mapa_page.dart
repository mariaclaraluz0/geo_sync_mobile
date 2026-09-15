import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    show
        FlutterMap,
        InteractionOptions,
        InteractiveFlag,
        MapController,
        MapOptions,
        Marker,
        MarkerLayer,
        TileLayer;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class MapaPage extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const MapaPage({super.key, this.currentIndex = 2, this.onTap});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage>
    with SingleTickerProviderStateMixin {
  String _filtroSelecionado = "Todos";
  String? _veiculoSelecionado;
  late AnimationController _pulseController;
  String? _erroLocalizacoes;
  final MapController _mapController = MapController();

  final List<RotaModel> _rotas = [
    RotaModel(
      codigo: "GS-9532",
      origem: "São Paulo",
      destino: "Rio de Janeiro",
      origemSigla: "SP",
      destinoSigla: "RJ",
      status: "Normal",
      cor: Color(0xFF10B981),
      velocidade: "68 km/h",
      atualizacao: "Agora",
      previsao: "14:20",
      motorista: "Carlos Silva",
      posicao: Offset(0.18, 0.28),
    ),
    RotaModel(
      codigo: "GS-6548",
      origem: "Minas Gerais",
      destino: "Rio Grande do Sul",
      origemSigla: "MG",
      destinoSigla: "RS",
      status: "Normal",
      cor: Color(0xFF10B981),
      velocidade: "74 km/h",
      atualizacao: "Há 1 min",
      previsao: "18:45",
      motorista: "Marcos Oliveira",
      posicao: Offset(0.37, 0.58),
    ),
    RotaModel(
      codigo: "GS-4512",
      origem: "São Paulo",
      destino: "Rio de Janeiro",
      origemSigla: "SP",
      destinoSigla: "RJ",
      status: "Atraso",
      cor: Color(0xFFF59E0B),
      velocidade: "42 km/h",
      atualizacao: "Há 2 min",
      previsao: "15:05",
      motorista: "Rafael Santos",
      posicao: Offset(0.59, 0.38),
    ),
    RotaModel(
      codigo: "GS-0811",
      origem: "Pernambuco",
      destino: "Bahia",
      origemSigla: "PE",
      destinoSigla: "BA",
      status: "Alerta",
      cor: Color(0xFFEF4444),
      velocidade: "18 km/h",
      atualizacao: "Há 3 min",
      previsao: "16:30",
      motorista: "João Pereira",
      posicao: Offset(0.78, 0.23),
    ),
    RotaModel(
      codigo: "GS-0206",
      origem: "Brasília",
      destino: "Goiás",
      origemSigla: "DF",
      destinoSigla: "GO",
      status: "Normal",
      cor: Color(0xFF10B981),
      velocidade: "61 km/h",
      atualizacao: "Agora",
      previsao: "13:50",
      motorista: "Lucas Almeida",
      posicao: Offset(0.28, 0.76),
    ),
    RotaModel(
      codigo: "GS-1705",
      origem: "Paraná",
      destino: "Minas Gerais",
      origemSigla: "PR",
      destinoSigla: "MG",
      status: "Normal",
      cor: Color(0xFF10B981),
      velocidade: "79 km/h",
      atualizacao: "Há 1 min",
      previsao: "17:15",
      motorista: "Pedro Costa",
      posicao: Offset(0.67, 0.72),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _carregarLocalizacoes();
  }

  Future<void> _carregarLocalizacoes() async {
    try {
      final resposta = await ApiService.instance.localizacoes();
      final dados = resposta.whereType<Map>().map(_rotaFromApi).toList();
      if (!mounted || dados.isEmpty) return;
      setState(() {
        _rotas
          ..clear()
          ..addAll(dados);
        _erroLocalizacoes = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _erroLocalizacoes = error.message);
    }
  }

  RotaModel _rotaFromApi(Map value) {
    final latitude = value['latitude'] ?? value['lat'];
    final longitude = value['longitude'] ?? value['lng'] ?? value['lon'];
    final latitudeValue = double.tryParse('$latitude');
    final longitudeValue = double.tryParse('$longitude');
    final x = longitudeValue == null
        ? 0.5
        : ((longitudeValue + 180) / 360).clamp(0.08, 0.92);
    final y = latitudeValue == null
        ? 0.5
        : ((90 - latitudeValue) / 180).clamp(0.12, 0.88);
    final status = '${value['status'] ?? 'Normal'}';
    final cor = status.toLowerCase().contains('alerta')
        ? const Color(0xFFEF4444)
        : status.toLowerCase().contains('atras')
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);
    return RotaModel(
      codigo: '${value['codigo'] ?? value['remessa_id'] ?? value['id'] ?? '-'}',
      origem: '${value['origem'] ?? '-'}',
      destino: '${value['destino'] ?? '-'}',
      origemSigla: '${value['origem_sigla'] ?? ''}',
      destinoSigla: '${value['destino_sigla'] ?? ''}',
      status: status,
      cor: cor,
      velocidade: '${value['velocidade'] ?? '-'}',
      atualizacao: '${value['updated_at'] ?? value['created_at'] ?? 'Agora'}',
      previsao: '${value['previsao'] ?? value['eta'] ?? '-'}',
      motorista: '${value['motorista'] ?? value['motorista_nome'] ?? '-'}',
      posicao: Offset(x.toDouble(), y.toDouble()),
      latitude: latitudeValue,
      longitude: longitudeValue,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<RotaModel> get _rotasFiltradas {
    if (_filtroSelecionado == "Alertas") {
      return _rotas
          .where((rota) => rota.status == "Alerta" || rota.status == "Atraso")
          .toList();
    }

    if (_filtroSelecionado == "Em Trânsito") {
      return _rotas.where((rota) => rota.status == "Normal").toList();
    }

    return _rotas;
  }

  int get _normais => _rotas.where((rota) => rota.status == "Normal").length;

  int get _atrasos => _rotas.where((rota) => rota.status == "Atraso").length;

  int get _alertas => _rotas.where((rota) => rota.status == "Alerta").length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            if (_erroLocalizacoes != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  _erroLocalizacoes!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 16),

                  _buildMapCard(),

                  const SizedBox(height: 16),

                  _buildStatusSummary(),

                  const SizedBox(height: 18),

                  _buildFilters(),

                  const SizedBox(height: 18),

                  _buildRoutesHeader(),

                  const SizedBox(height: 10),

                  ..._rotasFiltradas.map((rota) => _buildRouteCard(rota)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CABEÇALHO
  // ================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rastreamento",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_rotas.length} veículos monitorados agora",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            onTap: () async {
              await _carregarLocalizacoes();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text("Localizações atualizadas com sucesso."),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          _buildHeaderButton(
            icon: Icons.more_horiz_rounded,
            onTap: _abrirOpcoesMapa,
            tooltip: 'Mais opções do mapa',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Semantics(
      button: true,
      label: tooltip ?? 'Ação do mapa',
      child: Tooltip(
        message: tooltip ?? 'Ação do mapa',
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: const Color(0xFF334155), size: 20),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirOpcoesMapa() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Atualizar localizações'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _carregarLocalizacoes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong_rounded),
              title: const Text('Centralizar todos os pontos'),
              onTap: () {
                Navigator.pop(sheetContext);
                _centralizarPontos();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Limpar seleção'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _veiculoSelecionado = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _centralizarPontos() {
    final ponto = _rotas.firstWhere(
      (rota) => rota.latitude != null && rota.longitude != null,
      orElse: () => _rotas.first,
    );
    if (ponto.latitude == null || ponto.longitude == null) return;
    _mapController.move(
      latlong2.LatLng(ponto.latitude!, ponto.longitude!),
      6.5,
    );
  }

  void _selecionarRota(RotaModel rota) {
    setState(() => _veiculoSelecionado = rota.codigo);
    if (rota.latitude != null && rota.longitude != null) {
      _mapController.move(latlong2.LatLng(rota.latitude!, rota.longitude!), 10);
    }
  }

  // ================================================================
  // MAPA
  // ================================================================

  Widget _buildMapCard() {
    final scheme = Theme.of(context).colorScheme;
    final pontos = _rotas
        .where((rota) => rota.latitude != null && rota.longitude != null)
        .toList();
    final centro = pontos.isEmpty
        ? const latlong2.LatLng(-14.2350, -51.9253)
        : latlong2.LatLng(pontos.first.latitude!, pontos.first.longitude!);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centro,
              initialZoom: pontos.isEmpty ? 4.2 : 6.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.geosync.mobile',
              ),
              if (pontos.isNotEmpty)
                MarkerLayer(markers: pontos.map(_buildRealMarker).toList()),
            ],
          ),

          // Estado dos dados exibidos
          Positioned(
            top: 14,
            left: 14,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8 + (_pulseController.value * 2),
                        height: 8 + (_pulseController.value * 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        pontos.isEmpty ? 'SEM LOCALIZAÇÕES' : 'DADOS REAIS',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Hora da atualização
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 5),
                  Text(
                    "OpenStreetMap",
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles
          Positioned(
            right: 14,
            bottom: 14,
            child: Column(
              children: [
                _buildMapButton(
                  Icons.add_rounded,
                  () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 7),
                _buildMapButton(
                  Icons.remove_rounded,
                  () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMapButton(
                  Icons.my_location_rounded,
                  () => _mapController.move(centro, pontos.isEmpty ? 4.2 : 6.5),
                  primary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildRealMarker(RotaModel rota) {
    final selecionado = _veiculoSelecionado == rota.codigo;
    final scheme = Theme.of(context).colorScheme;
    return Marker(
      point: latlong2.LatLng(rota.latitude!, rota.longitude!),
      width: selecionado ? 130 : 52,
      height: selecionado ? 78 : 52,
      child: Semantics(
        button: true,
        label: '${rota.codigo}, status ${rota.status}',
        child: GestureDetector(
          onTap: () => _selecionarRota(rota),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: rota.cor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: rota.cor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              if (selecionado)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rota.codigo,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton(
    IconData icon,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    final label = switch (icon) {
      Icons.add_rounded => 'Aumentar zoom',
      Icons.remove_rounded => 'Diminuir zoom',
      _ => 'Centralizar mapa',
    };
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: primary
              ? const Color(0xFF0C46FF)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                color: primary ? Colors.white : const Color(0xFF334155),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // RESUMO
  // ================================================================

  Widget _buildStatusSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusItem(
              icon: Icons.check_circle_rounded,
              label: "Normais",
              value: _normais.toString(),
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatusItem(
              icon: Icons.schedule_rounded,
              label: "Atrasos",
              value: _atrasos.toString(),
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatusItem(
              icon: Icons.warning_rounded,
              label: "Alertas",
              value: _alertas.toString(),
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FILTROS
  // ================================================================

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip("Todos", _rotas.length),
            const SizedBox(width: 8),
            _buildFilterChip("Em Trânsito", _normais),
            const SizedBox(width: 8),
            _buildFilterChip("Alertas", _atrasos + _alertas),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int quantidade) {
    final bool selecionado = _filtroSelecionado == label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: selecionado ? const Color(0xFF0B2A4A) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selecionado ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
        boxShadow: selecionado
            ? [
                BoxShadow(
                  color: const Color(0xFF0C46FF).withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _filtroSelecionado = label;
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selecionado ? Colors.white : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? Colors.white.withValues(alpha: 0.20)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    quantidade.toString(),
                    style: TextStyle(
                      color: selecionado
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CABEÇALHO DA LISTA
  // ================================================================

  Widget _buildRoutesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Veículos em rota",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            "${_rotasFiltradas.length} encontrados",
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARD DA ROTA
  // ================================================================

  Widget _buildRouteCard(RotaModel rota) {
    final bool selecionado = _veiculoSelecionado == rota.codigo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selecionado
              ? const Color(0xFF0C46FF)
              : const Color(0xFFE5EAF0),
          width: selecionado ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selecionado ? 0.07 : 0.035),
            blurRadius: selecionado ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _selecionarRota(rota),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: rota.cor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: rota.cor,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rota.codigo,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            rota.motorista,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildStatusBadge(rota),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    _buildLocationBox(rota.origemSigla, rota.origem),

                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFDCE3EC),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 15,
                                color: rota.cor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFDCE3EC),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rota.previsao,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildLocationBox(
                      rota.destinoSigla,
                      rota.destino,
                      alignEnd: true,
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfo(
                          Icons.speed_rounded,
                          rota.velocidade,
                          "Velocidade",
                        ),
                      ),
                      Expanded(
                        child: _buildInfo(
                          Icons.update_rounded,
                          rota.atualizacao,
                          "Atualização",
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RotaModel rota) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: rota.cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: rota.cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            rota.status,
            style: TextStyle(
              color: rota.cor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBox(String sigla, String nome, {bool alignEnd = false}) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            sigla,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ====================================================================
// MODELO DA ROTA
// ====================================================================

class RotaModel {
  final String codigo;
  final String origem;
  final String destino;
  final String origemSigla;
  final String destinoSigla;
  final String status;
  final Color cor;
  final String velocidade;
  final String atualizacao;
  final String previsao;
  final String motorista;
  final Offset posicao;
  final double? latitude;
  final double? longitude;

  const RotaModel({
    required this.codigo,
    required this.origem,
    required this.destino,
    required this.origemSigla,
    required this.destinoSigla,
    required this.status,
    required this.cor,
    required this.velocidade,
    required this.atualizacao,
    required this.previsao,
    required this.motorista,
    required this.posicao,
    this.latitude,
    this.longitude,
  });
}

// ====================================================================
// MAPA VISUAL
// ====================================================================

class MapaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fundo = Paint()..color = const Color(0xFFEAF0F5);

    canvas.drawRect(Offset.zero & size, fundo);

    // Grade de ruas
    final Paint ruaPrincipal = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final Paint ruaSecundaria = Paint()
      ..color = const Color(0xFFDCE5EC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ruas horizontais
    for (double y = 35; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), ruaPrincipal);
    }

    // Ruas verticais
    for (double x = -50; x < size.width + 50; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x + 70, size.height), ruaPrincipal);
    }

    // Linhas secundárias
    for (double y = 15; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 30), ruaSecundaria);
    }

    // Rodovias destacadas
    final Paint rodovia = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final Path rota1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.25,
        size.width,
        size.height * 0.45,
      );

    canvas.drawPath(rota1, rodovia);

    final Path rota2 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.9,
        size.height,
      );

    canvas.drawPath(rota2, rodovia);

    // Rota azul do GeoSync
    final Paint rotaGeoSync = Paint()
      ..color = const Color(0xFF0C46FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path caminho = Path()
      ..moveTo(size.width * 0.12, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.60,
        size.width * 0.45,
        size.height * 0.68,
        size.width * 0.58,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.20,
        size.width * 0.82,
        size.height * 0.25,
        size.width * 0.94,
        size.height * 0.10,
      );

    canvas.drawPath(caminho, rotaGeoSync);

    // Pequenos blocos simulando áreas urbanas
    final Paint edificios = Paint()..color = const Color(0xFFD8E1E8);

    for (int i = 0; i < 14; i++) {
      final double x = ((i * 83) % (size.width - 30)).toDouble();

      final double y = ((i * 47) % (size.height - 30)).toDouble();

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 18 + (i % 3) * 6, 12 + (i % 2) * 5),
          const Radius.circular(3),
        ),
        edificios,
      );
    }

    // Bússola
    final Paint circulo = Paint()..color = Colors.white.withValues(alpha: 0.9);

    canvas.drawCircle(Offset(size.width - 36, 62), 15, circulo);

    final Paint ponteiro = Paint()
      ..color = const Color(0xFF0C46FF)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width - 36, 55),
      Offset(size.width - 36, 69),
      ponteiro,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
