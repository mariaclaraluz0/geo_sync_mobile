import 'package:flutter/material.dart';

import 'package:mobile/perfil_page.dart';
import 'package:mobile/remessa_page.dart' hide RemessaCard;
import 'package:mobile/mapa_page.dart';
import 'alerta_page.dart';

class TelaDashboard extends StatefulWidget {
  final String tipoUsuario;

  const TelaDashboard({super.key, this.tipoUsuario = 'Cliente'});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _currentIndex = 0;

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textLight => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get border => Theme.of(context).colorScheme.outlineVariant;
  Color get cardColor => Theme.of(context).colorScheme.surface;

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _home();

      case 1:
        return const RemessasPage();

      case 2:
        return const MapaPage();

      case 3:
        return const TelaAlertas();

      case 4:
        return const PerfilClientePage();

      default:
        return _home();
    }
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: _buildAppBar(),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _getBody()),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
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
      titleSpacing: 18,

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GeoSync",
                style: TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Área do cliente",
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
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _notificationButton() {
    return GestureDetector(
      onTap: () => _changePage(3),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_rounded,
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

  Widget _profileButton() {
    return GestureDetector(
      onTap: () => _changePage(4),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            "C",
            style: TextStyle(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                icon: Icons.grid_view_rounded,
                label: "Início",
                index: 0,
              ),

              _navItem(
                icon: Icons.inventory_2_outlined,
                label: "Remessas",
                index: 1,
              ),

              _navItem(icon: Icons.map_outlined, label: "Mapa", index: 2),

              _navItem(
                icon: Icons.warning_amber_rounded,
                label: "Alertas",
                index: 3,
                badge: 3,
              ),

              _navItem(
                icon: Icons.person_outline_rounded,
                label: "Perfil",
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    int? badge,
  }) {
    final selected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
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

                if (badge != null)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          "$badge",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
  // HOME
  // ============================================================

  Widget _home() {
    return RefreshIndicator(
      color: primary,

      onRefresh: () async {
        setState(() {});
      },

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAUDAÇÃO
            _buildWelcome(),

            const SizedBox(height: 18),

            // BUSCA
            _buildSearch(),

            const SizedBox(height: 18),

            // RESUMO DA OPERAÇÃO
            _buildOverviewCard(),

            const SizedBox(height: 22),

            // AÇÕES RÁPIDAS
            _buildQuickActions(),

            const SizedBox(height: 28),

            const SizedBox(height: 12),

            _buildStatistics(),

            const SizedBox(height: 4),

            // MINI MAPA
            _buildMiniMap(),

            const SizedBox(height: 28),

            // ALERTAS
            _buildCriticalAlerts(),

            const SizedBox(height: 28),

            // REMESSAS
            _buildRecentShipments(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bom dia, Theo 👋",
                style: TextStyle(
                  color: textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Tudo sob controle?",
                style: TextStyle(
                  color: textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAFBF1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                "Online",
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUSCA
  // ============================================================

  Widget _buildSearch() {
    return GestureDetector(
      onTap: () {
        _changePage(1);
      },

      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 15),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),

        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 21),

            SizedBox(width: 11),

            Expanded(
              child: Text(
                "Buscar remessa, código ou cidade...",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),

            Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 19),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, Color(0xFF123C69), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.white70,
                    size: 19,
                  ),

                  SizedBox(width: 8),

                  Text(
                    "OPERAÇÃO HOJE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                "284",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),

              const Text(
                "remessas em operação",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 15,
                        ),

                        SizedBox(width: 5),

                        Text(
                          "+12,5%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Text(
                    "vs. semana anterior",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AÇÕES RÁPIDAS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ações rápidas",
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickAction(
                icon: Icons.inventory_2_rounded,
                title: "Remessas",
                subtitle: "Consultar",
                color: primary,
                onTap: () => _changePage(1),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _quickAction(
                icon: Icons.map_rounded,
                title: "Mapa",
                subtitle: "Ver frota",
                color: const Color(0xFF7C3AED),
                onTap: () => _changePage(2),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _quickAction(
                icon: Icons.warning_rounded,
                title: "Alertas",
                subtitle: "3 pendentes",
                color: const Color(0xFFEF4444),
                onTap: () => _changePage(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

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
              width: 36,
              height: 36,

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(icon, color: color, size: 19),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              style: TextStyle(color: textLight, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ESTATÍSTICAS
  // ============================================================

  Widget _buildStatistics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      mainAxisSpacing: 12,
      crossAxisSpacing: 12,

      childAspectRatio: 1.32,
    );
  }

  // ============================================================
  // MINI MAPA
  // ============================================================

  Widget _buildMiniMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Localização da frota",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    "Acompanhe os veículos em trânsito",
                    style: TextStyle(color: textLight, fontSize: 12),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(2),

              child: const Text(
                "Abrir mapa →",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => _changePage(2),

          child: Container(
            height: 190,
            width: double.infinity,

            clipBehavior: Clip.antiAlias,

            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),

            child: Stack(
              children: [
                // Fundo simulando mapa
                CustomPaint(size: Size.infinite, painter: _MapPatternPainter()),

                // Estradas
                Positioned(
                  left: -30,
                  top: 95,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 420,
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

                Positioned(
                  left: 80,
                  top: -30,
                  child: Transform.rotate(
                    angle: 0.9,
                    child: Container(
                      width: 260,
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Marcadores
                _mapMarker(left: 65, top: 55),

                _mapMarker(left: 170, top: 105),

                _mapMarker(left: 270, top: 45),

                _mapMarker(left: 315, top: 125),

                // Card inferior
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),

                      child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          color: primary,
                          size: 18,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "184 veículos em trânsito",
                          style: TextStyle(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        Spacer(),

                        Icon(
                          Icons.arrow_forward_rounded,
                          color: textLight,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapMarker({required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,

      child: Container(
        width: 31,
        height: 31,

        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 8),
          ],
        ),

        child: const Icon(
          Icons.local_shipping_rounded,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  // ============================================================
  // ALERTAS
  // ============================================================

  Widget _buildCriticalAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,

              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E9),
                borderRadius: BorderRadius.circular(11),
              ),

              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Atenção necessária",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  Text(
                    "Existem ocorrências pendentes",
                    style: TextStyle(color: textLight, fontSize: 11),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(3),

              child: const Text(
                "Ver tudo",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        _buildAlert(
          title: "Desvio de rota detectado",
          code: "GS - 2784",
          time: "2 min",
          severity: "CRÍTICO",
          color: const Color(0xFFEF4444),
          route: "São Paulo → Rio de Janeiro",
        ),

        const SizedBox(height: 10),

        _buildAlert(
          title: "Veículo parado por muito tempo",
          code: "GS - 4512",
          time: "1 hora",
          severity: "ATENÇÃO",
          color: const Color(0xFFF59E0B),
          route: "Minas Gerais → Rio Grande do Sul",
        ),
      ],
    );
  }

  Widget _buildAlert({
    required String title,
    required String code,
    required String time,
    required String severity,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => _changePage(3),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,

                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Icon(Icons.warning_rounded, color: color, size: 19),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        code,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: Text(
                    severity,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    route,
                    style: TextStyle(color: textLight, fontSize: 10),
                  ),
                ),

                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REMESSAS
  // ============================================================

  Widget _buildRecentShipments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remessas recentes",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    "Últimas movimentações",
                    style: TextStyle(color: textLight, fontSize: 12),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(1),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Row(
                  children: [
                    Text(
                      "Ver todas",
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(width: 4),

                    Icon(Icons.arrow_forward_rounded, color: primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        _buildShipment(
          code: "GS - 9532",
          route: "SP → RJ",
          type: "Eletrônicos",
          status: "Em trânsito",
          progress: 0.78,
          eta: "Hoje, 16:40",
          statusColor: primary,
        ),

        const SizedBox(height: 10),

        _buildShipment(
          code: "GS - 6548",
          route: "MG → RS",
          type: "Alimentos",
          status: "Em trânsito",
          progress: 0.61,
          eta: "Hoje, 19:20",
          statusColor: primary,
        ),

        const SizedBox(height: 10),

        _buildShipment(
          code: "GS - 0321",
          route: "BA → RN",
          type: "Materiais de construção",
          status: "Atrasado",
          progress: 0.43,
          eta: "Atrasada",
          statusColor: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildShipment({
    required String code,
    required String route,
    required String type,
    required String status,
    required double progress,
    required String eta,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  Icons.local_shipping_rounded,
                  color: statusColor,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      type,
                      style: TextStyle(color: textLight, fontSize: 10),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),

                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: Color(0xFF94A3B8),
                size: 15,
              ),

              const SizedBox(width: 6),

              Text(
                route,
                style: TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF94A3B8),
                size: 14,
              ),

              const SizedBox(width: 4),

              Text(
                eta,
                style: TextStyle(
                  color: status == "Atrasado"
                      ? const Color(0xFFEF4444)
                      : textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,

              backgroundColor: const Color(0xFFE9EDF3),

              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Text(
                "Progresso da entrega",
                style: TextStyle(color: textLight, fontSize: 9),
              ),

              const Spacer(),

              Text(
                "${(progress * 100).round()}%",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAINEL DE MAPA SIMPLIFICADO
// ============================================================

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE4ED)
      ..strokeWidth = 1;

    const spacing = 35.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
