import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

Future<void> configurarServidorApi(BuildContext context) async {
  var urlAtual = '';
  try {
    urlAtual = ApiService.baseUrl;
  } on ApiException {
    // A URL pode ainda não estar configurada.
  }

  final controller = TextEditingController(text: urlAtual);
  final url = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Servidor da API e do IoT'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informe o endereço do servidor que recebe os dados do módulo IoT.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'URL da API',
              hintText: 'https://api.suaempresa.com/api',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No celular, use o endereço acessível pela rede do aparelho. '
            'Para desenvolvimento local, use o IP do computador, não localhost.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 300), controller.dispose);
  if (url == null || !context.mounted) return;

  try {
    await ApiService.saveBaseUrl(url);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servidor salvo: ${ApiService.baseUrl}')),
    );
  } on ApiException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}
