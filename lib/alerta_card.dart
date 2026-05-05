import 'package:flutter/material.dart';

class AlertaCard extends StatelessWidget {
  final String titulo;
  final String tempo;
  final String codigo;

  const AlertaCard({
    super.key,
    required this.titulo,
    required this.tempo,
    required this.codigo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 5,
          color: Colors.red,
        ),
        title: Text(titulo),
        subtitle: Text("$tempo • $codigo"),
      ),
    );
  }
}