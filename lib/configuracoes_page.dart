import 'package:flutter/material.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool _notificacoes = true;
  bool _biometria = false;
  bool _modoEscuro = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Text('Configurações', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações Push',
            subtitle: 'Receber alertas de rastreamento',
            value: _notificacoes,
            onChanged: (val) => setState(() => _notificacoes = val),
          ),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'Login por Biometria / Face ID',
            subtitle: 'Aumentar a segurança no acesso',
            value: _biometria,
            onChanged: (val) => setState(() => _biometria = val),
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Modo Escuro',
            subtitle: 'Ajustar o tema do aplicativo',
            value: _modoEscuro,
            onChanged: (val) => setState(() => _modoEscuro = val),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF0B2A4A)),
              title: const Text('Idioma do App', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Text('Português (BR)', style: TextStyle(color: Colors.grey)),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF0B2A4A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        activeColor: const Color(0xFF0B2A4A),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}