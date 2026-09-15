import 'package:flutter/material.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/widgets/responsive_content.dart';
import 'package:mobile/suporte_page.dart';

class ConfiguracoesMotoristaPage extends StatefulWidget {
  const ConfiguracoesMotoristaPage({super.key});
  @override
  State<ConfiguracoesMotoristaPage> createState() =>
      _ConfiguracoesMotoristaPageState();
}

class _ConfiguracoesMotoristaPageState
    extends State<ConfiguracoesMotoristaPage> {
  static const primary = Color(0xFF0C46FF);
  late bool notificacoes, novasEntregas, localizacao, modoEconomia;
  bool get modoEscuro => AppSession.modoEscuro.value;
  @override
  void initState() {
    super.initState();
    final c = AppSession.configuracoesMotorista.value;
    notificacoes = c.notificacoes;
    novasEntregas = c.novasEntregas;
    localizacao = c.localizacao;
    modoEconomia = c.modoEconomia;
    AppSession.modoEscuro.addListener(_tema);
  }

  @override
  void dispose() {
    AppSession.modoEscuro.removeListener(_tema);
    super.dispose();
  }

  void _tema() {
    if (mounted) setState(() {});
  }

  void _salvar() {
    AppSession.salvarConfiguracoes(
      ConfiguracoesMotorista(
        notificacoes: notificacoes,
        novasEntregas: novasEntregas,
        localizacao: localizacao,
        modoEconomia: modoEconomia,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferências salvas com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dadosPessoais() {
    final nome = TextEditingController(text: 'Carlos Silva');
    final telefone = TextEditingController(text: '(11) 99999-9999');
    final email = TextEditingController(text: 'carlos@geosync.com');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dados pessoais'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(nome, 'Nome'),
            _input(telefone, 'Telefone'),
            _input(email, 'E-mail'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nome.text.trim().isEmpty ||
                  telefone.text.trim().isEmpty ||
                  email.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados pessoais atualizados.')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configurações')),
    body: ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _titulo('Preferências'),
          _switch(
            Icons.dark_mode_outlined,
            'Modo escuro',
            modoEscuro ? 'Aparência escura ativada' : 'Usar aparência clara',
            modoEscuro,
            (v) => AppSession.definirModoEscuro(v),
          ),
          _switch(
            Icons.notifications_none_rounded,
            'Notificações',
            'Receber avisos e atualizações',
            notificacoes,
            (v) => setState(() => notificacoes = v),
          ),
          _switch(
            Icons.local_shipping_outlined,
            'Novas entregas',
            'Receber novas oportunidades de entrega',
            novasEntregas,
            (v) => setState(() => novasEntregas = v),
          ),
          _switch(
            Icons.location_on_outlined,
            'Localização',
            'Permitir rastreamento durante as entregas',
            localizacao,
            (v) => setState(() => localizacao = v),
          ),
          const SizedBox(height: 20),
          _titulo('Desempenho'),
          _switch(
            Icons.battery_saver_outlined,
            'Economia de bateria',
            'Reduz atualizações em segundo plano',
            modoEconomia,
            (v) => setState(() => modoEconomia = v),
          ),
          const SizedBox(height: 20),
          _titulo('Conta'),
          _acao(
            Icons.person_outline_rounded,
            'Dados pessoais',
            'Nome, telefone e e-mail',
            _dadosPessoais,
          ),
          _acao(
            Icons.lock_outline_rounded,
            'Alterar senha',
            'Atualize a senha da sua conta',
            () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
              );
              if (ok == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha alterada com sucesso.')),
                );
              }
            },
          ),
          _acao(
            Icons.help_outline_rounded,
            'Ajuda e suporte',
            'Fale com o suporte GeoSync',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuportePage()),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Salvar configurações'),
          ),
        ],
      ),
    ),
  );
  Widget _titulo(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
  );
  Widget _switch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> changed,
  ) => Card(
    child: SwitchListTile(
      secondary: Icon(icon, color: primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: primary,
      onChanged: changed,
    ),
  );
  Widget _acao(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) => Card(
    child: ListTile(
      leading: Icon(icon, color: primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
      onTap: tap,
    ),
  );
}
