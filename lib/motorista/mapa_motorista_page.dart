import 'package:flutter/material.dart';

class MapaMotoristaPage extends StatefulWidget {
  const MapaMotoristaPage({super.key, this.remessaInicial = 'GS-9532'});
  final String remessaInicial;

  @override
  State<MapaMotoristaPage> createState() => _MapaMotoristaPageState();
}

class _MapaMotoristaPageState extends State<MapaMotoristaPage> {
  static const _azul = Color(0xFF0C46FF);
  static const _escuro = Color(0xFF172033);
  static const _remessas = [
    _Remessa(
      'GS-9532',
      'Av. Paulista, 1578',
      'São Paulo, SP → Rio de Janeiro, RJ',
      '186 km',
      '14:20',
      'Em rota',
      .72,
    ),
    _Remessa(
      'GS-6548',
      'Centro de Distribuição',
      'Uberlândia, MG → Pelotas, RS',
      '542 km',
      '17:15',
      'Aguardando coleta',
      .18,
    ),
    _Remessa(
      'GS-0811',
      'Rod. BR-101, km 42',
      'Recife, PE → Salvador, BA',
      '118 km',
      '--:--',
      'Atenção',
      .36,
    ),
  ];

  late String _selecionada;
  bool _navegando = true;

  @override
  void initState() {
    super.initState();
    _selecionada = _remessas.any((item) => item.codigo == widget.remessaInicial)
        ? widget.remessaInicial
        : _remessas.first.codigo;
  }

  _Remessa get _remessa =>
      _remessas.firstWhere((item) => item.codigo == _selecionada);

  @override
  Widget build(BuildContext context) {
    final remessa = _remessa;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: _escuro,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rotas e remessas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Acompanhe sua operação',
              style: TextStyle(color: Color(0xFF718096), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Centralizar localização',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mapa centralizado na sua localização.'),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _Mapa(remessa: remessa),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Minhas remessas',
                        style: TextStyle(
                          color: _escuro,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_remessas.length} ativas',
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: _remessas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (_, index) => _CartaoRemessa(
                        remessa: _remessas[index],
                        selecionada: _remessas[index].codigo == _selecionada,
                        onTap: () => setState(
                          () => _selecionada = _remessas[index].codigo,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _navegando = !_navegando),
              icon: Icon(
                _navegando ? Icons.pause_rounded : Icons.navigation_rounded,
              ),
              label: Text(
                _navegando ? 'Pausar navegação' : 'Iniciar navegação',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({required this.remessa});
  final _Remessa remessa;

  @override
  Widget build(BuildContext context) {
    final cor = remessa.status == 'Atenção'
        ? const Color(0xFFDC2626)
        : remessa.status == 'Aguardando coleta'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF16A34A);
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECE5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _MapaPainter())),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A172033),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFF0C46FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remessa.codigo,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remessa.destino,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      remessa.status,
                      style: TextStyle(
                        color: cor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 93,
            top: 132,
            child: _Marcador(
              icone: Icons.local_shipping_rounded,
              cor: Color(0xFF0C46FF),
            ),
          ),
          const Positioned(
            right: 45,
            bottom: 28,
            child: _Marcador(
              icone: Icons.location_on_rounded,
              cor: Color(0xFF16A34A),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${remessa.distancia} • chegada ${remessa.previsao}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.icone, required this.cor});
  final IconData icone;
  final Color cor;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: cor,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: cor.withValues(alpha: .35), blurRadius: 10)],
    ),
    child: Icon(icone, color: Colors.white, size: 21),
  );
}

class _CartaoRemessa extends StatelessWidget {
  const _CartaoRemessa({
    required this.remessa,
    required this.selecionada,
    required this.onTap,
  });
  final _Remessa remessa;
  final bool selecionada;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selecionada ? const Color(0xFFE9EEFF) : const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selecionada
                ? const Color(0xFF0C46FF)
                : const Color(0xFFE8ECF3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 40,
              decoration: BoxDecoration(
                color: remessa.status == 'Atenção'
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF0C46FF),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remessa.codigo,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    remessa.rota,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: remessa.progresso,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF0C46FF),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF718096)),
          ],
        ),
      ),
    ),
  );
}

class _Remessa {
  const _Remessa(
    this.codigo,
    this.destino,
    this.rota,
    this.distancia,
    this.previsao,
    this.status,
    this.progresso,
  );
  final String codigo, destino, rota, distancia, previsao, status;
  final double progresso;
}

class _MapaPainter extends CustomPainter {
  const _MapaPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rua = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rota = Paint()
      ..color = const Color(0xFF0C46FF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final caminho = Path()
      ..moveTo(-10, size.height * .85)
      ..cubicTo(
        size.width * .18,
        size.height * .70,
        size.width * .22,
        size.height * .44,
        size.width * .48,
        size.height * .48,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .53,
        size.width * .73,
        size.height * .18,
        size.width + 10,
        size.height * .24,
      );
    canvas.drawPath(caminho, rua);
    canvas.drawPath(caminho, rota);
    canvas.drawLine(
      Offset(size.width * .08, 0),
      Offset(size.width * .35, size.height),
      rua,
    );
    canvas.drawLine(
      Offset(size.width * .73, 0),
      Offset(size.width * .45, size.height),
      rua,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
