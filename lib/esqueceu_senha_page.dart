import 'package:flutter/material.dart';
import 'package:mobile/app_session.dart';

class EsqueceuSenhaPage extends StatefulWidget {
  const EsqueceuSenhaPage({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<EsqueceuSenhaPage> createState() => _EsqueceuSenhaPageState();
}

class _EsqueceuSenhaPageState extends State<EsqueceuSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _ocultarNovaSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _email.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  void _redefinirSenha() {
    if (!_formKey.currentState!.validate()) return;
    final redefinida = AppSession.redefinirSenha(
      email: _email.text,
      novaSenha: _novaSenha.text,
    );
    if (!redefinida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não encontramos uma conta com este e-mail.'),
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  InputDecoration _decoracao({
    required String label,
    required IconData icone,
    Widget? sufixo,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icone),
    suffixIcon: sufixo,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_reset_outlined,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esqueceu a senha?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirme o e-mail cadastrado e escolha uma nova senha.',
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracao(
                    label: 'E-mail cadastrado',
                    icone: Icons.email_outlined,
                  ),
                  validator: (valor) => valor == null ||
                          !valor.trim().contains('@')
                      ? 'Informe um e-mail válido'
                      : null,
                ),
                const SizedBox(height: 16),
                _campoSenha(
                  controller: _novaSenha,
                  label: 'Nova senha',
                  ocultar: _ocultarNovaSenha,
                  onToggle: () => setState(
                    () => _ocultarNovaSenha = !_ocultarNovaSenha,
                  ),
                  validator: (valor) => valor == null || valor.length < 6
                      ? 'Use pelo menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                _campoSenha(
                  controller: _confirmacao,
                  label: 'Confirmar nova senha',
                  ocultar: _ocultarConfirmacao,
                  onToggle: () => setState(
                    () => _ocultarConfirmacao = !_ocultarConfirmacao,
                  ),
                  validator: (valor) => valor != _novaSenha.text
                      ? 'As senhas não coincidem'
                      : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _redefinirSenha,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text(
                      'Redefinir senha',
                      style: TextStyle(color: Colors.white),
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

  Widget _campoSenha({
    required TextEditingController controller,
    required String label,
    required bool ocultar,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: ocultar,
    textInputAction: label == 'Confirmar nova senha'
        ? TextInputAction.done
        : TextInputAction.next,
    onFieldSubmitted: (_) {
      if (label == 'Confirmar nova senha') _redefinirSenha();
    },
    decoration: _decoracao(
      label: label,
      icone: Icons.lock_outline,
      sufixo: IconButton(
        onPressed: onToggle,
        icon: Icon(
          ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: validator,
  );
}
