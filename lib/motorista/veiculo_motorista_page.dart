import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/responsive_content.dart';

class VeiculoMotoristaPage extends StatefulWidget {
  const VeiculoMotoristaPage({super.key});
  @override
  State<VeiculoMotoristaPage> createState() => _VeiculoMotoristaPageState();
}

class _VeiculoMotoristaPageState extends State<VeiculoMotoristaPage> {
  static const primary = Color(0xFF0C46FF);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _modelo, _placa, _renavam, _ano, _capacidade;

  @override
  void initState() {
    super.initState();
    final v = AppSession.veiculoMotorista.value;
    _modelo = TextEditingController(text: v.modelo);
    _placa = TextEditingController(text: v.placa);
    _renavam = TextEditingController(text: v.renavam);
    _ano = TextEditingController(text: v.ano);
    _capacidade = TextEditingController(text: v.capacidade);
  }

  @override
  void dispose() {
    _modelo.dispose();
    _placa.dispose();
    _renavam.dispose();
    _ano.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    AppSession.salvarVeiculo(
      VeiculoMotorista(
        modelo: _modelo.text.trim(),
        placa: _placa.text.trim().toUpperCase(),
        renavam: _renavam.text.trim(),
        ano: _ano.text.trim(),
        capacidade: _capacidade.text.trim(),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Dados do veículo salvos com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = AppSession.veiculoMotorista.value;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppGradientHeader(
              title: 'Meu veículo',
              subtitle: 'Dados do veículo cadastrado',
              icon: Icons.local_shipping_outlined,
            ),
            Expanded(
              child: ResponsiveContent(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B2A4A), primary],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 55,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        v.modelo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        v.placa,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _campo(_modelo, 'Modelo', Icons.local_shipping_outlined),
                _campo(
                  _placa,
                  'Placa',
                  Icons.pin_outlined,
                  formatter: FilteringTextInputFormatter.allow(
                    RegExp('[a-zA-Z0-9-]'),
                  ),
                  validator: (v) =>
                      RegExp(
                        r'^[A-Za-z]{3}-?[0-9][A-Za-z0-9][0-9]{2}$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Informe uma placa válida.',
                ),
                _campo(
                  _renavam,
                  'RENAVAM',
                  Icons.description_outlined,
                  number: true,
                  validator: (v) =>
                      RegExp(r'^\d{9,11}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Informe de 9 a 11 dígitos.',
                ),
                _campo(
                  _ano,
                  'Ano',
                  Icons.calendar_today_outlined,
                  number: true,
                  validator: (v) {
                    final a = int.tryParse(v ?? '');
                    return a != null &&
                            a >= 1900 &&
                            a <= DateTime.now().year + 1
                        ? null
                        : 'Informe um ano válido.';
                  },
                ),
                _campo(_capacidade, 'Capacidade', Icons.scale_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_outlined, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Veículo cadastrado e aprovado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
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
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label,
    IconData icon, {
    bool number = false,
    TextInputFormatter? formatter,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      validator:
          validator ??
          (v) => v == null || v.trim().isEmpty ? 'Informe $label.' : null,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (number) FilteringTextInputFormatter.digitsOnly,
        ?formatter,
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
