import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelaAlertas(),
  ));
}

class TelaAlertas extends StatelessWidget {
  const TelaAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Alertas",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123D7A),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Acompanhe em tempo real os alertas da sua frota e mercadorias.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    filtro("Todos", "5", Colors.blue),
                    filtro("Críticos", "2", Colors.red),
                    filtro("Atenção", "2", Colors.orange),
                    filtro("Informativos", "1", Colors.blueGrey),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [

                    alertaCard(
                      cor: Colors.red,
                      icone: Icons.warning_rounded,
                      titulo: "Desvio de Rota Detectado",
                      descricao:
                          "Veículo QWE-8A12 saiu da rota programada às 08:35.",
                      local:
                          "Rod. BR-153, km 355 - São Carlos/SP",
                      horario: "08:35",
                      status: "Crítico",
                    ),

                    alertaCard(
                      cor: Colors.orange,
                      icone: Icons.speed,
                      titulo: "Excesso de Velocidade",
                      descricao:
                          "Veículo ABC-1234 acima do limite permitido (90 km/h).",
                      local:
                          "Rod. Anhanguera, km 210 - Campinas/SP",
                      horario: "08:20",
                      status: "Atenção",
                    ),

                    alertaCard(
                      cor: Colors.red,
                      icone: Icons.stop_circle,
                      titulo: "Parada Não Autorizada",
                      descricao:
                          "Veículo XYZ-5678 parado fora dos pontos autorizados.",
                      local:
                          "Av. Brasil, 4200 - Ribeirão Preto/SP",
                      horario: "07:50",
                      status: "Crítico",
                    ),

                    alertaCard(
                      cor: Colors.orange,
                      icone: Icons.inventory_2_outlined,
                      titulo: "Abertura de Baú",
                      descricao:
                          "A porta do baú foi aberta fora do horário programado.",
                      local:
                          "Rod. Washington Luís, km 180 - Araraquara/SP",
                      horario: "07:15",
                      status: "Atenção",
                    ),

                    alertaCard(
                      cor: Colors.blue,
                      icone: Icons.info_outline,
                      titulo: "Manutenção Preventiva",
                      descricao:
                          "Lembrete: manutenção do veículo LMN-3456 agendada para hoje.",
                      local: "Centro de Manutenção",
                      horario: "06:30",
                      status: "Informativo",
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget alertaCard({
    required Color cor,
    required IconData icone,
    required String titulo,
    required String descricao,
    required String local,
    required String horario,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icone,
              color: cor,
              size: 34,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  descricao,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: cor, size: 18),
                    Expanded(
                      child: Text(
                        local,
                        style: TextStyle(
                          color: cor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            children: [
              Text(
                horario,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget filtro(String texto, String qtd, Color cor) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 11,
            backgroundColor: cor,
            child: Text(
              qtd,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }
}