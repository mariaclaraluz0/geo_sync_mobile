import 'package:flutter/material.dart';
import 'package:mobile/editarPerfil_page.dart';
import 'package:mobile/login_screen.dart';
import 'alterarSenha_page.dart';
import 'configuracoes_page.dart';
import 'suporte_page.dart';

class PerfilClientePage extends StatefulWidget {
  const PerfilClientePage({super.key});

  @override
  State<PerfilClientePage> createState() => _PerfilClientePageState();
}

class _PerfilClientePageState extends State<PerfilClientePage> {
  // Variáveis de Estado (Podem ser atualizadas dinamicamente)
  String _nome = "Maria Clara";
  String _tipoCliente = "Cliente Premium";
  String _email = "mariaclara@email.com";
  String _telefone = "(19) 99999-9999";
  String _endereco = "Campinas - SP";

  // Função auxiliar para exibir diálogos/mensagens
  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
    );
  }

  // Modal de confirmação para Logout
  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sair da Conta'),
          content: const Text('Tem certeza de que deseja encerrar a sessão?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarSnackBar("Sessão encerrada com sucesso.");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GeoSync",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Perfil do Cliente",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => _mostrarSnackBar("Sem novas notificações"),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),

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
                        child: Material(
                          color: Colors.blue,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                _mostrarSnackBar("Alterar foto de perfil"),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nome,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tipoCliente,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // DADOS DO USUÁRIO
            _infoCard(
              icon: Icons.email_outlined,
              title: "Email",
              value: _email,
            ),
            _infoCard(
              icon: Icons.phone_outlined,
              title: "Telefone",
              value: _telefone,
            ),
            _infoCard(
              icon: Icons.location_on_outlined,
              title: "Endereço",
              value: _endereco,
            ),

            const SizedBox(height: 15),

            // OPÇÕES DO MENU
            _menuItem(
              icon: Icons.edit_outlined,
              title: "Editar Perfil",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditarPerfilPage(),
                  ),
                );
              },
            ),
            _menuItem(
              icon: Icons.lock_outline,
              title: "Alterar Senha",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlterarSenhaPage(),
                  ),
                );
              },
            ),
            _menuItem(
              icon: Icons.support_agent_outlined,
              title: "Suporte",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SuportePage()),
                );
              },
            ),
            _menuItem(
              icon: Icons.settings_outlined,
              title: "Configurações",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracoesPage(),
                  ),
                );
              },
            ),
            _menuItem(
              icon: Icons.logout,
              title: "Sair",
              color: Colors.red,
              onTap: _confirmarSaida,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para cartões de informação
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF0B2A4A)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para itens do menu
  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: color == Colors.red ? Colors.red : Colors.grey,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
