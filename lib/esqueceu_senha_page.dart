import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/responsive_content.dart';

/// Solicita ao servidor o envio do link de redefinição de senha.
///
/// A resposta é a mesma para e-mails cadastrados ou não, para não revelar
/// quais contas existem. Fecha com `true` quando o pedido foi aceito.
class EsqueceuSenhaPage extends StatefulWidget {
  const EsqueceuSenhaPage({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<EsqueceuSenhaPage> createState() => _EsqueceuSenhaPageState();
}

class _EsqueceuSenhaPageState extends State<EsqueceuSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviarLink() async {
    if (_enviando || !_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await ApiService.instance.esqueciSenha(_email.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      // 404/422 indicam e-mail não cadastrado; respondemos como sucesso
      // para não revelar quais contas existem.
      if (error.statusCode == 404 || error.statusCode == 422) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.lock_reset_outlined,
                      size: 48,
                      color: cores.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Esqueceu a senha?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informe o e-mail cadastrado. Enviaremos um link para você '
                    'criar uma nova senha.',
                    style: TextStyle(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    enabled: !_enviando,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _enviarLink(),
                    decoration: InputDecoration(
                      labelText: 'E-mail cadastrado',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: cores.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (valor) {
                      final email = valor?.trim() ?? '';
                      return RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)
                          ? null
                          : 'Informe um e-mail válido';
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _enviando ? null : _enviarLink,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _enviando
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Enviar link de redefinição'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
