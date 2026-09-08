import 'package:flutter/material.dart';

class AvisosMotoristaPage extends StatefulWidget {
  const AvisosMotoristaPage({super.key});

  @override
  State<AvisosMotoristaPage> createState() => _AvisosMotoristaPageState();
}

class _AvisosMotoristaPageState extends State<AvisosMotoristaPage> {
  static const _primary = Color(0xFF0C46FF);
  static const _textDark = Color(0xFF172033);
  static const _textLight = Color(0xFF718096);

  final Set<int> _lidos = {};

  final _avisos = const [
    _Aviso(
      titulo: 'Próxima parada confirmada',
      descricao:
          'A coleta no Centro de Distribuição está confirmada para 09:30.',
      horario: 'Agora',
      icone: Icons.inventory_2_rounded,
      cor: _primary,
    ),
    _Aviso(
      titulo: 'Atenção ao trânsito',
      descricao:
          'Há lentidão na Rod. Presidente Dutra. Considere a rota sugerida.',
      horario: 'Há 12 min',
      icone: Icons.traffic_rounded,
      cor: Color(0xFFF59E0B),
    ),
    _Aviso(
      titulo: 'Documento validado',
      descricao: 'Os documentos da entrega GS-9532 foram verificados.',
      horario: 'Há 1 h',
      icone: Icons.verified_rounded,
      cor: Color(0xFF16A34A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Avisos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(
              () => _lidos.addAll(Iterable<int>.generate(_avisos.length)),
            ),
            child: const Text('Marcar como lidos'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3 avisos para você',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Acompanhe atualizações da sua rota.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Hoje',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_avisos.length, _buildAviso),
        ],
      ),
    );
  }

  Widget _buildAviso(int index) {
    final aviso = _avisos[index];
    final lido = _lidos.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _lidos.add(index)),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: aviso.cor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(aviso.icone, color: aviso.cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              aviso.titulo,
                              style: TextStyle(
                                color: _textDark,
                                fontWeight: lido
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            aviso.horario,
                            style: const TextStyle(
                              color: _textLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        aviso.descricao,
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!lido) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Aviso {
  const _Aviso({
    required this.titulo,
    required this.descricao,
    required this.horario,
    required this.icone,
    required this.cor,
  });
  final String titulo;
  final String descricao;
  final String horario;
  final IconData icone;
  final Color cor;
}
