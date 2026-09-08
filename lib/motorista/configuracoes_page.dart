import 'package:flutter/material.dart';
import 'package:mobile/app_session.dart';

class ConfiguracoesMotoristaPage extends StatefulWidget {
  const ConfiguracoesMotoristaPage({super.key});

  @override
  State<ConfiguracoesMotoristaPage> createState() =>
      _ConfiguracoesMotoristaPageState();
}

class _ConfiguracoesMotoristaPageState
    extends State<ConfiguracoesMotoristaPage> {
  static const Color primary = Color(0xFF0C46FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);
  static const Color border = Color(0xFFE8ECF3);

  bool notificacoes = true;
  bool novasEntregas = true;
  bool localizacao = true;
  bool modoEconomia = false;
  bool modoEscuro = AppSession.modoEscuro.value;

  @override
  void initState() {
    super.initState();
    AppSession.modoEscuro.addListener(_sincronizarTema);
  }

  @override
  void dispose() {
    AppSession.modoEscuro.removeListener(_sincronizarTema);
    super.dispose();
  }

  void _sincronizarTema() {
    if (mounted && modoEscuro != AppSession.modoEscuro.value) {
      setState(() => modoEscuro = AppSession.modoEscuro.value);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: modoEscuro ? const Color(0xFF0F172A) : background,
      appBar: AppBar(
        title: Text(
          "Configurações",
          style: TextStyle(
            color: modoEscuro ? Colors.white : textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: modoEscuro ? const Color(0xFF0F172A) : background,
        elevation: 0,
        iconTheme: IconThemeData(color: modoEscuro ? Colors.white : textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Preferências"),

          _switchItem(
            icon: Icons.dark_mode_outlined,
            titulo: "Modo escuro",
            subtitulo: modoEscuro
                ? "Aparência escura ativada"
                : "Usar aparência clara",
            valor: modoEscuro,
            onChanged: (valor) {
              setState(() => modoEscuro = valor);
              AppSession.definirModoEscuro(valor);
            },
          ),

          _switchItem(
            icon: Icons.notifications_none_rounded,
            titulo: "Notificações",
            subtitulo: "Receber avisos e atualizações",
            valor: notificacoes,
            onChanged: (valor) {
              setState(() {
                notificacoes = valor;
              });

              _mostrarMensagem(
                valor ? "Notificações ativadas." : "Notificações desativadas.",
              );
            },
          ),

          _switchItem(
            icon: Icons.local_shipping_outlined,
            titulo: "Novas entregas",
            subtitulo: "Receber novas oportunidades de entrega",
            valor: novasEntregas,
            onChanged: (valor) {
              setState(() {
                novasEntregas = valor;
              });
            },
          ),

          _switchItem(
            icon: Icons.location_on_outlined,
            titulo: "Localização",
            subtitulo: "Permitir rastreamento durante as entregas",
            valor: localizacao,
            onChanged: (valor) {
              setState(() {
                localizacao = valor;
              });

              _mostrarMensagem(
                valor ? "Localização ativada." : "Localização desativada.",
              );
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle("Desempenho"),

          _switchItem(
            icon: Icons.battery_saver_outlined,
            titulo: "Economia de bateria",
            subtitulo: "Reduz atualizações em segundo plano",
            valor: modoEconomia,
            onChanged: (valor) {
              setState(() {
                modoEconomia = valor;
              });
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle("Conta"),

          _actionItem(
            icon: Icons.person_outline_rounded,
            titulo: "Dados pessoais",
            subtitulo: "Nome, telefone e e-mail",
            onTap: () {
              _mostrarMensagem("Área de dados pessoais selecionada.");
            },
          ),

          _actionItem(
            icon: Icons.lock_outline_rounded,
            titulo: "Alterar senha",
            subtitulo: "Atualize a senha da sua conta",
            onTap: () {
              _abrirAlterarSenha();
            },
          ),

          _actionItem(
            icon: Icons.help_outline_rounded,
            titulo: "Ajuda e suporte",
            subtitulo: "Fale com o suporte GeoSync",
            onTap: () {
              _mostrarMensagem("Suporte selecionado.");
            },
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _mostrarMensagem("Preferências salvas com sucesso!");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Salvar configurações",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        titulo,
        style: TextStyle(
          color: modoEscuro ? Colors.white : textDark,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: modoEscuro ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: modoEscuro ? Colors.white12 : border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: modoEscuro ? Colors.white : textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: modoEscuro ? Colors.white60 : textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: valor, activeThumbColor: primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: modoEscuro ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: modoEscuro ? Colors.white12 : border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: modoEscuro ? Colors.white : textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          color: modoEscuro ? Colors.white60 : textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirAlterarSenha() {
    final senhaController = TextEditingController();
    final confirmarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Alterar senha",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nova senha"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmarController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmar senha"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (senhaController.text.isEmpty ||
                    confirmarController.text.isEmpty) {
                  return;
                }

                if (senhaController.text != confirmarController.text) {
                  _mostrarMensagem("As senhas não coincidem.");
                  return;
                }

                Navigator.pop(context);

                _mostrarMensagem("Senha alterada com sucesso!");
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }
}
