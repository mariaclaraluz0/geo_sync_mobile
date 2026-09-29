import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cartão que agrupa campos de formulário sob um título com ícone.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Decoração padrão dos campos: preenchida, cantos arredondados e borda
/// destacada no foco e no erro. Usa as cores do tema (claro e escuro).
InputDecoration modernInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? hint,
  String? helper,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder borda(Color cor, [double largura = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    errorMaxLines: 2,
    prefixIcon: Icon(icon, size: 22),
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: borda(scheme.outlineVariant),
    enabledBorder: borda(scheme.outlineVariant),
    focusedBorder: borda(scheme.primary, 1.8),
    errorBorder: borda(scheme.error),
    focusedErrorBorder: borda(scheme.error, 1.8),
  );
}

/// Barra fixa no rodapé com as ações principais do formulário. Sobe junto
/// com o teclado e respeita a área segura do aparelho.
class FormActionBar extends StatelessWidget {
  const FormActionBar({super.key, required this.children, this.maxWidth = 960});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Máscara de telefone brasileiro: (11) 91234-5678 ou (11) 1234-5678.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 11) digitos = digitos.substring(0, 11);
    final texto = formatarTelefone(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String formatarTelefone(String valor) {
  final d = valor.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';
  final ddd = d.substring(0, 2);
  final resto = d.substring(2);
  final corte = resto.length > 8 ? 5 : 4;
  if (resto.length <= corte) return '($ddd) $resto';
  return '($ddd) ${resto.substring(0, corte)}-${resto.substring(corte)}';
}
