import 'package:flutter/material.dart';

class RemessaCard extends StatelessWidget {
  final String codigo;
  final String rota;
  final String tipo;
  final String status;

  const RemessaCard({
    super.key,
    required this.codigo,
    required this.rota,
    required this.tipo,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.inventory),
        title: Text(codigo),
        subtitle: Text("$rota • $tipo"),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == "Atrasado"
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }
}