import 'package:flutter/material.dart';
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
        final resposta = ApiService.instance.authData(
          await ApiService.instance.login(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
        final token = resposta['token'] ?? resposta['access_token'];
        if (token is! String || token.isEmpty) {
          throw const ApiException('A API não retornou o token de acesso.');
        }
        final usuario = resposta['user'] is Map
            ? Map<String, dynamic>.from(resposta['user'] as Map)
            : <String, dynamic>{};
        final tipoApi =
            '${usuario['tipo_usuario'] ?? usuario['tipo'] ?? _tipoUsuario}';
        final tipo = tipoApi.toLowerCase() == 'motorista'
            ? 'Motorista'
            : 'Cliente';
        await AppSession.iniciarSessao(
          token: token,
          tipoUsuario: tipo,
          email: '${usuario['email'] ?? _emailController.text}',
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
    final controller = TextEditingController(text: ApiService.baseUrl);
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
            hintText: 'http://192.168.1.10:8000/api',
            prefixIcon: Icon(Icons.dns_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || !mounted) return;
    try {
      await ApiService.saveBaseUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API configurada: ${ApiService.baseUrl}')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2563EB); // Azul moderno

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // LOGO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          Icons.electric_car,
                          size: 50,
                          color: primaryColor,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TÍTULOS PRINCIPAIS
                  const Text(
                    'Bem-vindo de volta! 👋',
                    style: TextStyle(
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
                      color: Colors.white,
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
                          const Text(
                            'Entrar como',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _buildUserTypeOption(
                                  label: 'Cliente',
                                  icon: Icons.person_outline,
                                  selectedIcon: Icons.person,
                                  isSelected: _tipoUsuario == 'Cliente',
                                  onTap: () =>
                                      setState(() => _tipoUsuario = 'Cliente'),
                                  activeColor: primaryColor,
                                ),
                                _buildUserTypeOption(
                                  label: 'Motorista',
                                  icon: Icons.local_shipping_outlined,
                                  selectedIcon: Icons.local_shipping,
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
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
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
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
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
                                          emailInicial: _emailController.text,
                                        ),
                                      ),
                                    );
                                if (senhaRedefinida == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Senha redefinida com sucesso. Faça login para continuar.',
                                      ),
                                      backgroundColor: Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                    ? Icons.login_rounded
                                    : Icons.local_shipping_rounded,
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
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('Configurar servidor da API'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // REGISTRO DE CONTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não tem uma conta? ',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () {
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
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
