import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/motorista/sincronizacao_widgets.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/suporte_page.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/responsive_content.dart';
import 'package:mobile/widgets/settings_widgets.dart';

class ConfiguracoesMotoristaPage extends StatefulWidget {
  const ConfiguracoesMotoristaPage({super.key});

  @override
  State<ConfiguracoesMotoristaPage> createState() =>
      _ConfiguracoesMotoristaPageState();
}

class _ConfiguracoesMotoristaPageState
    extends State<ConfiguracoesMotoristaPage> {
  late bool _notificacoes, _novasEntregas, _localizacao, _modoEconomia;

  bool get _modoEscuro => AppSession.modoEscuro.value;

  /// Indica se há preferências alteradas que ainda não foram salvas.
  bool get _temAlteracoes {
    final salvas = AppSession.configuracoesMotorista.value;
    return _notificacoes != AppSession.notificacoesAtivas.value ||
        _novasEntregas != salvas.novasEntregas ||
        _localizacao != salvas.localizacao ||
        _modoEconomia != salvas.modoEconomia;
  }

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
    AppSession.modoEscuro.addListener(_atualizar);
  }

  @override
  void dispose() {
    AppSession.modoEscuro.removeListener(_atualizar);
    super.dispose();
  }

  void _carregarPreferencias() {
    final c = AppSession.configuracoesMotorista.value;
    _notificacoes = AppSession.notificacoesAtivas.value;
    _novasEntregas = c.novasEntregas;
    _localizacao = c.localizacao;
    _modoEconomia = c.modoEconomia;
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  void _salvar() {
    AppSession.salvarConfiguracoes(
      ConfiguracoesMotorista(
        notificacoes: _notificacoes,
        novasEntregas: _novasEntregas,
        localizacao: _localizacao,
        modoEconomia: _modoEconomia,
      ),
    );
    AppSession.definirNotificacoesAtivas(_notificacoes);
    setState(() {});
    showSettingsMessage(context, 'Preferências salvas com sucesso.');
  }

  void _descartar() => setState(_carregarPreferencias);

  Future<void> _confirmarSaida() async {
    final acao = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(LucideIcons.save, size: 30),
        title: const Text('Salvar alterações?'),
        content: const Text(
          'Você alterou suas preferências. Deseja salvá-las antes de sair?',
          textAlign: TextAlign.center,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'salvar'),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (!mounted || acao == null) return;
    if (acao == 'salvar') {
      _salvar();
    } else {
      _descartar();
    }
    Navigator.of(context).pop();
  }

  Future<void> _dadosPessoais() async {
    final atualizado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _DadosPessoaisSheet(),
    );
    if (atualizado == true && mounted) {
      setState(() {});
      showSettingsMessage(context, 'Dados pessoais atualizados.');
    }
  }

  Future<void> _alterarSenha() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
    );
    if (ok == true && mounted) {
      showSettingsMessage(context, 'Senha alterada com sucesso.');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final nome = AppSession.nome.trim();
    final email = AppSession.email.trim();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: !_temAlteracoes,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSaida();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Column(
            children: [
              const AppGradientHeader(
                title: 'Configurações',
                subtitle: 'Preferências do motorista',
                icon: LucideIcons.slidersHorizontal,
              ),
              Expanded(
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      (_temAlteracoes ? 110 : 28) + bottomInset,
                    ),
                    children: [
                      SettingsProfileCard(
                        name: nome.isEmpty ? 'Motorista GeoSync' : nome,
                        email: email.isEmpty ? 'E-mail não informado' : email,
                        initial: AppSession.inicialNome,
                        role: 'Motorista parceiro',
                        roleIcon: LucideIcons.truck,
                        onTap: _dadosPessoais,
                      ),

                      const SettingsSectionTitle(
                        'Aparência',
                        subtitle: 'Escolha como o GeoSync é exibido',
                      ),
                      SettingsThemeSelector(
                        darkMode: _modoEscuro,
                        onChanged: (valor) {
                          if (valor != _modoEscuro) {
                            AppSession.definirModoEscuro(valor);
                          }
                        },
                      ),

                      const SettingsSectionTitle(
                        'Notificações',
                        subtitle: 'Controle os avisos que você recebe',
                      ),
                      SettingsGroup(
                        children: [
                          SettingsSwitchTile(
                            icon: _notificacoes
                                ? LucideIcons.bellRing
                                : LucideIcons.bellOff,
                            color: SettingsColors.amber,
                            title: 'Notificações',
                            subtitle: _notificacoes
                                ? 'Receber avisos e atualizações'
                                : 'Todos os avisos estão pausados',
                            value: _notificacoes,
                            onChanged: (v) => setState(() => _notificacoes = v),
                          ),
                          SettingsSwitchTile(
                            icon: LucideIcons.milestone,
                            color: SettingsColors.blue,
                            title: 'Novas entregas',
                            subtitle: _notificacoes
                                ? 'Avisar sobre novas oportunidades'
                                : 'Ative as notificações para usar',
                            value: _notificacoes && _novasEntregas,
                            enabled: _notificacoes,
                            onChanged: (v) =>
                                setState(() => _novasEntregas = v),
                          ),
                        ],
                      ),

                      const SettingsSectionTitle(
                        'Rastreamento e desempenho',
                        subtitle: 'Equilibre precisão e consumo de bateria',
                      ),
                      SettingsGroup(
                        children: [
                          SettingsSwitchTile(
                            icon: _localizacao
                                ? LucideIcons.locateFixed
                                : LucideIcons.locateOff,
                            color: SettingsColors.green,
                            title: 'Localização',
                            subtitle: _localizacao
                                ? 'Rastreamento ativo durante as entregas'
                                : 'O cliente não verá sua posição',
                            value: _localizacao,
                            onChanged: (v) => setState(() => _localizacao = v),
                          ),
                          SettingsSwitchTile(
                            icon: _modoEconomia
                                ? LucideIcons.leaf
                                : LucideIcons.batteryFull,
                            color: SettingsColors.teal,
                            title: 'Economia de bateria',
                            subtitle: _modoEconomia
                                ? 'Menos atualizações em segundo plano'
                                : 'Atualizações em tempo real',
                            value: _modoEconomia,
                            onChanged: (v) => setState(() => _modoEconomia = v),
                          ),
                        ],
                      ),

                      const SettingsSectionTitle(
                        'Dados e sincronização',
                        subtitle: 'Funciona offline e envia quando houver rede',
                      ),
                      const SecaoSincronizacao(),

                      const SettingsSectionTitle('Conta'),
                      SettingsGroup(
                        children: [
                          SettingsActionTile(
                            icon: LucideIcons.idCard,
                            color: SettingsColors.indigo,
                            title: 'Dados pessoais',
                            subtitle: 'Nome, telefone e e-mail',
                            onTap: _dadosPessoais,
                          ),
                          SettingsActionTile(
                            icon: LucideIcons.keyRound,
                            color: SettingsColors.violet,
                            title: 'Alterar senha',
                            subtitle: 'Atualize a senha da sua conta',
                            onTap: _alterarSenha,
                          ),
                          SettingsActionTile(
                            icon: LucideIcons.headset,
                            color: SettingsColors.rose,
                            title: 'Ajuda e suporte',
                            subtitle: 'Fale com o suporte GeoSync',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SuportePage(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),
                      Center(
                        child: Text(
                          'GeoSync • Versão 0.1.0',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BarraSalvar(
            visivel: _temAlteracoes,
            onSalvar: _salvar,
            onDescartar: _descartar,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BARRA DE SALVAR
// ============================================================

/// Barra fixa que aparece somente quando existem alterações pendentes.
class _BarraSalvar extends StatelessWidget {
  const _BarraSalvar({
    required this.visivel,
    required this.onSalvar,
    required this.onDescartar,
  });

  final bool visivel;
  final VoidCallback onSalvar;
  final VoidCallback onDescartar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !visivel
          ? const SizedBox(width: double.infinity)
          : Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDescartar,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: BorderSide(color: scheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Descartar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: onSalvar,
                          icon: const Icon(LucideIcons.check, size: 20),
                          label: const Text(
                            'Salvar alterações',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// DADOS PESSOAIS
// ============================================================

class _DadosPessoaisSheet extends StatefulWidget {
  const _DadosPessoaisSheet();

  @override
  State<_DadosPessoaisSheet> createState() => _DadosPessoaisSheetState();
}

class _DadosPessoaisSheetState extends State<_DadosPessoaisSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController(text: AppSession.nome);
  final _telefone = TextEditingController();
  final _email = TextEditingController(text: AppSession.email);
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Busca o telefone (e dados mais recentes) na API para pré-preencher.
  Future<void> _carregarPerfil() async {
    try {
      final api = ApiService.instance;
      final usuario = api.authUser(api.authData(await api.me()));
      if (!mounted) return;
      final nome = '${usuario['name'] ?? usuario['nome'] ?? ''}'.trim();
      final email = '${usuario['email'] ?? ''}'.trim();
      final telefone = '${usuario['telefone'] ?? usuario['phone'] ?? ''}'
          .trim();
      if (nome.isNotEmpty && _nome.text.trim().isEmpty) _nome.text = nome;
      if (email.isNotEmpty && _email.text.trim().isEmpty) _email.text = email;
      if (telefone.isNotEmpty && _telefone.text.trim().isEmpty) {
        _telefone.text = telefone;
      }
    } on ApiException {
      // Sem conexão: o motorista ainda pode preencher os campos manualmente.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final nome = _nome.text.trim();
    final email = _email.text.trim();
    try {
      await ApiService.instance.updateProfile({
        'name': nome,
        'telefone': _telefone.text.trim(),
        'email': email,
      });
      await AppSession.atualizarDadosUsuario(nome: nome, email: email);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SettingsSheetHeader(
                  icon: LucideIcons.idCard,
                  color: SettingsColors.indigo,
                  title: 'Dados pessoais',
                  subtitle: 'Mantenha seu cadastro atualizado',
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _carregando
                      ? const LinearProgressIndicator(minHeight: 3)
                      : const SizedBox(height: 3),
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _nome,
                  label: 'Nome completo',
                  icon: LucideIcons.user,
                  keyboard: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  autofill: AutofillHints.name,
                  validator: (v) => (v ?? '').trim().length < 3
                      ? 'Informe seu nome completo'
                      : null,
                ),
                _campo(
                  controller: _telefone,
                  label: 'Telefone',
                  hint: '(00) 00000-0000',
                  icon: LucideIcons.phone,
                  keyboard: TextInputType.phone,
                  autofill: AutofillHints.telephoneNumber,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9()+\- ]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) {
                    final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digitos.length < 10
                        ? 'Informe um telefone válido com DDD'
                        : null;
                  },
                ),
                _campo(
                  controller: _email,
                  label: 'E-mail',
                  icon: LucideIcons.atSign,
                  keyboard: TextInputType.emailAddress,
                  autofill: AutofillHints.email,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _salvar(),
                  validator: (v) {
                    final valor = (v ?? '').trim();
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor)
                        ? null
                        : 'Informe um e-mail válido';
                  },
                ),
                if (_erro != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          color: scheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: TextStyle(color: scheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _salvando
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: scheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _salvando || _carregando ? null : _salvar,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Salvar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FormFieldValidator<String> validator,
    String? hint,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    String? autofill,
    List<TextInputFormatter>? formatters,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_salvando,
        keyboardType: keyboard,
        textCapitalization: capitalization,
        textInputAction: action,
        autofillHints: autofill == null ? null : [autofill],
        inputFormatters: formatters,
        onFieldSubmitted: onSubmitted,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          fillColor: scheme.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.error, width: 1.6),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}
