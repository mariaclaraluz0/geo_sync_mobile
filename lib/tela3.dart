import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapaPage(),
    );
  }
}

class MapaPage extends StatelessWidget {
  const MapaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      /// APPBAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("GeoSync", style: TextStyle(fontSize: 16)),
            Text("Rastreamento ao vivo", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          )
        ],
      ),

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
                BoxShadow(color: Colors.black12, blurRadius: 5)
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
                    )
                  ],
                ),

                const SizedBox(height: 10),

                /// "MAPA FAKE"
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
                )
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
          )
        ],
      ),

      /// NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Remessas"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Alertas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}

/// LEGENDA
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
      ],
    );
  }
}

/// PONTO NO MAPA
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// ITEM LISTA
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
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        title: Text(codigo),
        trailing: Text(rota),
      ),
    );
  }
}