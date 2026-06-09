import 'package:flutter/material.dart';

class PerfilClientePage extends StatelessWidget {
  const PerfilClientePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GeoSync",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Perfil do Cliente",
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notificações")),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // FOTO E NOME
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 55,
                        backgroundColor: Color(0xFF0B2A4A),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Alterar foto"),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Maria Clara",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Cliente Premium",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // DADOS
            _infoCard(
              icon: Icons.email,
              title: "Email",
              value: "mariaclara@email.com",
            ),

            _infoCard(
              icon: Icons.phone,
              title: "Telefone",
              value: "(19) 99999-9999",
            ),

            _infoCard(
              icon: Icons.location_on,
              title: "Endereço",
              value: "Campinas - SP",
            ),

            const SizedBox(height: 15),

            // OPÇÕES
            _menuItem(
              context,
              Icons.edit,
              "Editar Perfil",
              () {},
            ),

            _menuItem(
              context,
              Icons.lock,
              "Alterar Senha",
              () {},
            ),

            _menuItem(
              context,
              Icons.local_shipping,
              "Minhas Remessas",
              () {},
            ),

            _menuItem(
              context,
              Icons.support_agent,
              "Suporte",
              () {},
            ),

            _menuItem(
              context,
              Icons.settings,
              "Configurações",
              () {},
            ),

            _menuItem(
              context,
              Icons.logout,
              "Sair",
              () {},
              color: Colors.red,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

    );
  }

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF0B2A4A)),
          title: Text(title),
          subtitle: Text(value),
        ),
      ),
    );
  }

  static Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}