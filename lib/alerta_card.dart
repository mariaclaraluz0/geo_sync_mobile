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
    return Semantics(
      label: 'Alerta $titulo, $tempo, código $codigo',
      child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(width: 5, color: Theme.of(context).colorScheme.error),
        title: Text(titulo),
        subtitle: Text("$tempo • $codigo"),
      ),
      ),
    );
  }
}
