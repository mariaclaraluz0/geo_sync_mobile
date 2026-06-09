import 'package:flutter/material.dart';
import 'package:mobile/alerta_card.dart';
import 'package:mobile/card_info.dart';
import 'package:mobile/remessa_card.dart';
import 'package:mobile/perfil_page.dart';

import 'package:mobile/remessa_page.dart' hide RemessaCard;
import 'package:mobile/mapa_page.dart';

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
        return _home();
      case 1:
        return RemessasPage();
      case 2:
        return MapaPage();
      case 3:
        return const Center(child: Text("Alertas")); 
      case 4:
        return PerfilClientePage(); 
      default:
        return _home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Um fundo cinza neutro e moderno (estilo iOS/Material 3 limpo)
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Remove a sombra pesada antiga
        scrolledUnderElevation: 1,
        actions: [
          // Atalho rápido de notificações para a aba de alertas
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              setState(() {
                _currentIndex = 3;
              });
            },
          ),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _getBody(),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF0C46FF),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Início"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: "Remessas"),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Mapa"),
            BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: "Alertas"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Perfil"),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação mais elegante
          const Text(
            "Bem-vindo de volta 👋",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.normal),
          ),
          const Text(
            "Painel de Controle",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: -0.5),
          ),

          const SizedBox(height: 20),

          // Grid de informações ajustado para não quebrar proporção
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4, // Garante que o card tenha um formato retangular harmônico
            children: const [
              CardInfo(title: "Ativas", value: "284", icon: Icons.inventory_2_outlined),
              CardInfo(title: "Trânsito", value: "284", icon: Icons.local_shipping_outlined),
              CardInfo(title: "Entregas", value: "56", icon: Icons.check_circle_outline_rounded),
              CardInfo(title: "Alertas", value: "3", icon: Icons.warning_amber_rounded),
            ],
          ),

          const SizedBox(height: 28),

          // Seção de Alertas Críticos
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 6),
              const Text(
                "Alertas Críticos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "2 novos",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          const AlertaCard(
            titulo: "Desvio de rota detectado",
            tempo: "2 min",
            codigo: "GS - 2784",
          ),
          const SizedBox(height: 8), // Pequeno espaçamento entre os cards
          const AlertaCard(
            titulo: "Desvio de rota detectado",
            tempo: "1 hora",
            codigo: "GS - 4512",
          ),

          const SizedBox(height: 28),

          // Seção de Remessas Recentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Remessas Recentes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              // AGORA FUNCIONAL: Clicar aqui muda a aba do app de verdade!
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 1; // Vai para a aba Remessas
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "Ver todas →",
                    style: TextStyle(
                      color: Color(0xFF0C46FF), 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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