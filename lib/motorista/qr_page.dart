import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/motorista/entrega_page.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/responsive_content.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RemessaQrCodec {
  static const _prefix = 'geo-sync-remessa';

  static String encode(Object remessaId) => '$_prefix:${remessaId.toString().trim()}';

  static String? decode(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('$_prefix:')) {
      final id = value.substring(_prefix.length + 1).trim();
      return id.isEmpty ? null : id;
    }

    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.scheme == 'geo-sync' &&
        uri.host == 'remessa' &&
        uri.pathSegments.length == 1) {
      return uri.pathSegments.first;
    }

    return null;
  }
}

class QrRemessaPage extends StatefulWidget {
  const QrRemessaPage({super.key});

  @override
  State<QrRemessaPage> createState() => _QrRemessaPageState();
}

class _QrRemessaPageState extends State<QrRemessaPage> {
  bool _loading = true;
  String? _error;
  List<Remessa> _remessas = [];

  @override
  void initState() {
    super.initState();
    _carregarRemessas();
  }

  Future<void> _carregarRemessas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.minhasRemessas(forceRefresh: true);
      final remessas = data.whereType<Map>().map((item) {
        final progresso = item['progresso'] ?? item['progress'] ?? 0;
        return Remessa(
          codigo: '${item['codigo'] ?? item['code'] ?? item['id'] ?? '-'}',
          status: '${item['status'] ?? item['situacao'] ?? 'Aguardando coleta'}',
          origem: '${item['origem'] ?? item['origin'] ?? '-'}',
          destino: '${item['destino'] ?? item['destination'] ?? '-'}',
          tipo: '${item['tipo'] ?? item['tipo_carga'] ?? item['cargo'] ?? '-'}',
          peso: '${item['peso'] ?? item['weight'] ?? '-'}',
          eta: '${item['eta'] ?? item['previsao_entrega'] ?? '-'}',
          progresso: progresso is num ? progresso.toDouble().clamp(0.0, 1.0) : 0.0,
          id: item['id'] ?? item['remessa_id'],
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _remessas = remessas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar as remessas para gerar ou escanear o QR.';
        _loading = false;
      });
    }
  }

  Future<void> _abrirScanner() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (id == null || !mounted) return;

    try {
      final payload = await ApiService.instance.remessa(id);
      final remessa = Remessa(
        codigo: '${payload['codigo'] ?? payload['code'] ?? payload['id'] ?? '-'}',
        status: '${payload['status'] ?? payload['situacao'] ?? 'Aguardando coleta'}',
        origem: '${payload['origem'] ?? payload['origin'] ?? '-'}',
        destino: '${payload['destino'] ?? payload['destination'] ?? '-'}',
        tipo: '${payload['tipo'] ?? payload['tipo_carga'] ?? payload['cargo'] ?? '-'}',
        peso: '${payload['peso'] ?? payload['weight'] ?? '-'}',
        eta: '${payload['eta'] ?? payload['previsao_entrega'] ?? '-'}',
        progresso: (payload['progresso'] ?? payload['progress'] ?? 0) is num
            ? ((payload['progresso'] ?? payload['progress'] ?? 0) as num)
                .toDouble()
                .clamp(0.0, 1.0)
            : 0.0,
        id: payload['id'] ?? payload['remessa_id'],
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetalhesRemessa(remessa: remessa)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível localizar a remessa do QR informado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppGradientHeader(
              title: 'QR da remessa',
              subtitle: 'Gerar ou ler o QR da entrega',
              icon: LucideIcons.qrCode,
              actions: [
                Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _abrirScanner,
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Icon(LucideIcons.scanLine, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ResponsiveContent(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.cloudOff, size: 52),
                                  const SizedBox(height: 12),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 18),
                                  FilledButton.icon(
                                    onPressed: _carregarRemessas,
                                    icon: const Icon(LucideIcons.refreshCw),
                                    label: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_remessas.isEmpty)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Nenhuma remessa disponível para gerar QR.'),
                                  ),
                                )
                              else
                                ..._remessas.map((remessa) => _cardRemessa(remessa)),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardRemessa(Remessa remessa) {
    final payload = RemessaQrCodec.encode(remessa.id ?? remessa.codigo);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF7F9FC),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 78,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remessa.codigo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(remessa.status, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(
                    '${remessa.origem} → ${remessa.destino}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrCodePreviewPage(remessa: remessa),
                  ),
                );
              },
              icon: const Icon(LucideIcons.qrCode),
              label: const Text('QR'),
            ),
          ],
        ),
      ),
    );
  }
}

class QrCodePreviewPage extends StatelessWidget {
  const QrCodePreviewPage({super.key, required this.remessa});

  final Remessa remessa;

  @override
  Widget build(BuildContext context) {
    final payload = RemessaQrCodec.encode(remessa.id ?? remessa.codigo);
    final preview = payload.length > 32 ? '${payload.substring(0, 32)}…' : payload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR da remessa'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remessa.codigo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 240,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conteúdo: $preview',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () async {
                      final scannedId = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const QrScannerPage()),
                      );
                      if (scannedId == null || !context.mounted) return;
                      try {
                        final remessaData = await ApiService.instance.remessa(scannedId);
                        final found = Remessa(
                          codigo: '${remessaData['codigo'] ?? remessaData['code'] ?? remessaData['id'] ?? '-'}',
                          status: '${remessaData['status'] ?? remessaData['situacao'] ?? 'Aguardando coleta'}',
                          origem: '${remessaData['origem'] ?? remessaData['origin'] ?? '-'}',
                          destino: '${remessaData['destino'] ?? remessaData['destination'] ?? '-'}',
                          tipo: '${remessaData['tipo'] ?? remessaData['tipo_carga'] ?? remessaData['cargo'] ?? '-'}',
                          peso: '${remessaData['peso'] ?? remessaData['weight'] ?? '-'}',
                          eta: '${remessaData['eta'] ?? remessaData['previsao_entrega'] ?? '-'}',
                          progresso: (remessaData['progresso'] ?? remessaData['progress'] ?? 0) is num
                              ? ((remessaData['progresso'] ?? remessaData['progress'] ?? 0) as num)
                                  .toDouble()
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          id: remessaData['id'] ?? remessaData['remessa_id'],
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => DetalhesRemessa(remessa: found)),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR válido, mas a remessa não foi encontrada.')),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.scanLine),
                    label: const Text('Ler QR'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR da remessa'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final rawValue = capture.barcodes.firstOrNull?.rawValue;
              final remessaId = RemessaQrCodec.decode(rawValue);
              if (remessaId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR inválido. Use um código gerado pela app.')),
                );
                return;
              }

              _scanned = true;
              if (!mounted) return;
              Navigator.of(context).pop(remessaId);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Posicione o código QR da remessa na câmera',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
