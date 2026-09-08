import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/app_session.dart';

class DocumentosMotoristaPage extends StatefulWidget {
  const DocumentosMotoristaPage({super.key});
  @override
  State<DocumentosMotoristaPage> createState() =>
      _DocumentosMotoristaPageState();
}

class _DocumentosMotoristaPageState extends State<DocumentosMotoristaPage> {
  static const primary = Color(0xFF0C46FF);
  Future<void> _enviar(bool cnh) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (imagem == null || !mounted) return;
      final docs = AppSession.documentosMotorista.value;
      AppSession.salvarDocumentos(
        cnh
            ? docs.copyWith(cnhEnviada: true)
            : docs.copyWith(crlvEnviado: true),
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cnh ? 'CNH' : 'CRLV'} enviado para análise.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a galeria.')),
      );
    }
  }

  void _escolherDocumento() => showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Atualizar CNH'),
            onTap: () {
              Navigator.pop(context);
              _enviar(true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Atualizar CRLV'),
            onTap: () {
              Navigator.pop(context);
              _enviar(false);
            },
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final docs = AppSession.documentosMotorista.value;
    final pendente = docs.possuiPendencia;
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B2A4A), primary],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.verified_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendente
                            ? 'Documentos em análise'
                            : 'Documentação regularizada',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendente
                            ? 'Você receberá um aviso após a validação.'
                            : 'Todos os documentos estão dentro da validade.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Documentos pessoais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _documento(
            Icons.badge_outlined,
            'CNH',
            'Carlos Silva',
            docs.cnhEnviada
                ? 'Enviada para análise'
                : 'Categoria D • Válida até 18/06/2028',
            docs.cnhEnviada,
            () => _enviar(true),
          ),
          _documento(
            Icons.description_outlined,
            'Documento do veículo',
            'CRLV',
            docs.crlvEnviado
                ? 'Enviado para análise'
                : 'Documento válido • 2026',
            docs.crlvEnviado,
            () => _enviar(false),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dados da habilitação',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _info(Icons.credit_card, 'Número da CNH', '01234567890'),
          _info(Icons.category_outlined, 'Categoria', 'D'),
          _info(Icons.calendar_month_outlined, 'Validade', '18/06/2028'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _escolherDocumento,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Atualizar documentos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documento(
    IconData icon,
    String titulo,
    String subtitulo,
    String detalhe,
    bool enviado,
    VoidCallback tap,
  ) => Card(
    child: ListTile(
      onTap: tap,
      leading: Icon(icon, color: primary),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('$subtitulo\n$detalhe'),
      isThreeLine: true,
      trailing: Icon(
        enviado ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
        color: enviado ? Colors.orange : Colors.green,
      ),
    ),
  );
  Widget _info(IconData icon, String titulo, String valor) => Card(
    child: ListTile(
      leading: Icon(icon, color: primary),
      title: Text(titulo),
      subtitle: Text(
        valor,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
