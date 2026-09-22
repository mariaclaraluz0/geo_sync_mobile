import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class AlterarSenhaPage extends StatefulWidget {
  const AlterarSenhaPage({super.key});

  @override
  State<AlterarSenhaPage> createState() => _AlterarSenhaPageState();
}

class _AlterarSenhaPageState extends State<AlterarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _obscureAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirma = true;
  bool _enviando = false;

  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await ApiService.instance.updateProfile({
        'current_password': _senhaAtual.text,
        'password': _novaSenha.text,
        'password_confirmation': _confirmacao.text,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Text('Alterar Senha', style: TextStyle(fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildPasswordField(
                controller: _senhaAtual,
                label: 'Senha Atual',
                obscure: _obscureAtual,
                onToggle: () => setState(() => _obscureAtual = !_obscureAtual),
                validator: (valor) => valor == null || valor.isEmpty
                    ? 'Informe a senha atual'
                    : null,
              ),
              _buildPasswordField(
                controller: _novaSenha,
                label: 'Nova Senha',
                obscure: _obscureNova,
                onToggle: () => setState(() => _obscureNova = !_obscureNova),
                validator: (valor) => valor == null || valor.length < 6
                    ? 'Use pelo menos 6 caracteres'
                    : null,
              ),
              _buildPasswordField(
                controller: _confirmacao,
                label: 'Confirmar Nova Senha',
                obscure: _obscureConfirma,
                onToggle: () =>
                    setState(() => _obscureConfirma = !_obscureConfirma),
                validator: (valor) =>
                    valor != _novaSenha.text ? 'As senhas não coincidem' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _atualizarSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Atualizar Senha',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0B2A4A)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onFieldSubmitted: (_) => _atualizarSenha(),
        validator: validator,
      ),
    );
  }
}
