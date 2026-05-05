import 'package:flutter/material.dart';

class RemessasPage extends StatelessWidget {
  const RemessasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      /// APPBAR
      
      /// BODY
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// BUSCA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por ID ou carga...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// FILTROS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                FiltroChip("Todas", true),
                FiltroChip("Trânsito", false),
                FiltroChip("Entregues", false),
                FiltroChip("Atrasadas", false),
                FiltroChip("Alertas", false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// LISTA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [

                SectionTitle("Hoje"),

                RemessaCard(
                  codigo: "GS - 9532",
                  status: "Em Trânsito",
                  origem: "São Paulo, SP",
                  destino: "Rio de Janeiro, RJ",
                  tipo: "Eletrônicos",
                  peso: "2.4 ton",
                  eta: "20:09",
                ),

                RemessaCard(
                  codigo: "GS - 1705",
                  status: "Entregue",
                  origem: "Curitiba, PR",
                  destino: "Belo Horizonte, MG",
                  tipo: "Documentos",
                  peso: "0.2 ton",
                  eta: "Entregue",
                ),

                RemessaCard(
                  codigo: "GS - 6548",
                  status: "Em Trânsito",
                  origem: "Uberlândia, MG",
                  destino: "Pelotas, RS",
                  tipo: "Alimentos",
                  peso: "5.1 ton",
                  eta: "17:15",
                ),

                SectionTitle("Ontem"),

                RemessaCard(
                  codigo: "GS - 0811",
                  status: "Alerta",
                  origem: "Recife, PE",
                  destino: "Salvador, BA",
                  tipo: "Farmacêuticos",
                  peso: "1.2 ton",
                  eta: "--:--",
                ),

                RemessaCard(
                  codigo: "GS - 4512",
                  status: "Atrasado",
                  origem: "Campinas, SP",
                  destino: "Niterói, RJ",
                  tipo: "Construção",
                  peso: "8.3 ton",
                  eta: "15:40",
                ),

                RemessaCard(
                  codigo: "GS - 0206",
                  status: "Em Trânsito",
                  origem: "Brasília, DF",
                  destino: "Goiânia, GO",
                  tipo: "Perecíveis",
                  peso: "3.7 ton",
                  eta: "14:30",
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// TÍTULO DE SEÇÃO
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(title),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// CHIP FILTRO
class FiltroChip extends StatelessWidget {
  final String text;
  final bool selected;

  const FiltroChip(this.text, this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(text),
        backgroundColor: selected ? const Color.fromARGB(255, 14, 95, 161) : Colors.grey[200],
        labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black),
      ),
    );
  }
}

/// CARD REMESSA
class RemessaCard extends StatelessWidget {
  final String codigo;
  final String status;
  final String origem;
  final String destino;
  final String tipo;
  final String peso;
  final String eta;

  const RemessaCard({
    super.key,
    required this.codigo,
    required this.status,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.peso,
    required this.eta,
  });

  Color getStatusColor() {
    switch (status) {
      case "Entregue":
        return Colors.green;
      case "Atrasado":
        return Colors.orange;
      case "Alerta":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.inventory, size: 30),
        title: Row(
          children: [
            Text(codigo),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: getStatusColor(), fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$origem → $destino"),
            Text("$tipo • $peso"),
          ],
        ),
        trailing: Text("ETA $eta"),
      ),
    );
  }
}