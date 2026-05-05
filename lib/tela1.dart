import 'package:flutter/material.dart';
import 'package:mobile/alerta_card.dart';
import 'package:mobile/card_info.dart';
import 'package:mobile/remessa_card.dart';

import 'package:mobile/tela2.dart' hide RemessaCard;
import 'package:mobile/tela3.dart' hide MapaPage;

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _currentIndex = 0;

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _home(); // SUA TELA ATUAL
      case 1:
        return RemessasPage();
      case 2:
        return const Center(child: Text("Mapa"));
      case 3:
        return const Center(child: Text("Alertas"));
      case 4:
        return const Center(child: Text("Perfil"));
      default:
        return _home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 247, 247),

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "GeoSync",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      /// 🔥 AQUI MUDA O CONTEÚDO
      body: _getBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 12, 70, 255),
        unselectedItemColor: Colors.grey,

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

  /// 🔥 SUA TELA ORIGINAL (SEM ALTERAR NADA)
  Widget _home() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bem-vindo de volta 👋"),
          const Text(
            "Painel de controle",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: const [
              CardInfo(title: "Ativas", value: "284", icon: Icons.inventory),
              CardInfo(title: "Trânsito", value: "284", icon: Icons.local_shipping),
              CardInfo(title: "Entregas", value: "56", icon: Icons.check_circle),
              CardInfo(title: "Alertas", value: "3", icon: Icons.warning),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "⚠️ Alerta Crítico",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const AlertaCard(
            titulo: "Desvio de rota detectado",
            tempo: "2 min",
            codigo: "GS - 2784",
          ),

          const AlertaCard(
            titulo: "Desvio de rota detectado",
            tempo: "1 hora",
            codigo: "GS - 4512",
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Remessas Recentes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Ver todas →",
                style: TextStyle(color: Color.fromARGB(255, 12, 70, 177)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const RemessaCard(
            codigo: "GS - 9532",
            rota: "SP → RJ",
            tipo: "Eletrônicos",
            status: "Em Trânsito",
          ),

          const RemessaCard(
            codigo: "GS - 6548",
            rota: "MG → RS",
            tipo: "Alimentos",
            status: "Em Trânsito",
          ),

          const RemessaCard(
            codigo: "GS - 0321",
            rota: "BA → RN",
            tipo: "Materiais de Construção",
            status: "Atrasado",
          ),
        ],
      ),
    );
  }
}