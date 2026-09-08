import 'package:flutter/material.dart';

class DocumentosMotoristaPage extends StatefulWidget {
  const DocumentosMotoristaPage({super.key});

  @override
  State<DocumentosMotoristaPage> createState() =>
      _DocumentosMotoristaPageState();
}

class _DocumentosMotoristaPageState extends State<DocumentosMotoristaPage> {
  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textLight => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get border => Theme.of(context).colorScheme.outlineVariant;

  bool cnhValida = true;
  bool documentoVeiculo = true;

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _atualizarDocumento(String documento) {
    _mostrarMensagem("Solicitação de atualização de $documento enviada.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Documentos",
          style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 22),

            Text(
              "Documentos pessoais",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),

            const SizedBox(height: 12),

            _documentoCard(
              icon: Icons.badge_outlined,
              titulo: "CNH",
              subtitulo: "Carlos Silva",
              detalhe: "Categoria D • Válida até 18/06/2028",
              valido: cnhValida,
              onTap: () {
                _atualizarDocumento("CNH");
              },
            ),

            const SizedBox(height: 10),

            _documentoCard(
              icon: Icons.description_outlined,
              titulo: "Documento do veículo",
              subtitulo: "CRLV",
              detalhe: "Documento válido • 2026",
              valido: documentoVeiculo,
              onTap: () {
                _atualizarDocumento("documento do veículo");
              },
            ),

            const SizedBox(height: 24),

            Text(
              "Dados da habilitação",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),

            const SizedBox(height: 12),

            _infoCard(
              icon: Icons.credit_card,
              titulo: "Número da CNH",
              valor: "01234567890",
            ),

            _infoCard(
              icon: Icons.category_outlined,
              titulo: "Categoria",
              valor: "D",
            ),

            _infoCard(
              icon: Icons.calendar_month_outlined,
              titulo: "Validade",
              valor: "18/06/2028",
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _mostrarMensagem("Documentos enviados para análise.");
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text("Atualizar documentos"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryDark, primary]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.verified_rounded, color: Colors.white, size: 28),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Documentação regularizada",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Todos os documentos estão dentro da validade.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentoCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String detalhe,
    required bool valido,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: TextStyle(color: textLight, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalhe,
                    style: TextStyle(color: textLight, fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  valido ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: valido ? Colors.green : Colors.orange,
                  size: 21,
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: textLight, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
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
