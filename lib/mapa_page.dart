import 'package:flutter/material.dart';

class MapaPage extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const MapaPage({super.key, this.currentIndex = 2, this.onTap});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  // Estado para controlar qual filtro está ativo
  String _filtroSelecionado = "Todos";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Cinza moderno e limpo

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          /// CARD DO MAPA (Simulador de Painel de Controle)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                /// HEADER DO MAPA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Monitoramento ao Vivo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        StatusLegenda("Normal", Color(0xFF10B981)),
                        StatusLegenda("Atraso", Color(0xFFF59E0B)),
                        StatusLegenda("Alerta", Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// ÁREA DO MAPA (Estilizado)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Fundo escuro estilo "Dark Map UI"
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600&auto=format&fit=crop'), // Textura abstrata simulando relevo/rotas
                      fit: BoxFit.cover,
                      opacity: 0.15,
                    ),
                  ),
                  child: Stack(
                    children: const [
                      // Grid de linhas decorativas simulando coordenadas GPS
                      Positioned.fill(child: GridPaper(color: Colors.white10, intervals: [40, 80], subdivisions: 1)),
                      
                      PontoMapa(left: 50, top: 50, color: Color(0xFF10B981)),
                      PontoMapa(left: 120, top: 110, color: Color(0xFF10B981)),
                      PontoMapa(left: 210, top: 70, color: Color(0xFFF59E0B)),
                      PontoMapa(left: 280, top: 40, color: Color(0xFFEF4444)),
                      PontoMapa(left: 90, top: 150, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// SEÇÃO DE FILTROS (Chips Interativos)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip("Todos"),
                const SizedBox(width: 8),
                _buildFilterChip("Em Trânsito"),
                const SizedBox(width: 8),
                _buildFilterChip("Alertas"),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// LISTA DE ROTAS FILTRADA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: _getFilteredRoutes(),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para construir os botões de filtro
  Widget _buildFilterChip(String label) {
    final isSelected = _filtroSelecionado == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroSelecionado = label;
          });
        }
      },
      selectedColor: const Color(0xFF0C46FF),
      textColor: isSelected ? Colors.white : const Color(0xFF64748B),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// Lógica de filtragem mockada
  List<Widget> _getFilteredRoutes() {
    final todas = [
      const ItemRota("GS - 9532", "SP", "RJ", Color(0xFF10B981), "Normal"),
      const ItemRota("GS - 6548", "MG", "RS", Color(0xFF10B981), "Normal"),
      const ItemRota("GS - 4512", "SP", "RJ", Color(0xFFF59E0B), "Atraso"),
      const ItemRota("GS - 0811", "PE", "BA", Color(0xFFEF4444), "Alerta"),
      const ItemRota("GS - 0206", "DF", "GO", Color(0xFF10B981), "Normal"),
      const ItemRota("GS - 1705", "PR", "MG", Color(0xFF10B981), "Normal"),
    ];

    if (_filtroSelecionado == "Alertas") {
      return todas.where((item) => item.status == "Alerta" || item.status == "Atraso").toList();
    } else if (_filtroSelecionado == "Em Trânsito") {
      return todas.where((item) => item.status == "Normal").toList();
    }
    return todas;
  }
}

class ItemRota extends StatelessWidget {
  final String codigo;
  final String origem;
  final String destino;
  final Color cor;
  final String status;

  const ItemRota(this.codigo, this.origem, this.destino, this.cor, this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text("Monitorando veículo $codigo"),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador visual de status lateral esquerdo
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Informações do Veículo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(origem, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                        ),
                        Text(destino, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              ),

              // Ícone com badge indicando o tipo de transporte
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_outlined, color: cor, size: 20),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StatusLegenda extends StatelessWidget {
  final String text;
  final Color color;

  const StatusLegenda(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 10),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class PontoMapa extends StatelessWidget {
  final double left;
  final double top;
  final Color color;

  const PontoMapa({
    super.key,
    required this.left,
    required this.top,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anel externo/Efeito de pulso estático para destacar no mapa
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
          // Ponto Central Real
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}