import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;

  final List<Widget> _pages = const [
    Center(child: Text("Início")),
    Center(child: Text("Remessas")),
    DashboardPage(),
    Center(child: Text("Alertas")),
    Center(child: Text("Perfil")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("GeoSync", style: TextStyle(fontSize: 16)),
            Text("Rastreamento ao vivo",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 10),
        ],
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B2A4A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

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

// ===== TELA PRINCIPAL (MAPA) =====
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // CARD DO GRÁFICO
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Visão ao vivo"),
                const SizedBox(height: 10),

                Expanded(
                  child: Stack(
                    children: const [
                      Positioned(left: 20, top: 40, child: Dot(color: Colors.blue)),
                      Positioned(left: 100, top: 80, child: Dot(color: Colors.green)),
                      Positioned(left: 180, top: 120, child: Dot(color: Colors.blue)),
                      Positioned(left: 240, top: 50, child: Dot(color: Colors.red)),
                      Positioned(left: 60, top: 120, child: Dot(color: Colors.orange)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // LISTA
          Expanded(
            child: ListView(
              children: const [
                ShipmentCard("GS - 9532", "SP → RJ", Colors.blue),
                ShipmentCard("GS - 6548", "MG → RS", Colors.blue),
                ShipmentCard("GS - 4512", "SP → RJ", Colors.orange),
                ShipmentCard("GS - 0811", "PE → BA", Colors.red),
                ShipmentCard("GS - 0206", "DF → GO", Colors.blue),
                ShipmentCard("GS - 1705", "PR → MG", Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CARD DE REMESSA
class ShipmentCard extends StatelessWidget {
  final String code;
  final String route;
  final Color color;

  const ShipmentCard(this.code, this.route, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Você clicou em $code")),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 5, backgroundColor: color),
            const SizedBox(width: 10),
            Text(code),
            const Spacer(),
            Text(route),
          ],
        ),
      ),
    );
  }
}

// PONTO DO GRÁFICO
class Dot extends StatelessWidget {
  final Color color;

  const Dot({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}