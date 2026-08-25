import 'package:flutter/material.dart';

class VeiculoMotoristaPage extends StatefulWidget {
  const VeiculoMotoristaPage({super.key});

  @override
  State<VeiculoMotoristaPage> createState() =>
      _VeiculoMotoristaPageState();
}

class _VeiculoMotoristaPageState
    extends State<VeiculoMotoristaPage> {
  static const Color primary = Color(0xFF0C46FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);
  static const Color border = Color(0xFFE8ECF3);

  final TextEditingController modeloController =
      TextEditingController(
    text: "Volvo VM 270",
  );

  final TextEditingController placaController =
      TextEditingController(
    text: "ABC-1D23",
  );

  final TextEditingController renavamController =
      TextEditingController(
    text: "12345678901",
  );

  final TextEditingController anoController =
      TextEditingController(
    text: "2024",
  );

  final TextEditingController capacidadeController =
      TextEditingController(
    text: "14 toneladas",
  );

  @override
  void dispose() {
    modeloController.dispose();
    placaController.dispose();
    renavamController.dispose();
    anoController.dispose();
    capacidadeController.dispose();
    super.dispose();
  }

  void _salvar() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            "Dados do veículo atualizados com sucesso!",
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          "Meu veículo",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: textDark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildVehicleHeader(),

            const SizedBox(height: 22),

            _campo(
              controller: modeloController,
              label: "Modelo",
              icon: Icons.local_shipping_outlined,
            ),

            _campo(
              controller: placaController,
              label: "Placa",
              icon: Icons.pin_outlined,
            ),

            _campo(
              controller: renavamController,
              label: "RENAVAM",
              icon: Icons.description_outlined,
              keyboardType: TextInputType.number,
            ),

            _campo(
              controller: anoController,
              label: "Ano",
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),

            _campo(
              controller: capacidadeController,
              label: "Capacidade",
              icon: Icons.scale_outlined,
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: border,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Veículo cadastrado e aprovado",
                      style: TextStyle(
                        color: textDark,
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
                icon: const Icon(
                  Icons.save_rounded,
                ),
                label: const Text(
                  "Salvar alterações",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2A4A),
            Color(0xFF0C46FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 55,
          ),
          SizedBox(height: 10),
          Text(
            "Volvo VM 270",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "ABC-1D23",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: textLight,
          ),
          prefixIcon: Icon(
            icon,
            color: primary,
            size: 21,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}