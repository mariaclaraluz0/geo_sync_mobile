import 'package:flutter/material.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  static const _blue = Color(0xFF2563EB);
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  String _tipoUsuario = 'Cliente';
  bool _ocultarSenha = true, _ocultarConfirmacao = true, _aceitouTermos = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_form.currentState!.validate()) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para criar sua conta.')),
      );
      return;
    }
    setState(() => _carregando = true);
    try {
      final resposta = await ApiService.instance.register(
        name: _nome.text,
        email: _email.text,
        phone: _telefone.text,
        password: _senha.text,
        userType: _tipoUsuario,
      );
      final token = resposta['token'] ?? resposta['access_token'];
      if (token is String && token.isNotEmpty) {
        await AppSession.iniciarSessao(
          token: token,
          tipoUsuario: _tipoUsuario,
          email: _email.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastro realizado com sucesso! Faça login para continuar.',
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon, [
    Widget? suffix,
  ]) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _blue, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Container(
            height: 250,
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
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Crie sua conta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comece a gerenciar suas entregas com a gente.',
                    style: TextStyle(color: Colors.white.withValues(alpha: .8)),
                  ),
                  const SizedBox(height: 28),
                  _formulario(),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Já possui uma conta? ',
                          style: TextStyle(color: Color(0xFF64748B)),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: TextStyle(
                                color: _blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como você vai usar o app?',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _seletorTipo(),
          const SizedBox(height: 24),
          _campo(
            _nome,
            'Nome completo',
            'Como podemos te chamar?',
            Icons.person_outline_rounded,
            TextInputType.name,
            (v) => v == null || v.trim().length < 3
                ? 'Informe seu nome completo'
                : null,
          ),
          _campo(
            _email,
            'E-mail',
            'seu@email.com',
            Icons.email_outlined,
            TextInputType.emailAddress,
            (v) => v == null || !v.contains('@')
                ? 'Informe um e-mail válido'
                : null,
          ),
          _campo(
            _telefone,
            'Telefone',
            '(00) 00000-0000',
            Icons.phone_outlined,
            TextInputType.phone,
            (v) => v == null || v.trim().length < 10
                ? 'Informe um telefone válido'
                : null,
          ),
          _campoSenha(),
          if (_senha.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _forcaSenha(),
          ],
          const SizedBox(height: 16),
          _campoConfirmacao(),
          const SizedBox(height: 12),
          _termos(),
          const SizedBox(height: 12),
          _botaoCriarConta(),
        ],
      ),
    ),
  );

  Widget _campo(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    TextInputType type,
    String? Function(String?) validator,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      textCapitalization: label == 'Nome completo'
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: _decoration(label, hint, icon),
      validator: validator,
    ),
  );

  Widget _campoSenha() => TextFormField(
    controller: _senha,
    obscureText: _ocultarSenha,
    textInputAction: TextInputAction.next,
    onChanged: (_) => setState(() {}),
    decoration: _decoration(
      'Senha',
      'Mínimo de 6 caracteres',
      Icons.lock_outline_rounded,
      IconButton(
        onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
        icon: Icon(
          _ocultarSenha
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: (v) => v == null || v.length < 6
        ? 'A senha deve ter pelo menos 6 caracteres'
        : null,
  );

  Widget _campoConfirmacao() => TextFormField(
    controller: _confirmacao,
    obscureText: _ocultarConfirmacao,
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => _criarConta(),
    decoration: _decoration(
      'Confirmar senha',
      'Repita sua senha',
      Icons.lock_reset_outlined,
      IconButton(
        onPressed: () =>
            setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
        icon: Icon(
          _ocultarConfirmacao
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: (v) => v != _senha.text ? 'As senhas não coincidem' : null,
  );

  Widget _termos() => CheckboxListTile(
    value: _aceitouTermos,
    onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: _blue,
    title: const Text(
      'Li e concordo com os Termos de Uso e a Política de Privacidade.',
      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
    ),
  );

  Widget _botaoCriarConta() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: _carregando ? null : _criarConta,
      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      label: Text(
        _carregando ? 'Criando conta...' : 'Criar minha conta',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Widget _seletorTipo() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        _opcaoTipo(
          'Cliente',
          Icons.person_outline_rounded,
          Icons.person_rounded,
        ),
        _opcaoTipo(
          'Motorista',
          Icons.local_shipping_outlined,
          Icons.local_shipping_rounded,
        ),
      ],
    ),
  );
  Widget _opcaoTipo(String label, IconData icon, IconData selecionado) {
    final ativo = _tipoUsuario == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tipoUsuario = label),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: ativo ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ativo ? selecionado : icon,
                size: 18,
                color: ativo ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: ativo ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _forcaSenha() {
    final forte =
        _senha.text.length >= 10 &&
        RegExp(r'[A-Z]').hasMatch(_senha.text) &&
        RegExp(r'[0-9]').hasMatch(_senha.text);
    final media = _senha.text.length >= 6;
    final cor = forte
        ? const Color(0xFF16A34A)
        : media
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: forte
                ? 1
                : media
                ? .65
                : .3,
            minHeight: 5,
            color: cor,
            backgroundColor: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          forte
              ? 'Senha forte'
              : media
              ? 'Senha média'
              : 'Senha fraca',
          style: TextStyle(
            fontSize: 12,
            color: cor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
