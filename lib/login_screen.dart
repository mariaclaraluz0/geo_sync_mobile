import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/tela_dashboard.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';
import 'package:mobile/cadastro_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/esqueceu_senha_page.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String _tipoUsuario = 'Cliente';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _carregando = false;

  Future<void> _fazerLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _carregando = true);
      try {
        final resposta = await ApiService.instance.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final token = ApiService.instance.authToken(resposta);
        if (token == null) {
          throw ApiException(
            'Login aceito pela API, mas o token não foi encontrado na resposta. '
            'Verifique se o JSON retorna token, access_token ou accessToken.',
          );
        }
        final usuario = ApiService.instance.authUser(resposta);
        final tipoApi =
            '${usuario['tipo_usuario'] ?? usuario['tipo'] ?? _tipoUsuario}';
        final tipo = tipoApi.toLowerCase() == 'motorista'
            ? 'Motorista'
            : 'Cliente';
        await AppSession.iniciarSessao(
          token: token,
          tipoUsuario: tipo,
          email: '${usuario['email'] ?? _emailController.text}',
          nome: '${usuario['name'] ?? usuario['nome'] ?? ''}',
        );
        if (!mounted) return;
        final destino = tipo == 'Cliente'
            ? const TelaDashboard(tipoUsuario: 'Cliente')
            : const MotoristaDashboard();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destino),
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      } finally {
        if (mounted) setState(() => _carregando = false);
      }
    }
  }

  Future<void> _configurarServidor() async {
    // A primeira configuração ainda não tem baseUrl; nesse caso, abra o
    // diálogo com o campo vazio em vez de falhar antes de mostrá-lo.
    var baseUrlAtual = '';
    try {
      baseUrlAtual = ApiService.baseUrl;
    } on ApiException {
      // Sem URL configurada (ou com uma URL inválida), o usuário pode
      // informar uma nova diretamente neste campo.
    }
    final controller = TextEditingController(text: baseUrlAtual);
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Servidor da API'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'URL do Laravel',
            hintText: 'https://api.suaempresa.com/api',
            prefixIcon: Icon(CupertinoIcons.cloud),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            icon: const Icon(CupertinoIcons.floppy_disk),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
    // Descarta só depois da animação de fechamento do diálogo, que ainda
    // usa o controller; descartar antes causa erro na tela.
    Future.delayed(const Duration(seconds: 1), controller.dispose);
    if (url == null || !mounted) return;
    try {
      await ApiService.saveBaseUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API configurada: ${ApiService.baseUrl}')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = scheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fundo Decorativo Superior
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  // Em tablets o formulário não se estica pela tela toda.
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // LOGO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                          width: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback caso a imagem da logo falhe no carregamento
                            return Icon(
                              CupertinoIcons.car_detailed,
                              size: 50,
                              color: primaryColor,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TÍTULOS PRINCIPAIS
                      Text(
                        'Bem-vindo de volta! 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Acesse sua conta para continuar',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // CARD DO FORMULÁRIO DE LOGIN
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SELETOR DE TIPO DE USUÁRIO (Alternador Moderno)
                              Text(
                                'Entrar como',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _buildUserTypeOption(
                                      label: 'Cliente',
                                      icon: CupertinoIcons.person,
                                      selectedIcon: CupertinoIcons.person_fill,
                                      isSelected: _tipoUsuario == 'Cliente',
                                      onTap: () => setState(
                                        () => _tipoUsuario = 'Cliente',
                                      ),
                                      activeColor: primaryColor,
                                    ),
                                    _buildUserTypeOption(
                                      label: 'Motorista',
                                      icon: LucideIcons.truck,
                                      selectedIcon: LucideIcons.truck600,
                                      isSelected: _tipoUsuario == 'Motorista',
                                      onTap: () => setState(
                                        () => _tipoUsuario = 'Motorista',
                                      ),
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // CAMPO EMAIL
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o seu e-mail';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Informe um e-mail válido';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  hintText: 'seu@email.com',
                                  prefixIcon: const Icon(
                                    CupertinoIcons.envelope,
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainer,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: scheme.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // CAMPO SENHA
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _fazerLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a sua senha';
                                  }
                                  if (value.length < 6) {
                                    return 'A senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(CupertinoIcons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? CupertinoIcons.eye_slash
                                          : CupertinoIcons.eye,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: scheme.surfaceContainer,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: scheme.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ESQUECEU A SENHA
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    final senhaRedefinida =
                                        await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EsqueceuSenhaPage(
                                              emailInicial:
                                                  _emailController.text,
                                            ),
                                          ),
                                        );
                                    if (!context.mounted) return;
                                    if (senhaRedefinida == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Se o e-mail estiver cadastrado, você receberá um link para criar uma nova senha.',
                                          ),
                                          backgroundColor: Color(0xFF16A34A),
                                        ),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: const Size(0, 44),
                                  ),
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // BOTÃO ENTRAR
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _carregando ? null : _fazerLogin,
                                  icon: Icon(
                                    _tipoUsuario == 'Cliente'
                                        ? CupertinoIcons.arrow_right_circle
                                        : LucideIcons.truck,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _carregando
                                        ? 'Entrando...'
                                        : 'Entrar como $_tipoUsuario',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    elevation: 2,
                                    shadowColor: primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _configurarServidor,
                                  icon: const Icon(
                                    CupertinoIcons.slider_horizontal_3,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Configurar servidor da API',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // REGISTRO DE CONTA
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Não tem uma conta?',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CadastroScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Cadastre-se',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // VERSÃO
                      const Text(
                        'Versão 1.0.0',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para construir a opção do tipo de usuário
  Widget _buildUserTypeOption({
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
