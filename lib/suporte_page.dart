import 'package:flutter/material.dart';

class SuportePage extends StatefulWidget {
  const SuportePage({super.key});

  @override
  State<SuportePage> createState() => _SuportePageState();
}

class _SuportePageState extends State<SuportePage> {
  final _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  void _enviarSolicitacao(String canal) {
    if (_mensagemController.text.trim().isEmpty) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solicitação enviada pelo $canal. Retornaremos em breve.',
        ),
      ),
    );
    _mensagemController.clear();
  }

  void _abrirFormulario(String titulo, String canal) {
    _mensagemController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Descreva sua dúvida e nossa equipe receberá sua solicitação.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mensagemController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _enviarSolicitacao(canal),
                child: const Text('Enviar solicitação'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFaq() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Perguntas frequentes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ExpansionTile(
            title: Text('Como acompanho uma remessa?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Acesse Remessas e selecione o pedido desejado para ver o rastreamento.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Como atualizo meus dados?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Abra Perfil e toque em Editar perfil.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Esqueci minha senha, o que faço?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Acesse Perfil e escolha Alterar senha.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Text(
          'Atendimento e Suporte',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Como podemos ajudar?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildOptionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat em Tempo Real',
            subtitle: 'Fale com nosso atendente virtual',
            onTap: () => _abrirFormulario('Chat com suporte', 'chat'),
          ),
          _buildOptionCard(
            icon: Icons.help_outline,
            title: 'Perguntas Frequentes (FAQ)',
            subtitle: 'Tire suas dúvidas rapidamente',
            onTap: _abrirFaq,
          ),
          _buildOptionCard(
            icon: Icons.email_outlined,
            title: 'Enviar um E-mail',
            subtitle: 'suporte@geosync.com.br',
            onTap: () => _abrirFormulario('Enviar e-mail', 'e-mail'),
          ),
          _buildOptionCard(
            icon: Icons.headset_mic_outlined,
            title: 'Central Telefônica',
            subtitle: '0800 123 4567',
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Central telefônica'),
                content: const Text(
                  'Ligue gratuitamente para 0800 123 4567, de segunda a sexta, das 8h às 18h.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendi'),
                  ),
                ],
              ),
            ),
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
          backgroundColor: const Color(0xFF0B2A4A).withValues(alpha: 0.1),
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
