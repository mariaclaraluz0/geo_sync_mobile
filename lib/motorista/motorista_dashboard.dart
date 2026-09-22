import 'package:flutter/material.dart';

import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/motorista/avisos_motorista_page.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:mobile/motorista/documentos_page.dart';
import 'package:mobile/motorista/entrega_page.dart';
import 'package:mobile/motorista/mapa_motorista_page.dart';
import 'package:mobile/motorista/veiculo_motorista_page.dart';
import 'package:mobile/widgets/responsive_content.dart';

class MotoristaDashboard extends StatefulWidget {
  const MotoristaDashboard({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MotoristaDashboard> createState() => _MotoristaDashboardState();
}

class _MotoristaDashboardState extends State<MotoristaDashboard> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textLight => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get border => Theme.of(context).colorScheme.outlineVariant;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // ============================================================
  // ESTADO
  // ============================================================

  late int _currentIndex;
  List<Remessa> _remessas = [];
  bool _carregandoResumo = true;

  Remessa? get _rotaAtiva {
    for (final remessa in _remessas) {
      if (remessa.status == 'Em rota' || remessa.status == 'Aguardando coleta') return remessa;
    }
    return _remessas.isEmpty ? null : _remessas.first;
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(0, 2).toInt();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final dados = await ApiService.instance.minhasRemessas(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _remessas = dados.whereType<Map>().map((value) {
          final progress = value['progresso'] ?? value['progress'] ?? 0;
          return Remessa(
            codigo: '${value['codigo'] ?? value['code'] ?? value['id'] ?? '-'}',
            status: '${value['status'] ?? value['situacao'] ?? 'Aguardando coleta'}',
            origem: '${value['origem'] ?? value['origin'] ?? '-'}',
            destino: '${value['destino'] ?? value['destination'] ?? '-'}',
            tipo: '${value['tipo'] ?? value['tipo_carga'] ?? '-'}',
            peso: '${value['peso'] ?? value['weight'] ?? '-'}',
            eta: '${value['eta'] ?? value['previsao_entrega'] ?? '-'}',
            progresso: progress is num ? progress.toDouble().clamp(0, 1).toDouble() : 0,
            id: value['id'] ?? value['remessa_id'],
          );
        }).toList();
        _carregandoResumo = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoResumo = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;
          final content = ResponsiveContent(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _getBody(),
              ),
            ),
          );
          if (!desktop) return content;
          return Row(
            children: [
              _buildNavigationRail(),
              VerticalDivider(width: 1, color: border),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 800
          ? _buildBottomNavigation()
          : null,
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _inicio();

      case 2:
        return _perfil();

      default:
        return _inicio();
    }
  }

  void _changePage(int index) {
    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RemessasPage()));
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 18,
      title: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeoSync',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Painel do motorista',
                style: TextStyle(
                  color: textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _notificationButton(),
        const SizedBox(width: 8),
        _profileButton(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_shipping_outlined,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  Widget _notificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AvisosMotoristaPage()));
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_outlined,
                color: Color(0xFF475569),
                size: 22,
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PERFIL NO APP BAR
  // ============================================================

  Widget _profileButton() {
    return GestureDetector(
      onTap: () {
        _changePage(2);
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF0FF), Color(0xFFDDE7FF)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            AppSession.inicialNome,
            style: const TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: border, width: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.dashboard_outlined,
                label: 'Início',
                index: 0,
              ),
              _navItem(
                icon: Icons.local_shipping_outlined,
                label: 'Entregas',
                index: 1,
              ),
              _navItem(
                icon: Icons.account_circle_outlined,
                label: 'Perfil',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail() => NavigationRail(
    selectedIndex: _currentIndex,
    onDestinationSelected: _changePage,
    labelType: NavigationRailLabelType.all,
    leading: const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 24),
      child: Icon(Icons.route_outlined, color: primary),
    ),
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_outlined),
        label: Text('Início'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.local_shipping_outlined),
        selectedIcon: Icon(Icons.local_shipping_outlined),
        label: Text('Entregas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.account_circle_outlined),
        selectedIcon: Icon(Icons.account_circle_outlined),
        label: Text('Perfil'),
      ),
    ],
  );

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _changePage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 23,
                color: selected ? primary : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INÍCIO
  // ============================================================

  Widget _inicio() {
    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        await _carregarResumo();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(),
            const SizedBox(height: 20),
            _cardRota(),
            const SizedBox(height: 24),
            _buildAcoesRapidas(),
            const SizedBox(height: 28),
            _buildResumo(),
            const SizedBox(height: 28),
            _buildProximasParadas(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SAUDAÇÃO
  // ============================================================

  Widget _buildWelcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final greeting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bom dia, ${AppSession.nome.isEmpty ? 'motorista' : AppSession.nome} 👋',
              style: TextStyle(
                color: textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Sua rota de hoje',
              style: TextStyle(
                color: textDark,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [greeting, const SizedBox(height: 10), _buildStatusOnline()],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 12),
            _buildStatusOnline(),
          ],
        );
      },
    );
  }

  Widget _buildStatusOnline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2F4DE)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: success),
          SizedBox(width: 6),
          Text(
            'Online',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DA ROTA
  // ============================================================

  Widget _cardRota() {
    final remessa = _rotaAtiva;
    if (_carregandoResumo) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }
    if (remessa == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(26), border: Border.all(color: border)),
        child: const Column(children: [Icon(Icons.local_shipping_outlined, size: 36), SizedBox(height: 10), Text('Nenhuma entrega ativa hoje')]),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, Color(0xFF123C69), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -70,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.navigation_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'VIAGEM EM ANDAMENTO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      remessa.codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 7, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 6),
                        Text(
                          remessa.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${remessa.origem} → ${remessa.destino}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _routeInfo(
                    icon: Icons.route_outlined,
                    value: '-',
                    label: 'distância',
                  ),
                  const SizedBox(width: 10),
                  _routeInfo(
                    icon: Icons.inventory_2_outlined,
                    value: '${_remessas.where((r) => r.status != 'Entregue').length}',
                    label: 'entregas',
                  ),
                  const SizedBox(width: 10),
                  _routeInfo(
                    icon: Icons.schedule_outlined,
                    value: remessa.eta,
                    label: 'previsão',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MapaMotoristaPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_outlined, size: 19),
                  label: const Text(
                    'Continuar navegação',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 15),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AÇÕES RÁPIDAS
  // ============================================================

  Widget _buildAcoesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acesso rápido',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _acaoRapida(
                icon: Icons.local_shipping_outlined,
                titulo: 'Entregas',
                subtitulo: 'Ver rota',
                cor: primary,
                onTap: () => _changePage(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _acaoRapida(
                icon: Icons.map_outlined,
                titulo: 'Mapa',
                subtitulo: 'Navegação',
                cor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MapaMotoristaPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _acaoRapida(
                icon: Icons.notifications_outlined,
                titulo: 'Avisos',
                subtitulo: 'Atualizações',
                cor: warning,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AvisosMotoristaPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _acaoRapida({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitulo, style: TextStyle(color: textLight, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildResumo() {
    final ativas = _remessas.where((r) => r.status != 'Entregue' && r.status != 'Cancelada').length;
    final entregues = _remessas.where((r) => r.status == 'Entregue').length;
    final emRota = _remessas.where((r) => r.status == 'Em rota').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo do dia',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _resumo(
                icon: Icons.inventory_2_outlined,
                valor: '$ativas',
                legenda: 'ativas',
                cor: primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _resumo(
                icon: Icons.task_alt_outlined,
                valor: '$entregues',
                legenda: 'entregues',
                cor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _resumo(
                icon: Icons.access_time_outlined,
                valor: '$emRota',
                legenda: 'em rota',
                cor: success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resumo({
    required IconData icon,
    required String valor,
    required String legenda,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cor, size: 19),
          ),
          const SizedBox(height: 11),
          Text(
            valor,
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(legenda, style: TextStyle(color: textLight, fontSize: 9)),
        ],
      ),
    );
  }

  // ============================================================
  // PRÓXIMAS PARADAS
  // ============================================================

  Widget _buildProximasParadas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Próximas paradas',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _changePage(1),
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_remessas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma parada programada.'),
          )
        else
          ..._remessas.take(3).toList().asMap().entries.map((entry) {
            final remessa = entry.value;
            final entregue = remessa.status == 'Entregue';
            final cor = entregue ? success : entry.key == 0 ? primary : textLight;
            return _parada(
              numero: '${entry.key + 1}',
              titulo: remessa.destino,
              detalhe: 'Previsão • ${remessa.eta}',
              icon: entregue
                  ? Icons.check_circle_outline
                  : Icons.location_on_outlined,
              status: remessa.status,
              statusColor: cor,
              isFirst: entry.key == 0,
            );
          }),
      ],
    );
  }

  Widget _parada({
    required String numero,
    required String titulo,
    required String detalhe,
    required IconData icon,
    required String status,
    required Color statusColor,
    required bool isFirst,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detalhe, style: TextStyle(color: textLight, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: statusColor, size: 19),
              const SizedBox(height: 5),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFIL
  // ============================================================

  Widget _perfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // AVATAR
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF0FF), Color(0xFFDCE7FF)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.account_circle_outlined, size: 46, color: primary),
          ),

          const SizedBox(height: 12),

          Text(
            AppSession.nome.isEmpty ? 'Motorista' : AppSession.nome,
            style: TextStyle(
              color: textDark,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined, color: success, size: 16),
              const SizedBox(width: 5),
              Text(
                'Motorista • CNH válida',
                style: TextStyle(color: textLight, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // STATUS
          _buildProfileStatus(),

          const SizedBox(height: 18),

          _perfilItem(
            icon: Icons.badge_outlined,
            titulo: 'Documentos',
            subtitulo: 'CNH e documentos do motorista',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentosMotoristaPage(),
                ),
              );
            },
          ),

          _perfilItem(
            icon: Icons.local_shipping_outlined,
            titulo: 'Meu veículo',
            subtitulo: 'Volvo VM 270 • ABC-1D23',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VeiculoMotoristaPage()),
              );
            },
          ),

          _perfilItem(
            icon: Icons.settings_outlined,
            titulo: 'Configurações',
            subtitulo: 'Preferências da conta',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracoesMotoristaPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF6F8FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: success, size: 9),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motorista ativo',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Você está disponível para novas entregas.',
                  style: TextStyle(color: textLight, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: primary, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM DO PERFIL
  // ============================================================

  Widget _perfilItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO SAIR
  // ============================================================

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _sair,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFFFDADA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 21),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.redAccent,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAIR
  // ============================================================

  Future<void> _sair() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {
      // Remove the local credentials if the server is unavailable.
    }
    await AppSession.encerrarSessao();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
