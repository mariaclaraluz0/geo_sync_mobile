import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/form_widgets.dart';

/// Dados do veículo do motorista. O cartão do topo mostra uma prévia que
/// acompanha a edição; as alterações ficam salvas no aparelho.
class VeiculoMotoristaPage extends StatefulWidget {
  const VeiculoMotoristaPage({super.key});

  @override
  State<VeiculoMotoristaPage> createState() => _VeiculoMotoristaPageState();
}

class _VeiculoMotoristaPageState extends State<VeiculoMotoristaPage> {
  static const _larguraDuasColunas = 760.0;
  static final _placaValida = RegExp(r'^[A-Z]{3}-?[0-9][A-Z0-9][0-9]{2}$');

  final _formKey = GlobalKey<FormState>();
  late VeiculoMotorista _salvo;
  late final TextEditingController _modelo;
  late final TextEditingController _placa;
  late final TextEditingController _renavam;
  late final TextEditingController _ano;
  late final TextEditingController _capacidade;
  bool _salvando = false;

  List<TextEditingController> get _campos => [
    _modelo,
    _placa,
    _renavam,
    _ano,
    _capacidade,
  ];

  @override
  void initState() {
    super.initState();
    _salvo = AppSession.veiculoMotorista.value;
    _modelo = TextEditingController(text: _salvo.modelo);
    _placa = TextEditingController(text: _salvo.placa.toUpperCase());
    _renavam = TextEditingController(text: _salvo.renavam);
    _ano = TextEditingController(text: _salvo.ano);
    _capacidade = TextEditingController(text: _salvo.capacidade);
    for (final c in _campos) {
      c.addListener(_atualizar);
    }
  }

  @override
  void dispose() {
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  void _atualizar() => setState(() {});

  VeiculoMotorista get _editado => VeiculoMotorista(
    modelo: _modelo.text.trim(),
    placa: _placa.text.trim().toUpperCase(),
    renavam: _renavam.text.trim(),
    ano: _ano.text.trim(),
    capacidade: _capacidade.text.trim(),
  );

  bool get _alterado {
    final e = _editado;
    return e.modelo != _salvo.modelo ||
        e.placa != _salvo.placa.toUpperCase() ||
        e.renavam != _salvo.renavam ||
        e.ano != _salvo.ano ||
        e.capacidade != _salvo.capacidade;
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _mensagem('Revise os campos destacados.', erro: true);
      return;
    }
    setState(() => _salvando = true);
    final veiculo = _editado;
    await AppSession.salvarVeiculo(veiculo);
    if (!mounted) return;
    setState(() {
      _salvo = veiculo;
      _salvando = false;
    });
    _mensagem('Dados do veículo salvos.');
  }

  Future<void> _confirmarSaida() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_note_rounded, size: 32),
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Os dados do veículo foram alterados e ainda não foram salvos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) Navigator.pop(context);
  }

  Future<void> _copiarRenavam() async {
    await Clipboard.setData(ClipboardData(text: _renavam.text.trim()));
    _mensagem('RENAVAM copiado.');
  }

  void _mensagem(String texto, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
          content: Row(
            children: [
              Icon(
                erro ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(texto, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _confirmarSaida();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= _larguraDuasColunas;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: AppGradientHeader(
                      title: 'Meu veículo',
                      subtitle: _alterado
                          ? 'Você tem alterações não salvas'
                          : 'Dados do veículo cadastrado',
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: largo
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 340,
                                        child: _painelResumo(),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(child: _formulario()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _painelResumo(),
                                      const SizedBox(height: 16),
                                      _formulario(),
                                    ],
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
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _alterado && !_salvando ? _salvar : null,
                  icon: _salvando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_alterado ? 'Salvar alterações' : 'Tudo salvo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _painelResumo() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CartaoVeiculo(veiculo: _editado),
      const SizedBox(height: 12),
      _StatusAprovacao(),
    ],
  );

  Widget _formulario() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormSectionCard(
        title: 'Identificação',
        subtitle: 'Dados do documento do veículo (CRLV)',
        icon: Icons.badge_rounded,
        children: [
          _campo(
            controller: _modelo,
            label: 'Modelo',
            icon: Icons.local_shipping_rounded,
            hint: 'Ex.: Volvo VM 270',
            capitalization: TextCapitalization.words,
            validator: (v) =>
                (v?.trim().length ?? 0) < 2 ? 'Informe o modelo' : null,
          ),
          _campo(
            controller: _placa,
            label: 'Placa',
            icon: Icons.pin_rounded,
            hint: 'ABC1D23 ou ABC-1234',
            helper: 'Padrão Mercosul ou antigo',
            formatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
              LengthLimitingTextInputFormatter(8),
              _MaiusculasFormatter(),
            ],
            validator: (v) => _placaValida.hasMatch(v?.trim() ?? '')
                ? null
                : 'Placa inválida',
          ),
          _campo(
            controller: _renavam,
            label: 'RENAVAM',
            icon: Icons.description_rounded,
            hint: '11 dígitos',
            teclado: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            acao: _renavam.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Copiar RENAVAM',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: _copiarRenavam,
                  ),
            validator: (v) => RegExp(r'^\d{9,11}$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Informe de 9 a 11 dígitos',
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormSectionCard(
        title: 'Especificações',
        subtitle: 'Usadas para oferecer entregas compatíveis',
        icon: Icons.tune_rounded,
        children: [
          _campo(
            controller: _ano,
            label: 'Ano de fabricação',
            icon: Icons.calendar_month_rounded,
            hint: 'Ex.: 2024',
            teclado: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) {
              final ano = int.tryParse(v ?? '');
              return ano != null &&
                      ano >= 1950 &&
                      ano <= DateTime.now().year + 1
                  ? null
                  : 'Informe um ano válido';
            },
          ),
          _campo(
            controller: _capacidade,
            label: 'Capacidade de carga',
            icon: Icons.scale_rounded,
            hint: 'Ex.: 14 toneladas',
            ultimo: true,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Informe a capacidade' : null,
          ),
        ],
      ),
    ],
  );

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    String? helper,
    TextInputType teclado = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    Widget? acao,
    bool ultimo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: teclado,
        textCapitalization: capitalization,
        inputFormatters: formatters,
        textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: ultimo && _alterado ? (_) => _salvar() : null,
        validator: validator,
        decoration: modernInputDecoration(
          context,
          label: label,
          icon: icon,
          hint: hint,
          helper: helper,
          suffix: acao,
        ),
      ),
    );
  }
}

/// Converte o texto digitado para maiúsculas (placa).
class _MaiusculasFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Cartão de destaque com modelo, placa e especificações do veículo.
class _CartaoVeiculo extends StatelessWidget {
  const _CartaoVeiculo({required this.veiculo});

  final VeiculoMotorista veiculo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2A4A), Color(0xFF0C46FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C46FF).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VEÍCULO',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      veiculo.modelo.isEmpty ? 'Modelo' : veiculo.modelo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(child: _PlacaMercosul(placa: veiculo.placa)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Especificacao(
                  icon: Icons.calendar_month_rounded,
                  rotulo: 'Ano',
                  valor: veiculo.ano,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Especificacao(
                  icon: Icons.scale_rounded,
                  rotulo: 'Capacidade',
                  valor: veiculo.capacidade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Placa no visual do padrão Mercosul (faixa azul com "BRASIL").
class _PlacaMercosul extends StatelessWidget {
  const _PlacaMercosul({required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context) {
    final texto = placa.trim().isEmpty ? '——————' : placa.trim();
    return Semantics(
      label: 'Placa $texto',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1F2937), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: const Text(
                'BRASIL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  texto,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Especificacao extends StatelessWidget {
  const _Especificacao({
    required this.icon,
    required this.rotulo,
    required this.valor,
  });

  final IconData icon;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  valor.isEmpty ? '—' : valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _StatusAprovacao extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const verde = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: verde.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: verde.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: verde.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: verde, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veículo aprovado',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Liberado para receber entregas',
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
    );
  }
}
