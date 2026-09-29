import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/form_widgets.dart';

/// Troca de senha. Fecha com `true` quando o servidor aceita a nova senha.
class AlterarSenhaPage extends StatefulWidget {
  const AlterarSenhaPage({super.key});

  @override
  State<AlterarSenhaPage> createState() => _AlterarSenhaPageState();
}

/// Requisito exibido na lista de verificação da nova senha.
class _Requisito {
  const _Requisito(this.texto, this.atendido, {this.obrigatorio = false});

  final String texto;
  final bool Function(String senha) atendido;
  final bool obrigatorio;
}

class _AlterarSenhaPageState extends State<AlterarSenhaPage> {
  static const _tamanhoMinimo = 8;
  static const _larguraDuasColunas = 760.0;

  static final _requisitos = [
    _Requisito(
      'Pelo menos $_tamanhoMinimo caracteres',
      (s) => s.length >= _tamanhoMinimo,
      obrigatorio: true,
    ),
    _Requisito(
      'Letras maiúsculas e minúsculas',
      (s) => RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s),
    ),
    _Requisito('Pelo menos um número', (s) => RegExp(r'\d').hasMatch(s)),
    _Requisito(
      'Um símbolo (ex.: ! @ # \$ %)',
      (s) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(s),
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _focoNova = FocusNode();
  final _focoConfirmacao = FocusNode();
  bool _ocultarAtual = true;
  bool _ocultarNova = true;
  bool _ocultarConfirmacao = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_senhaAtual, _novaSenha, _confirmacao]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    _focoNova.dispose();
    _focoConfirmacao.dispose();
    super.dispose();
  }

  /// 0 a 4, pela quantidade de requisitos atendidos.
  int get _forca {
    final senha = _novaSenha.text;
    if (senha.isEmpty) return 0;
    return _requisitos.where((r) => r.atendido(senha)).length;
  }

  bool get _senhasConferem =>
      _confirmacao.text.isNotEmpty && _confirmacao.text == _novaSenha.text;

  bool get _podeEnviar =>
      !_enviando &&
      _senhaAtual.text.isNotEmpty &&
      _novaSenha.text.length >= _tamanhoMinimo &&
      _senhasConferem;

  Future<void> _atualizarSenha() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await ApiService.instance.updateProfile({
        'current_password': _senhaAtual.text,
        'password': _novaSenha.text,
        'password_confirmation': _confirmacao.text,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largo = constraints.maxWidth >= _larguraDuasColunas;
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: AppGradientHeader(
                    title: 'Alterar senha',
                    subtitle: 'Mantenha sua conta protegida',
                    icon: Icons.shield_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: largo ? 960 : 560),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: largo
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: _formulario()),
                                      const SizedBox(width: 20),
                                      Expanded(flex: 2, child: _dicas()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _formulario(),
                                      const SizedBox(height: 16),
                                      _dicas(),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FormActionBar(
          maxWidth: 560,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _podeEnviar ? _atualizarSenha : null,
                icon: _enviando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.lock_reset_rounded),
                label: Text(_enviando ? 'Atualizando...' : 'Atualizar senha'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormSectionCard(
        title: 'Senha atual',
        subtitle: 'Confirme que é você',
        icon: Icons.key_rounded,
        children: [
          _campoSenha(
            controller: _senhaAtual,
            label: 'Senha atual',
            icon: Icons.lock_outline_rounded,
            ocultar: _ocultarAtual,
            alternar: () => setState(() => _ocultarAtual = !_ocultarAtual),
            autofill: AutofillHints.password,
            aoConcluir: _focoNova.requestFocus,
            validator: (v) =>
                (v ?? '').isEmpty ? 'Informe sua senha atual' : null,
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormSectionCard(
        title: 'Nova senha',
        subtitle: 'Crie uma senha forte e única',
        icon: Icons.password_rounded,
        children: [
          _campoSenha(
            controller: _novaSenha,
            label: 'Nova senha',
            icon: Icons.lock_reset_rounded,
            ocultar: _ocultarNova,
            alternar: () => setState(() => _ocultarNova = !_ocultarNova),
            foco: _focoNova,
            autofill: AutofillHints.newPassword,
            aoConcluir: _focoConfirmacao.requestFocus,
            validator: (v) {
              final senha = v ?? '';
              if (senha.length < _tamanhoMinimo) {
                return 'Use pelo menos $_tamanhoMinimo caracteres';
              }
              if (senha == _senhaAtual.text) {
                return 'A nova senha deve ser diferente da atual';
              }
              return null;
            },
          ),
          _medidorDeForca(),
          const SizedBox(height: 12),
          ..._requisitos.map(_itemRequisito),
          const SizedBox(height: 16),
          _campoSenha(
            controller: _confirmacao,
            label: 'Confirmar nova senha',
            icon: Icons.lock_person_outlined,
            ocultar: _ocultarConfirmacao,
            alternar: () =>
                setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
            foco: _focoConfirmacao,
            autofill: AutofillHints.newPassword,
            ultimo: true,
            aoConcluir: () {
              if (_podeEnviar) _atualizarSenha();
            },
            indicador: _confirmacao.text.isEmpty
                ? null
                : Icon(
                    _senhasConferem
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: _senhasConferem
                        ? const Color(0xFF16A34A)
                        : Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
            // Quando não coincidem, o erro da validação ocupa este espaço.
            helper: _senhasConferem ? 'As senhas coincidem' : null,
            validator: (v) =>
                v != _novaSenha.text ? 'As senhas não coincidem' : null,
          ),
        ],
      ),
    ],
  );

  Widget _campoSenha({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool ocultar,
    required VoidCallback alternar,
    required String? Function(String?) validator,
    required String autofill,
    required VoidCallback aoConcluir,
    FocusNode? foco,
    bool ultimo = false,
    Widget? indicador,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        focusNode: foco,
        obscureText: ocultar,
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: [autofill],
        textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) => aoConcluir(),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: modernInputDecoration(
          context,
          label: label,
          icon: icon,
          helper: helper,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?indicador,
              IconButton(
                tooltip: ocultar ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: alternar,
                icon: Icon(
                  ocultar
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _medidorDeForca() {
    final scheme = Theme.of(context).colorScheme;
    final forca = _forca;
    final (rotulo, cor) = switch (forca) {
      0 => ('Digite a nova senha', scheme.onSurfaceVariant),
      1 => ('Fraca', const Color(0xFFDC2626)),
      2 => ('Razoável', const Color(0xFFF59E0B)),
      3 => ('Boa', const Color(0xFF2563EB)),
      _ => ('Forte', const Color(0xFF16A34A)),
    };
    return Semantics(
      label: 'Força da senha: $rotulo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < forca ? cor : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: 'Força: ',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              children: [
                TextSpan(
                  text: rotulo,
                  style: TextStyle(color: cor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRequisito(_Requisito requisito) {
    final scheme = Theme.of(context).colorScheme;
    final ok = requisito.atendido(_novaSenha.text);
    final cor = ok ? const Color(0xFF16A34A) : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              key: ValueKey(ok),
              size: 18,
              color: cor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              requisito.obrigatorio
                  ? requisito.texto
                  : '${requisito.texto} (recomendado)',
              style: TextStyle(
                color: ok ? scheme.onSurface : scheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dicas() {
    final scheme = Theme.of(context).colorScheme;
    Widget dica(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dicas de segurança',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          dica(
            Icons.fingerprint_rounded,
            'Não reutilize senhas de outros apps ou serviços.',
          ),
          dica(
            Icons.no_encryption_gmailerrorred_outlined,
            'Evite datas de nascimento, nomes ou sequências como 123456.',
          ),
          dica(
            Icons.password_rounded,
            'Frases longas são fáceis de lembrar e difíceis de adivinhar.',
          ),
        ],
      ),
    );
  }
}
