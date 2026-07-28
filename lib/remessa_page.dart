import 'package:flutter/material.dart';

class RemessasPage extends StatefulWidget {
  const RemessasPage({super.key});

  @override
  State<RemessasPage> createState() => _RemessasPageState();
}

class _RemessasPageState extends State<RemessasPage> {
  final TextEditingController _searchController = TextEditingController();

  String filtroSelecionado = "Todas";

  final List<Remessa> remessas = [
    Remessa(
      codigo: "GS - 9532",
      status: "Em Trânsito",
      origem: "São Paulo, SP",
      destino: "Rio de Janeiro, RJ",
      tipo: "Eletrônicos",
      peso: "2.4 ton",
      eta: "20:09",
      progresso: 0.72,
    ),
    Remessa(
      codigo: "GS - 1705",
      status: "Entregue",
      origem: "Curitiba, PR",
      destino: "Belo Horizonte, MG",
      tipo: "Documentos",
      peso: "0.2 ton",
      eta: "Entregue",
      progresso: 1.0,
    ),
    Remessa(
      codigo: "GS - 6548",
      status: "Em Trânsito",
      origem: "Uberlândia, MG",
      destino: "Pelotas, RS",
      tipo: "Alimentos",
      peso: "5.1 ton",
      eta: "17:15",
      progresso: 0.48,
    ),
    Remessa(
      codigo: "GS - 0811",
      status: "Alerta",
      origem: "Recife, PE",
      destino: "Salvador, BA",
      tipo: "Farmacêuticos",
      peso: "1.2 ton",
      eta: "--:--",
      progresso: 0.36,
    ),
    Remessa(
      codigo: "GS - 4512",
      status: "Atrasado",
      origem: "Campinas, SP",
      destino: "Niterói, RJ",
      tipo: "Construção",
      peso: "8.3 ton",
      eta: "15:40",
      progresso: 0.61,
    ),
    Remessa(
      codigo: "GS - 0206",
      status: "Em Trânsito",
      origem: "Brasília, DF",
      destino: "Goiânia, GO",
      tipo: "Perecíveis",
      peso: "3.7 ton",
      eta: "14:30",
      progresso: 0.82,
    ),
  ];

  List<Remessa> get remessasFiltradas {
    final pesquisa = _searchController.text.toLowerCase().trim();

    return remessas.where((remessa) {
      final correspondeFiltro = filtroSelecionado == "Todas" ||
          (filtroSelecionado == "Trânsito" &&
              remessa.status == "Em Trânsito") ||
          remessa.status == filtroSelecionado;

      final correspondeBusca = pesquisa.isEmpty ||
          remessa.codigo.toLowerCase().contains(pesquisa) ||
          remessa.origem.toLowerCase().contains(pesquisa) ||
          remessa.destino.toLowerCase().contains(pesquisa) ||
          remessa.tipo.toLowerCase().contains(pesquisa);

      return correspondeFiltro && correspondeBusca;
    }).toList();
  }

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

  int quantidadePorStatus(String status) {
    if (status == "Todas") {
      return remessas.length;
    }

    if (status == "Trânsito") {
      return remessas.where((r) => r.status == "Em Trânsito").length;
    }

    return remessas.where((r) => r.status == status).length;
  }

  void limparBusca() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GeoSync",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              "Minhas Remessas",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Lista atualizada!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: Column(
        children: [
          // ============================================================
          // ÁREA SUPERIOR
          // ============================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0B2A4A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // BUSCA
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar ID, cidade ou carga...",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0B2A4A),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: limparBusca,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // RESUMO
                Row(
                  children: [
                    Expanded(
                      child: ResumoItem(
                        icone: Icons.inventory_2_outlined,
                        titulo: "Total",
                        valor: "${remessas.length}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: Icons.local_shipping_outlined,
                        titulo: "Em rota",
                        valor: "${quantidadePorStatus("Trânsito")}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: Icons.check_circle_outline,
                        titulo: "Entregues",
                        valor: "${quantidadePorStatus("Entregue")}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: Icons.warning_amber_rounded,
                        titulo: "Alertas",
                        valor:
                            "${quantidadePorStatus("Alerta") + quantidadePorStatus("Atrasado")}",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ============================================================
          // FILTROS
          // ============================================================

          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FiltroChip(
                  texto: "Todas",
                  selecionado: filtroSelecionado == "Todas",
                  quantidade: quantidadePorStatus("Todas"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Todas";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Trânsito",
                  selecionado: filtroSelecionado == "Trânsito",
                  quantidade: quantidadePorStatus("Trânsito"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Trânsito";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Entregues",
                  selecionado: filtroSelecionado == "Entregue",
                  quantidade: quantidadePorStatus("Entregue"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Entregue";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Atrasadas",
                  selecionado: filtroSelecionado == "Atrasado",
                  quantidade: quantidadePorStatus("Atrasado"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Atrasado";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Alertas",
                  selecionado: filtroSelecionado == "Alerta",
                  quantidade: quantidadePorStatus("Alerta"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Alerta";
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // RESULTADO
          // ============================================================

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  "${remessasFiltradas.length} remessa(s)",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                if (filtroSelecionado != "Todas")
                  TextButton(
                    onPressed: () {
                      setState(() {
                        filtroSelecionado = "Todas";
                      });
                    },
                    child: const Text("Limpar filtro"),
                  ),
              ],
            ),
          ),

          // ============================================================
          // LISTA
          // ============================================================

          Expanded(
            child: remessasFiltradas.isEmpty
                ? const EstadoVazio()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
                    itemCount: remessasFiltradas.length,
                    itemBuilder: (context, index) {
                      final remessa = remessasFiltradas[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RemessaCard(
                          remessa: remessa,
                          onTap: () => abrirDetalhes(remessa),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODELO
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
// RESUMO
// ============================================================================

class ResumoItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const ResumoItem({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icone,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FILTRO
// ============================================================================

class FiltroChip extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final int quantidade;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.quantidade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFF0B2A4A)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF0B2A4A)
                : Colors.grey.shade300,
          ),
          boxShadow: [
            if (selecionado)
              BoxShadow(
                color: const Color(0xFF0B2A4A).withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Text(
              texto,
              style: TextStyle(
                color: selecionado
                    ? Colors.white
                    : const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$quantidade",
                style: TextStyle(
                  color: selecionado
                      ? Colors.white
                      : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
// CARD DA REMESSA
// ============================================================================

class RemessaCard extends StatefulWidget {
  final Remessa remessa;
  final VoidCallback onTap;

  const RemessaCard({
    super.key,
    required this.remessa,
    required this.onTap,
  });

  @override
  State<RemessaCard> createState() => _RemessaCardState();
}

class _RemessaCardState extends State<RemessaCard> {
  Color get statusColor {
    switch (widget.remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Atrasado":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData get statusIcon {
    switch (widget.remessa.status) {
      case "Entregue":
        return Icons.check_circle_rounded;

      case "Atrasado":
        return Icons.schedule_rounded;

      case "Alerta":
        return Icons.warning_rounded;

      default:
        return Icons.local_shipping_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOPO
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: statusColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.remessa.codigo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.remessa.tipo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        widget.remessa.favorita =
                            !widget.remessa.favorita;
                      });
                    },
                    icon: Icon(
                      widget.remessa.favorita
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: widget.remessa.favorita
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.remessa.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ROTA
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 17,
                        color: Color(0xFF2563EB),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        color: Colors.grey.shade300,
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Origem",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          widget.remessa.origem,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Destino",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          widget.remessa.destino,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ETA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "ETA",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.remessa.eta,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // PROGRESSO
              Row(
                children: [
                  Text(
                    "Progresso da entrega",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${(widget.remessa.progresso * 100).toInt()}%",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.remessa.progresso,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    statusColor,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // RODAPÉ
              Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.remessa.peso,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Ver detalhes",
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ESTADO VAZIO
// ============================================================================

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2A4A).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: Color(0xFF0B2A4A),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Nenhuma remessa encontrada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tente alterar os filtros ou pesquisar por outro código.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DETALHES
// ============================================================================

class DetalhesRemessa extends StatelessWidget {
  final Remessa remessa;

  const DetalhesRemessa({
    super.key,
    required this.remessa,
  });

  Color get statusColor {
    switch (remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Atrasado":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: statusColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remessa.codigo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          remessa.tipo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Status da remessa",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      remessa.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Informações da carga",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              InfoDetalhe(
                icone: Icons.category_outlined,
                titulo: "Tipo de carga",
                valor: remessa.tipo,
              ),

              InfoDetalhe(
                icone: Icons.scale_outlined,
                titulo: "Peso",
                valor: remessa.peso,
              ),

              InfoDetalhe(
                icone: Icons.schedule_outlined,
                titulo: "Previsão",
                valor: remessa.eta,
              ),

              const SizedBox(height: 20),

              const Text(
                "Rota",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 15),

              RotaDetalhe(
                icone: Icons.radio_button_checked,
                titulo: "Origem",
                valor: remessa.origem,
                cor: Colors.blue,
              ),

              RotaDetalhe(
                icone: Icons.location_on_rounded,
                titulo: "Destino",
                valor: remessa.destino,
                cor: Colors.red,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Abrindo localização da remessa...",
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    "Ver no mapa",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
}

// ============================================================================
// INFORMAÇÃO
// ============================================================================

class InfoDetalhe extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const InfoDetalhe({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icone,
              size: 19,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ROTA
// ============================================================================

class RotaDetalhe extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color cor;

  const RotaDetalhe({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icone,
            color: cor,
            size: 19,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}