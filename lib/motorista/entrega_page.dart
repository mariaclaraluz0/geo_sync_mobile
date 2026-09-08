import 'package:flutter/material.dart';

import 'package:mobile/motorista/avisos_motorista_page.dart';
import 'package:mobile/motorista/mapa_motorista_page.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';

class RemessasPage extends StatefulWidget {
  const RemessasPage({super.key});

  @override
  State<RemessasPage> createState() => _RemessasPageState();
}

class _RemessasPageState extends State<RemessasPage> {
  final TextEditingController _searchController = TextEditingController();

  String filtroSelecionado = "Todas";
  final int _currentIndex = 1;

  // ============================================================
  // CORES
  // ============================================================

  static const Color azul = Color(0xFF0C46FF);
  static const Color azulEscuro = Color(0xFF0B2A4A);
  static const Color texto = Color(0xFF172033);
  static const Color textoSecundario = Color(0xFF718096);
  static const Color borda = Color(0xFFE5EAF2);

  // ============================================================
  // DADOS
  // ============================================================

  final List<Remessa> remessas = [
    Remessa(
      codigo: "GS-9532",
      status: "Em rota",
      origem: "São Paulo, SP",
      destino: "Rio de Janeiro, RJ",
      tipo: "Eletrônicos",
      peso: "2.4 ton",
      eta: "20:09",
      progresso: 0.72,
    ),
    Remessa(
      codigo: "GS-6548",
      status: "Aguardando coleta",
      origem: "Uberlândia, MG",
      destino: "Pelotas, RS",
      tipo: "Alimentos",
      peso: "5.1 ton",
      eta: "17:15",
      progresso: 0.48,
    ),
    Remessa(
      codigo: "GS-1705",
      status: "Entregue",
      origem: "Curitiba, PR",
      destino: "Belo Horizonte, MG",
      tipo: "Documentos",
      peso: "0.2 ton",
      eta: "Entregue",
      progresso: 1.0,
    ),
    Remessa(
      codigo: "GS-0811",
      status: "Alerta",
      origem: "Recife, PE",
      destino: "Salvador, BA",
      tipo: "Farmacêuticos",
      peso: "1.2 ton",
      eta: "--:--",
      progresso: 0.36,
    ),
  ];

  // ============================================================
  // FILTRO
  // ============================================================

  List<Remessa> get remessasFiltradas {
    final pesquisa = _searchController.text.toLowerCase().trim();

    return remessas.where((remessa) {
      bool correspondeFiltro = true;

      switch (filtroSelecionado) {
        case "Trânsito":
          correspondeFiltro = remessa.status == "Em rota";
          break;

        case "Entregue":
          correspondeFiltro = remessa.status == "Entregue";
          break;

        case "Alerta":
          correspondeFiltro = remessa.status == "Alerta";
          break;

        default:
          correspondeFiltro = true;
      }

      final correspondeBusca =
          pesquisa.isEmpty ||
          remessa.codigo.toLowerCase().contains(pesquisa) ||
          remessa.origem.toLowerCase().contains(pesquisa) ||
          remessa.destino.toLowerCase().contains(pesquisa) ||
          remessa.tipo.toLowerCase().contains(pesquisa);

      return correspondeFiltro && correspondeBusca;
    }).toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // QUANTIDADE
  // ============================================================

  int quantidadePorStatus(String status) {
    if (status == "Todas") {
      return remessas.length;
    }

    if (status == "Trânsito") {
      return remessas.where((r) => r.status == "Em rota").length;
    }

    return remessas.where((r) => r.status == status).length;
  }

  // ============================================================
  // BUSCA
  // ============================================================

  void limparBusca() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  // ============================================================
  // DETALHES
  // ============================================================

  void abrirDetalhes(Remessa remessa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DetalhesRemessa(remessa: remessa);
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GeoSync",
                      style: TextStyle(
                        color: texto,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Gestão de entregas",
                      style: TextStyle(
                        color: textoSecundario,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              _buildNotificationButton(),

              const SizedBox(width: 9),

              _buildProfileButton(),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Minhas entregas",
                      style: TextStyle(
                        color: texto,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Acompanhe suas cargas em tempo real.",
                      style: TextStyle(color: textoSecundario, fontSize: 12),
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
                    Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Text(
                      "Online",
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildSearch(),

          const SizedBox(height: 16),

          _buildResumoRapido(),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [azulEscuro, azul],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: azul.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_shipping_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  // ============================================================
  // NOTIFICAÇÃO
  // ============================================================

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AvisosMotoristaPage()));
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borda),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF475569),
                size: 23,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
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
  // PERFIL
  // ============================================================

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () => _abrirDashboard(2),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "C",
            style: TextStyle(
              color: azul,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUSCA
  // ============================================================

  Widget _buildSearch() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borda),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: texto,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Buscar por código, origem ou destino",
          hintStyle: const TextStyle(color: textoSecundario, fontSize: 12),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: azul.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.search_rounded, color: azul, size: 20),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: limparBusca,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: textoSecundario,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO RÁPIDO
  // ============================================================

  Widget _buildResumoRapido() {
    final emRota = remessas.where((r) => r.status == "Em rota").length;

    final aguardando = remessas
        .where((r) => r.status == "Aguardando coleta")
        .length;

    final entregues = remessas.where((r) => r.status == "Entregue").length;

    return Row(
      children: [
        Expanded(
          child: _miniIndicador(
            valor: "$emRota",
            titulo: "Em rota",
            icon: Icons.navigation_rounded,
            cor: azul,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _miniIndicador(
            valor: "$aguardando",
            titulo: "Aguardando",
            icon: Icons.schedule_rounded,
            cor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _miniIndicador(
            valor: "$entregues",
            titulo: "Entregues",
            icon: Icons.check_circle_outline_rounded,
            cor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _miniIndicador({
    required String valor,
    required String titulo,
    required IconData icon,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borda),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    color: texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textoSecundario,
                    fontSize: 9,
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

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildConteudo() {
    return Column(
      children: [
        const SizedBox(height: 18),

        _buildFiltros(),

        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                "${remessasFiltradas.length} entregas",
                style: const TextStyle(
                  color: texto,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (filtroSelecionado != "Todas")
                GestureDetector(
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Todas";
                    });
                  },
                  child: const Text(
                    "Limpar filtro",
                    style: TextStyle(
                      color: azul,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: remessasFiltradas.isEmpty
              ? const _EstadoVazio()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: remessasFiltradas.length,
                  itemBuilder: (context, index) {
                    final remessa = remessasFiltradas[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _RemessaCard(
                        remessa: remessa,
                        onTap: () => abrirDetalhes(remessa),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFiltros() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filtro(
            texto: "Todas",
            filtro: "Todas",
            quantidade: quantidadePorStatus("Todas"),
          ),
          _filtro(
            texto: "Em rota",
            filtro: "Trânsito",
            quantidade: quantidadePorStatus("Trânsito"),
          ),
          _filtro(
            texto: "Entregues",
            filtro: "Entregue",
            quantidade: quantidadePorStatus("Entregue"),
          ),
          _filtro(
            texto: "Alertas",
            filtro: "Alerta",
            quantidade: quantidadePorStatus("Alerta"),
          ),
        ],
      ),
    );
  }

  Widget _filtro({
    required String texto,
    required String filtro,
    required int quantidade,
  }) {
    final selecionado = filtroSelecionado == filtro;

    return GestureDetector(
      onTap: () {
        setState(() {
          filtroSelecionado = filtro;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selecionado ? azul : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selecionado ? azul : borda),
          boxShadow: selecionado
              ? [
                  BoxShadow(
                    color: azul.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              texto,
              style: TextStyle(
                color: selecionado ? Colors.white : textoSecundario,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: selecionado
                    ? Colors.white.withValues(alpha: 0.18)
                    : const Color(0xFFF0F3F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$quantidade",
                style: TextStyle(
                  color: selecionado ? Colors.white : textoSecundario,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.grid_view_rounded,
                texto: "Início",
                index: 0,
              ),
              _navItem(
                icon: Icons.local_shipping_rounded,
                texto: "Entregas",
                index: 1,
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                texto: "Perfil",
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String texto,
    required int index,
  }) {
    final selecionado = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pop();
        } else if (index == 2) {
          _abrirDashboard(2);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selecionado
              ? azul.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selecionado ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 22,
                color: selecionado ? azul : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                color: selecionado ? azul : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  void _abrirDashboard(int initialIndex) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MotoristaDashboard(initialIndex: initialIndex),
      ),
    );
  }
}

// ============================================================================
// MODELO DA REMESSA
// ============================================================================

class Remessa {
  final String codigo;
  final String status;
  final String origem;
  final String destino;
  final String tipo;
  final String peso;
  final String eta;
  final double progresso;

  bool favorita;

  Remessa({
    required this.codigo,
    required this.status,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.peso,
    required this.eta,
    required this.progresso,
    this.favorita = false,
  });
}

// ============================================================================
// CARD DA REMESSA
// ============================================================================

class _RemessaCard extends StatefulWidget {
  final Remessa remessa;
  final VoidCallback onTap;

  const _RemessaCard({required this.remessa, required this.onTap});

  @override
  State<_RemessaCard> createState() => _RemessaCardState();
}

class _RemessaCardState extends State<_RemessaCard> {
  Color get corStatus {
    switch (widget.remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Aguardando coleta":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF0C46FF);
    }
  }

  IconData get iconeStatus {
    switch (widget.remessa.status) {
      case "Entregue":
        return Icons.check_circle_rounded;

      case "Aguardando coleta":
        return Icons.schedule_rounded;

      case "Alerta":
        return Icons.warning_amber_rounded;

      default:
        return Icons.navigation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remessa = widget.remessa;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E7F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ÍCONE
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(iconeStatus, color: corStatus, size: 24),
                ),

                const SizedBox(width: 13),

                // INFORMAÇÕES
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            remessa.codigo,
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: corStatus.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              remessa.status,
                              style: TextStyle(
                                color: corStatus,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        remessa.tipo,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFB1BBCB),
                  size: 14,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ROTA
            Row(
              children: [
                _pontoRota(
                  cor: const Color(0xFF2563EB),
                  icon: Icons.radio_button_checked_rounded,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    remessa.origem,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Color(0xFFB0BAC9),
                  ),
                ),

                Expanded(
                  child: Text(
                    remessa.destino,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _pontoRota(
                  cor: const Color(0xFFDC2626),
                  icon: Icons.location_on_rounded,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // PROGRESSO
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      "Progresso da entrega",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(remessa.progresso * 100).round()}%",
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: remessa.progresso,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFEFF2F6),
                    valueColor: AlwaysStoppedAnimation<Color>(corStatus),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // INFORMAÇÕES INFERIORES
            Row(
              children: [
                _infoItem(icon: Icons.scale_outlined, texto: remessa.peso),
                const SizedBox(width: 15),
                _infoItem(icon: Icons.access_time_rounded, texto: remessa.eta),
                const Spacer(),
                if (remessa.status == "Em rota")
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MapaMotoristaPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 15),
                    label: const Text(
                      "Mapa",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pontoRota({required Color cor, required IconData icon}) {
    return Icon(icon, size: 13, color: cor);
  }

  Widget _infoItem({required IconData icon, required String texto}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ESTADO VAZIO
// ============================================================================

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEFF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF0C46FF),
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Nenhuma entrega encontrada",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Tente alterar sua busca ou selecionar outro filtro.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETALHES DA REMESSA
// ============================================================================

class DetalhesRemessa extends StatelessWidget {
  final Remessa remessa;

  const DetalhesRemessa({super.key, required this.remessa});

  Color get corStatus {
    switch (remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Aguardando coleta":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF0C46FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INDICADOR
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // CABEÇALHO
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: corStatus,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remessa.codigo,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Detalhes da entrega",
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
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
                      color: corStatus.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      remessa.status,
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ROTA
              _buildRota(),

              const SizedBox(height: 22),

              // INFORMAÇÕES
              const Text(
                "Informações da carga",
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              _informacao(
                icon: Icons.inventory_2_outlined,
                titulo: "Tipo de carga",
                valor: remessa.tipo,
              ),

              _informacao(
                icon: Icons.scale_outlined,
                titulo: "Peso",
                valor: remessa.peso,
              ),

              _informacao(
                icon: Icons.access_time_rounded,
                titulo: "Previsão",
                valor: remessa.eta,
              ),

              const SizedBox(height: 10),

              // PROGRESSO
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Progresso",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(remessa.progresso * 100).round()}%",
                          style: TextStyle(
                            color: corStatus,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: remessa.progresso,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE6EAF0),
                        valueColor: AlwaysStoppedAnimation<Color>(corStatus),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // BOTÃO MAPA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MapaMotoristaPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: const Text(
                    "Acompanhar no mapa",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRota() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        children: [
          _rotaItem(
            icon: Icons.radio_button_checked_rounded,
            cor: const Color(0xFF2563EB),
            titulo: "Origem",
            local: remessa.origem,
          ),

          Container(
            margin: const EdgeInsets.only(left: 6),
            height: 25,
            width: 1.5,
            color: const Color(0xFFD5DCE6),
          ),

          _rotaItem(
            icon: Icons.location_on_rounded,
            cor: const Color(0xFFDC2626),
            titulo: "Destino",
            local: remessa.destino,
          ),
        ],
      ),
    );
  }

  Widget _rotaItem({
    required IconData icon,
    required Color cor,
    required String titulo,
    required String local,
  }) {
    return Row(
      children: [
        Icon(icon, color: cor, size: 15),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              local,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _informacao({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 17),
          ),

          const SizedBox(width: 10),

          Text(
            titulo,
            style: const TextStyle(color: Color(0xFF718096), fontSize: 11),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
