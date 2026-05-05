import 'package:flutter/material.dart';

class MapaPage extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const MapaPage({super.key, this.currentIndex = 2, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      /// BODY
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// CARD MAPA
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("📡 Visão ao vivo"),
                    Row(
                      children: const [
                        StatusLegenda("OK", Colors.green),
                        StatusLegenda("Atraso", Colors.orange),
                        StatusLegenda("Alerta", Colors.red),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// MAPA
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: const [
                      PontoMapa(left: 50, top: 40, color: Colors.blue),
                      PontoMapa(left: 120, top: 80, color: Colors.green),
                      PontoMapa(left: 200, top: 60, color: Colors.blue),
                      PontoMapa(left: 260, top: 40, color: Colors.red),
                      PontoMapa(left: 80, top: 120, color: Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// LISTA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                ItemRota("GS - 9532", "SP → RJ", Colors.blue),
                ItemRota("GS - 6548", "MG → RS", Colors.blue),
                ItemRota("GS - 4512", "SP → RJ", Colors.orange),
                ItemRota("GS - 0811", "PE → BA", Colors.red),
                ItemRota("GS - 0206", "DF → GO", Colors.blue),
                ItemRota("GS - 1705", "PR → MG", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ItemRota extends StatelessWidget {
  final String codigo;
  final String rota;
  final Color cor;

  const ItemRota(this.codigo, this.rota, this.cor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        title: Text(
          codigo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(rota, style: const TextStyle(color: Colors.grey)),

        /// 🔥 clique (opcional)
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Você clicou em $codigo")));
        },
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
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(text, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
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
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
