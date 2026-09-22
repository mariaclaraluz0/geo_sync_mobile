import 'package:flutter/material.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/widgets/app_gradient_header.dart';

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

  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);

  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  bool _notificacoes = AppSession.notificacoesAtivas.value;
  bool _modoEscuro = AppSession.modoEscuro.value;

  @override
  void initState() {
    super.initState();
    AppSession.modoEscuro.addListener(_sincronizarTema);
    AppSession.notificacoesAtivas.addListener(_sincronizarNotificacoes);
  }

  @override
  void dispose() {
    AppSession.modoEscuro.removeListener(_sincronizarTema);
    AppSession.notificacoesAtivas.removeListener(_sincronizarNotificacoes);
    super.dispose();
  }

  void _sincronizarTema() {
    if (mounted && _modoEscuro != AppSession.modoEscuro.value) {
      setState(() => _modoEscuro = AppSession.modoEscuro.value);
    }
  }

  void _sincronizarNotificacoes() {
    if (mounted && _notificacoes != AppSession.notificacoesAtivas.value) {
      setState(() => _notificacoes = AppSession.notificacoesAtivas.value);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppGradientHeader(
                title: 'Configurações',
                subtitle: 'Ajuste o aplicativo do seu jeito',
                icon: Icons.settings_outlined,
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                  children: [
            _buildTituloSecao(
              "Preferências",
              "Personalize sua experiência no GeoSync",
            ),

            const SizedBox(height: 12),

            // ====================================================
            // NOTIFICAÇÕES
            // ====================================================
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Modo escuro',
              subtitle: _modoEscuro
                  ? 'Cores escuras ativadas'
                  : 'Usar aparência clara',
              value: _modoEscuro,
              onChanged: (val) {
                setState(() => _modoEscuro = val);
                AppSession.definirModoEscuro(val);
              },
            ),

            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              subtitle: _notificacoes
                  ? 'Você receberá alertas com som e vibração'
                  : 'As notificações estão desativadas',
              value: _notificacoes,
              onChanged: (val) {
                setState(() => _notificacoes = val);
                AppSession.definirNotificacoesAtivas(val);
                _mostrarMensagem(
                  val ? "Notificações ativadas." : "Notificações desativadas.",
                );
              },
            ),

            const SizedBox(height: 24),

            // ====================================================
            // SEGURANÇA
            // ====================================================
            _buildTituloSecao("Segurança", "Proteja sua conta e seus dados"),

            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.lock_outline,
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
            ],
          ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
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
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        activeThumbColor: primary,
        activeTrackColor: primary.withValues(alpha: 0.35),
        inactiveThumbColor: scheme.onSurface,
        inactiveTrackColor: scheme.outlineVariant,
        value: value,
        onChanged: onChanged,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
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
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  trailing ?? Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow("Versão", "1.0.0", Icons.info_outline),
          const SizedBox(height: 14),
          _buildInfoRow("Aplicativo", "GeoSync", Icons.local_shipping_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),

        Text(
          valor,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  Future<void> _alterarSenha() async {
    final senhaAlterada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
    );
    if (senhaAlterada == true && mounted) {
      _mostrarMensagem("Senha atualizada com sucesso.");
    }
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
