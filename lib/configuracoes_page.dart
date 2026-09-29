import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/suporte_page.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/settings_widgets.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  static const _versaoApp = '0.1.0';

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
    final scheme = Theme.of(context).colorScheme;
    final nome = AppSession.nome.trim();
    final email = AppSession.email.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const AppGradientHeader(
              title: 'Configurações',
              subtitle: 'Ajuste o aplicativo do seu jeito',
              icon: Icons.tune_rounded,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  28 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  SettingsProfileCard(
                    name: nome.isEmpty ? 'Cliente GeoSync' : nome,
                    email: email.isEmpty ? 'E-mail não informado' : email,
                    initial: AppSession.inicialNome,
                    role: 'Cliente',
                    roleIcon: Icons.verified_rounded,
                  ),

                  const SettingsSectionTitle(
                    'Aparência',
                    subtitle: 'Escolha como o GeoSync é exibido',
                  ),
                  SettingsThemeSelector(
                    darkMode: _modoEscuro,
                    onChanged: (valor) {
                      if (valor == _modoEscuro) return;
                      setState(() => _modoEscuro = valor);
                      AppSession.definirModoEscuro(valor);
                    },
                  ),

                  const SettingsSectionTitle('Notificações'),
                  SettingsGroup(
                    children: [
                      SettingsSwitchTile(
                        icon: _notificacoes
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: SettingsColors.amber,
                        title: 'Notificações',
                        subtitle: _notificacoes
                            ? 'Alertas com som e vibração ativados'
                            : 'Você não receberá alertas',
                        value: _notificacoes,
                        onChanged: _alterarNotificacoes,
                      ),
                    ],
                  ),

                  const SettingsSectionTitle('Segurança'),
                  SettingsGroup(
                    children: [
                      SettingsActionTile(
                        icon: Icons.lock_reset_rounded,
                        color: SettingsColors.blue,
                        title: 'Alterar senha',
                        subtitle: 'Atualize a senha da sua conta',
                        onTap: _alterarSenha,
                      ),
                      SettingsActionTile(
                        icon: Icons.shield_rounded,
                        color: SettingsColors.green,
                        title: 'Privacidade e segurança',
                        subtitle: 'Saiba como seus dados são usados',
                        onTap: _abrirPrivacidade,
                      ),
                    ],
                  ),

                  const SettingsSectionTitle('Ajuda'),
                  SettingsGroup(
                    children: [
                      SettingsActionTile(
                        icon: Icons.support_agent_rounded,
                        color: SettingsColors.teal,
                        title: 'Ajuda e suporte',
                        subtitle: 'Fale com a equipe GeoSync',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuportePage(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SettingsSectionTitle('Sobre'),
                  const SettingsGroup(
                    children: [
                      SettingsInfoTile(
                        icon: Icons.local_shipping_rounded,
                        color: SettingsColors.indigo,
                        title: 'Aplicativo',
                        value: 'GeoSync',
                      ),
                      SettingsInfoTile(
                        icon: Icons.info_rounded,
                        color: SettingsColors.slate,
                        title: 'Versão',
                        value: _versaoApp,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      'GeoSync • Logística inteligente',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11.5,
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
  // AÇÕES
  // ============================================================

  void _alterarNotificacoes(bool valor) {
    setState(() => _notificacoes = valor);
    AppSession.definirNotificacoesAtivas(valor);
    showSettingsMessage(
      context,
      valor ? 'Notificações ativadas.' : 'Notificações desativadas.',
    );
  }

  Future<void> _alterarSenha() async {
    final senhaAlterada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
    );
    if (senhaAlterada == true && mounted) {
      showSettingsMessage(context, 'Senha atualizada com sucesso.');
    }
  }

  void _abrirPrivacidade() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsSheetHeader(
                icon: Icons.shield_rounded,
                color: SettingsColors.green,
                title: 'Privacidade e segurança',
                subtitle: 'Transparência sobre os seus dados',
              ),
              const SizedBox(height: 20),
              const _ItemPrivacidade(
                icon: Icons.location_on_rounded,
                titulo: 'Rastreamento de remessas',
                descricao:
                    'Usamos a localização apenas para acompanhar suas entregas em tempo real.',
              ),
              const _ItemPrivacidade(
                icon: Icons.lock_rounded,
                titulo: 'Conexão protegida',
                descricao:
                    'Seu acesso é autenticado por token e suas informações trafegam de forma segura.',
              ),
              const _ItemPrivacidade(
                icon: Icons.visibility_off_rounded,
                titulo: 'Sem compartilhamento indevido',
                descricao:
                    'Seus dados são usados somente para os serviços de gerenciamento do GeoSync.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemPrivacidade extends StatelessWidget {
  const _ItemPrivacidade({
    required this.icon,
    required this.titulo,
    required this.descricao,
  });

  final IconData icon;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
