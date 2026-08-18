import 'package:flutter/material.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/motorista/entrega_page.dart';

class MotoristaDashboard extends StatefulWidget {
  const MotoristaDashboard({super.key});

  @override
  State<MotoristaDashboard> createState() =>
      _MotoristaDashboardState();
}

class _MotoristaDashboardState extends State<MotoristaDashboard> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);
  static const Color border = Color(0xFFE8ECF3);

  // Página atualmente selecionada
  int _currentIndex = 0;

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
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _getBody(),
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
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
        return _meusGanhos();

      case 3:
        return _perfil();

      default:
        return _inicio();
    }
  }

  void _changePage(int index) {
    // ----------------------------------------------------------
    // ABRIR A TELA DE ENTREGAS
    // ----------------------------------------------------------

    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RemessasPage(),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // ALTERAR AS OUTRAS PÁGINAS
    // ----------------------------------------------------------

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
      titleSpacing: 18,

      title: Row(
        children: [
          // LOGO
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primaryDark,
                  primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // TÍTULO
          const Column(
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
                "Área do motorista",
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

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  Widget _notificationButton() {
    return GestureDetector(
      onTap: () {
        _mostrarMensagem(
          "Você não possui novos avisos.",
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
          ),
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
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
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
        _changePage(3);
      },
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.grid_view_rounded,
                label: "Início",
                index: 0,
              ),

              // ------------------------------------------------
              // ENTREGAS
              // Ao clicar, abre entrega_page.dart
              // ------------------------------------------------
              _navItem(
                icon: Icons.local_shipping_outlined,
                label: "Entregas",
                index: 1,
              ),

              _navItem(
                icon: Icons.account_balance_wallet_outlined,
                label: "Ganhos",
                index: 2,
              ),

              _navItem(
                icon: Icons.person_outline_rounded,
                label: "Perfil",
                index: 3,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primary.withOpacity(0.09)
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
                color: selected
                    ? primary
                    : const Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? primary
                    : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
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
        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (mounted) {
          setState(() {});
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(),

            const SizedBox(height: 18),

            _cardRota(),

            const SizedBox(height: 22),

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
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Olá, Carlos 👋",
                style: TextStyle(
                  color: textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Sua rota de hoje",
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
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAFBF1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.circle,
                size: 7,
                color: Color(0xFF16A34A),
              ),

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
  // CARD DA ROTA
  // ============================================================

  Widget _cardRota() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryDark,
            Color(0xFF123C69),
            primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.22),
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
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    color: Colors.white70,
                    size: 19,
                  ),

                  SizedBox(width: 8),

                  Text(
                    "VIAGEM EM ANDAMENTO",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                "GS-9532",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "São Paulo, SP → Rio de Janeiro, RJ",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          color: Colors.white,
                          size: 15,
                        ),

                        SizedBox(width: 5),

                        Text(
                          "186 km",
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
                    "3 entregas hoje",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mostrarMensagem(
                      "Navegação para a próxima parada iniciada.",
                    );
                  },
                  icon: const Icon(
                    Icons.directions,
                  ),
                  label: const Text(
                    "Abrir navegação",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
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

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildResumo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Resumo do dia",
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
                icon: Icons.inventory_2_rounded,
                valor: "3",
                legenda: "entregas",
                cor: primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _resumo(
                icon: Icons.route_rounded,
                valor: "186 km",
                legenda: "percorridos",
                cor: const Color(0xFF7C3AED),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: cor,
              size: 20,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            valor,
            style: const TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            legenda,
            style: const TextStyle(
              color: textLight,
              fontSize: 10,
            ),
          ),
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
        const Text(
          "Próximas paradas",
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        _parada(
          numero: "1",
          titulo: "Centro de Distribuição",
          detalhe: "Retirada confirmada • 09:30",
          icon: Icons.inventory_2_rounded,
        ),

        _parada(
          numero: "2",
          titulo: "Av. Paulista, 1578",
          detalhe: "Entrega prevista • 11:40",
          icon: Icons.location_on_rounded,
        ),

        _parada(
          numero: "3",
          titulo: "Rua das Flores, 82",
          detalhe: "Entrega prevista • 14:20",
          icon: Icons.location_on_rounded,
        ),
      ],
    );
  }

  Widget _parada({
    required String numero,
    required String titulo,
    required String detalhe,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  detalhe,
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            icon,
            color: primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEUS GANHOS
  // ============================================================

  Widget _meusGanhos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meus ganhos",
            style: TextStyle(
              color: textDark,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primaryDark,
                  primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DISPONÍVEL ESTA SEMANA",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "R\$ 1.480,00",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "6 entregas concluídas",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Últimos repasses",
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          _repasse(
            "Entrega GS-1705",
            "R\$240,00",
          ),

          _repasse(
            "Entrega GS-8122",
            "R\$310,00",
          ),
        ],
      ),
    );
  }

  Widget _repasse(
    String entrega,
    String valor,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBF1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              entrega,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
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
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        30,
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 45,
              color: primary,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Carlos Silva",
            style: TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            "Motorista • CNH válida",
            style: TextStyle(
              color: textLight,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 25),

          _perfilItem(
            icon: Icons.badge_outlined,
            titulo: "Documentos",
            subtitulo: "CNH e dados do veículo",
          ),

          _perfilItem(
            icon: Icons.directions_car_outlined,
            titulo: "Meu veículo",
            subtitulo: "Volvo VM 270 • ABC-1D23",
          ),

          _perfilItem(
            icon: Icons.settings_outlined,
            titulo: "Configurações",
            subtitulo: "Preferências da conta",
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: _sair,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFDADA),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 21,
                  ),

                  SizedBox(width: 12),

                  Text(
                    "Sair da conta",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfilItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF94A3B8),
            size: 15,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // SAIR
  // ============================================================

  void _sair() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }
}
