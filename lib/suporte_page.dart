import 'package:flutter/material.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Text('Atendimento e Suporte', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Como podemos ajudar?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildOptionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat em Tempo Real',
            subtitle: 'Fale com nosso atendente virtual',
            onTap: () {},
          ),
          _buildOptionCard(
            icon: Icons.help_outline,
            title: 'Perguntas Frequentes (FAQ)',
            subtitle: 'Tire suas dúvidas rapidamente',
            onTap: () {},
          ),
          _buildOptionCard(
            icon: Icons.email_outlined,
            title: 'Enviar um E-mail',
            subtitle: 'suporte@geosync.com.br',
            onTap: () {},
          ),
          _buildOptionCard(
            icon: Icons.headset_mic_outlined,
            title: 'Central Telefônica',
            subtitle: '0800 123 4567',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0B2A4A).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF0B2A4A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}