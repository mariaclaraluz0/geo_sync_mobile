import 'package:flutter/material.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  // ============================================================
  // PALETA GEOSYNC
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);

  static const Color background = Color(0xFFF5F7FB);

  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);

  static const Color border = Color(0xFFE8ECF3);

  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  bool _notificacoes = true;
  bool _biometria = false;
  final bool _modoEscuro = false;

  String _idiomaSelecionado = "Português (BR)";
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _modoEscuro
          ? ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              colorScheme: ColorScheme.dark(
                primary: primary,
                secondary: primary,
                surface: const Color(0xFF172033),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            )
          : ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: background,
              colorScheme: const ColorScheme.light(
                primary: primary,
                secondary: primary,
                surface: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
      child: Scaffold(
        backgroundColor: _modoEscuro ? const Color(0xFF0F172A) : background,
        appBar: AppBar(
          title: const Text(
            'Configurações',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          children: [
            _buildCabecalho(),

            const SizedBox(height: 22),

            _buildTituloSecao(
              "Preferências",
              "Personalize sua experiência no GeoSync",
            ),

            const SizedBox(height: 12),

            // ====================================================
            // NOTIFICAÇÕES
            // ====================================================
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notificações Push',
              subtitle: _notificacoes
                  ? 'Você receberá alertas de rastreamento'
                  : 'As notificações estão desativadas',
              value: _notificacoes,
              onChanged: (val) {
                setState(() {
                  _notificacoes = val;
                });

                _mostrarMensagem(
                  val ? "Notificações ativadas." : "Notificações desativadas.",
                );
              },
            ),

            // ====================================================
            // BIOMETRIA
            // ====================================================
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Login por Biometria / Face ID',
              subtitle: _biometria
                  ? 'Acesso biométrico ativado'
                  : 'Usar biometria para entrar',
              value: _biometria,
              onChanged: (val) {
                setState(() {
                  _biometria = val;
                });

                _mostrarMensagem(
                  val
                      ? "Login biométrico ativado."
                      : "Login biométrico desativado.",
                );
              },
            ),

            const SizedBox(height: 24),

            // ====================================================
            // IDIOMA
            // ====================================================
            _buildTituloSecao("Aplicativo", "Configure as opções gerais"),

            const SizedBox(height: 12),

            _buildIdiomaCard(),

            const SizedBox(height: 24),

            // ====================================================
            // SEGURANÇA
            // ====================================================
            _buildTituloSecao("Segurança", "Proteja sua conta e seus dados"),

            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.lock_outline_rounded,
              title: "Alterar senha",
              subtitle: "Atualize a senha da sua conta",
              onTap: _alterarSenha,
            ),

            _buildActionCard(
              icon: Icons.security_outlined,
              title: "Privacidade e segurança",
              subtitle: "Gerencie suas preferências de segurança",
              onTap: _abrirPrivacidade,
            ),

            const SizedBox(height: 24),

            // ====================================================
            // INFORMAÇÕES
            // ====================================================
            _buildTituloSecao("Sobre", "Informações do aplicativo"),

            const SizedBox(height: 12),

            _buildInformacaoCard(),

            const SizedBox(height: 25),

            Center(
              child: Text(
                "GeoSync • Configurações",
                style: TextStyle(
                  color: _modoEscuro ? Colors.white54 : textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _buildCabecalho() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personalize o GeoSync",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Ajuste o aplicativo do seu jeito.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TÍTULO DE SEÇÃO
  // ============================================================

  Widget _buildTituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: _modoEscuro ? Colors.white : textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitulo,
          style: TextStyle(
            color: _modoEscuro ? Colors.white60 : textLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SWITCH
  // ============================================================

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _modoEscuro ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _modoEscuro ? Colors.white.withValues(alpha: 0.06) : border,
        ),
        boxShadow: _modoEscuro
            ? null
            : [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        secondary: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _modoEscuro ? Colors.white : textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              color: _modoEscuro ? Colors.white60 : textLight,
              fontSize: 11,
            ),
          ),
        ),
        activeThumbColor: primary,
        activeTrackColor: primary.withValues(alpha: 0.35),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: _modoEscuro ? Colors.white24 : border,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  // ============================================================
  // IDIOMA
  // ============================================================

  Widget _buildIdiomaCard() {
    return _buildActionCard(
      icon: Icons.language_rounded,
      title: "Idioma do aplicativo",
      subtitle: _idiomaSelecionado,
      trailing: Icons.keyboard_arrow_down_rounded,
      onTap: _selecionarIdioma,
    );
  }

  // ============================================================
  // CARD DE AÇÃO
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _modoEscuro ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _modoEscuro ? Colors.white.withValues(alpha: 0.06) : border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: primary, size: 22),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _modoEscuro ? Colors.white : textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _modoEscuro ? Colors.white60 : textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  trailing ?? Icons.chevron_right_rounded,
                  color: _modoEscuro ? Colors.white54 : textLight,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES
  // ============================================================

  Widget _buildInformacaoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _modoEscuro ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _modoEscuro ? Colors.white.withValues(alpha: 0.06) : border,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow("Versão", "1.0.0", Icons.info_outline_rounded),
          const SizedBox(height: 14),
          _buildInfoRow("Aplicativo", "GeoSync", Icons.local_shipping_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: _modoEscuro ? Colors.white70 : textLight,
              fontSize: 12,
            ),
          ),
        ),

        Text(
          valor,
          style: TextStyle(
            color: _modoEscuro ? Colors.white : textDark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELEÇÃO DE IDIOMA
  // ============================================================

  void _selecionarIdioma() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _modoEscuro ? const Color(0xFF172033) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Idioma do aplicativo",
                style: TextStyle(
                  color: _modoEscuro ? Colors.white : textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _buildIdiomaOption("Português (BR)"),
              _buildIdiomaOption("English"),
              _buildIdiomaOption("Español"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdiomaOption(String idioma) {
    final bool selecionado = idioma == _idiomaSelecionado;

    return ListTile(
      onTap: () {
        setState(() {
          _idiomaSelecionado = idioma;
        });

        Navigator.pop(context);

        _mostrarMensagem("Idioma alterado para $idioma.");
      },
      leading: Icon(
        selecionado ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selecionado ? primary : textLight,
      ),
      title: Text(
        idioma,
        style: TextStyle(
          color: _modoEscuro ? Colors.white : textDark,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  void _alterarSenha() {
    _mostrarMensagem("Acesse seu perfil para alterar a senha.");
  }

  // ============================================================
  // PRIVACIDADE
  // ============================================================

  void _abrirPrivacidade() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _modoEscuro ? const Color(0xFF172033) : Colors.white,
          title: Text(
            "Privacidade e segurança",
            style: TextStyle(
              color: _modoEscuro ? Colors.white : textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Suas informações são utilizadas para fornecer os serviços de rastreamento e gerenciamento do GeoSync.",
            style: TextStyle(
              color: _modoEscuro ? Colors.white70 : textLight,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Fechar",
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
