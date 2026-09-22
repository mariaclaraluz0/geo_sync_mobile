import 'package:flutter/material.dart';
import 'package:mobile/perfil_page.dart';
import 'package:mobile/tela_dashboard.dart';

// ============================================================
// TELA DE REMESSAS
// ============================================================

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
      bool correspondeFiltro = filtroSelecionado == "Todas";

      if (filtroSelecionado == "Trânsito") {
        correspondeFiltro = remessa.status == "Em rota";
      }

      if (filtroSelecionado == "Entregue") {
        correspondeFiltro = remessa.status == "Entregue";
      }

      if (filtroSelecionado == "Alerta") {
        correspondeFiltro = remessa.status == "Alerta";
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
      builder: (context) {
        return DetalhesRemessa(remessa: remessa);
      },
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void navegarPara(int index) {
    if (index == _currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaDashboard()),
        );
        break;

      case 1:
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PerfilClientePage()),
        );
        break;
    }
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
            _buildTopo(),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // TOPO
  // ============================================================

  Widget _buildTopo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // LOGO
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [azulEscuro, azul]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: azul.withValues(alpha: 0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              // NOME
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
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Área do motorista",
                      style: TextStyle(color: textoSecundario, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // NOTIFICAÇÕES
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Você não possui novas notificações."),
                    ),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE3E8F0)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // PERFIL
              GestureDetector(
                onTap: () {
                  navegarPara(3);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "C",
                      style: TextStyle(
                        color: azul,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            "Minhas entregas",
            style: TextStyle(
              color: texto,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Somente cargas atribuídas a você.",
            style: TextStyle(color: textoSecundario, fontSize: 13),
          ),

          const SizedBox(height: 18),

          // BUSCA
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: texto, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Buscar entrega...",
                hintStyle: const TextStyle(
                  color: textoSecundario,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: azul),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: limparBusca,
                        icon: const Icon(Icons.close, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
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
        const SizedBox(height: 16),

        // FILTROS
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _filtro(
                texto: "Todas",
                selecionado: filtroSelecionado == "Todas",
                quantidade: quantidadePorStatus("Todas"),
              ),
              _filtro(
                texto: "Em rota",
                selecionado: filtroSelecionado == "Trânsito",
                quantidade: quantidadePorStatus("Trânsito"),
                filtro: "Trânsito",
              ),
              _filtro(
                texto: "Entregues",
                selecionado: filtroSelecionado == "Entregue",
                quantidade: quantidadePorStatus("Entregue"),
                filtro: "Entregue",
              ),
              _filtro(
                texto: "Alertas",
                selecionado: filtroSelecionado == "Alerta",
                quantidade: quantidadePorStatus("Alerta"),
                filtro: "Alerta",
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CONTADOR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                "${remessasFiltradas.length} entrega(s)",
                style: const TextStyle(
                  color: texto,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

        // LISTA
        Expanded(
          child: remessasFiltradas.isEmpty
              ? const _EstadoVazio()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: remessasFiltradas.length,
                  itemBuilder: (context, index) {
                    final remessa = remessasFiltradas[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
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
  // FILTRO
  // ============================================================

  Widget _filtro({
    required String texto,
    required bool selecionado,
    required int quantidade,
    String? filtro,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          filtroSelecionado = filtro ?? texto;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? azul : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? azul : const Color(0xFFE1E6EF),
          ),
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: selecionado
                    ? Colors.white.withValues(alpha: 0.20)
                    : const Color(0xFFF0F3F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$quantidade",
                style: TextStyle(
                  color: selecionado ? Colors.white : textoSecundario,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
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
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.dashboard_outlined, texto: "Início", index: 0),
            _navItem(
              icon: Icons.local_shipping_outlined,
              texto: "Entregas",
              index: 1,
            ),
            _navItem(
              icon: Icons.account_circle_outlined,
              texto: "Perfil",
              index: 2,
            ),
          ],
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
        navegarPara(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        height: 66,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFFE9EEFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selecionado ? azul : const Color(0xFF8FA0B8),
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                color: selecionado ? azul : const Color(0xFF8FA0B8),
                fontSize: 10,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
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

  IconData get icone {
    switch (widget.remessa.status) {
      case "Entregue":
        return Icons.check_circle_outline;

      case "Aguardando coleta":
        return Icons.schedule_outlined;

      case "Alerta":
        return Icons.warning_amber_outlined;

      default:
        return Icons.local_shipping_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE0E6EF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: corStatus.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icone, color: corStatus, size: 24),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.remessa.codigo,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${widget.remessa.origem} → ${widget.remessa.destino}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, color: corStatus, size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        widget.remessa.status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: corStatus,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE9EEFF),
            child: Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF0C46FF),
              size: 38,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Nenhuma entrega encontrada",
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Tente alterar sua busca ou filtro.",
            style: TextStyle(color: Color(0xFF718096), fontSize: 12),
          ),
        ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DCE6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: corStatus,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remessa.codigo,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Detalhes da entrega",
                      style: TextStyle(color: Color(0xFF718096), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            _informacao("Status", remessa.status, corStatus),

            _informacao("Origem", remessa.origem, const Color(0xFF2563EB)),

            _informacao("Destino", remessa.destino, const Color(0xFFDC2626)),

            _informacao("Tipo de carga", remessa.tipo, const Color(0xFF64748B)),

            _informacao("Peso", remessa.peso, const Color(0xFF64748B)),

            _informacao("Previsão", remessa.eta, corStatus),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text("Ver no mapa"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2A4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informacao(String titulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
