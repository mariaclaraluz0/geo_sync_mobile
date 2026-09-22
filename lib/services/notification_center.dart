import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app_session.dart';

enum NotificationSeverity { info, warning, critical }

/// Centraliza a contagem de não lidos e exibe um banner chamativo (com som e
/// vibração) quando surge um item novo. Não depende de nenhum pacote de push;
/// funciona por polling enquanto o app está aberto.
class AppNotificationCenter {
  AppNotificationCenter._();

  static final AppNotificationCenter instance = AppNotificationCenter._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Timer? _timer;
  Future<List<dynamic>> Function()? _fetcher;
  OverlayState? _overlay;
  final Set<String> _seenIds = {};
  bool _primed = false;

  /// Começa a monitorar [fetch] (ex.: alertas ou avisos) em [interval].
  /// Deve ser chamado a partir de uma tela sempre visível (dashboard).
  void attach(
    BuildContext context, {
    required Future<List<dynamic>> Function() fetch,
    Duration interval = const Duration(seconds: 45),
  }) {
    _fetcher = fetch;
    _overlay = Overlay.maybeOf(context, rootOverlay: true);
    _seenIds.clear();
    _primed = false;
    _timer?.cancel();
    unawaited(_poll());
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  void detach() {
    _timer?.cancel();
    _timer = null;
    _fetcher = null;
    _overlay = null;
  }

  Future<void> refreshNow() => _poll();

  /// Mostra um banner avulso (ex.: nova entrega disponível), sem afetar a
  /// contagem de não lidos monitorada por [attach].
  void notify({
    required String titulo,
    String mensagem = '',
    NotificationSeverity severidade = NotificationSeverity.info,
  }) => _notificar(titulo: titulo, mensagem: mensagem, severidade: severidade);

  Future<void> _poll() async {
    final fetch = _fetcher;
    if (fetch == null) return;
    try {
      final items = await fetch();
      _handle(items);
    } catch (_) {
      // Mantém a última contagem conhecida em caso de falha de rede.
    }
  }

  bool _isRead(Map item) =>
      item['lido'] == true || item['read'] == true || item['read_at'] != null;

  String _idOf(Map item) => '${item['id'] ?? item['_id'] ?? item.hashCode}';

  void _handle(List<dynamic> items) {
    final maps = items.whereType<Map>().toList();
    final naoLidos = maps.where((item) => !_isRead(item)).toList();
    unreadCount.value = naoLidos.length;

    if (!_primed) {
      _seenIds
        ..clear()
        ..addAll(maps.map(_idOf));
      _primed = true;
      return;
    }

    final novos = naoLidos
        .where((item) => !_seenIds.contains(_idOf(item)))
        .toList();
    _seenIds
      ..clear()
      ..addAll(maps.map(_idOf));
    if (novos.isEmpty) return;

    final destaque = novos.first;
    _notificar(
      titulo: '${destaque['titulo'] ?? destaque['title'] ?? 'Novo alerta'}',
      mensagem:
          '${destaque['descricao'] ?? destaque['message'] ?? destaque['mensagem'] ?? ''}',
      severidade: _severidadeDe(destaque),
      extras: novos.length - 1,
    );
  }

  NotificationSeverity _severidadeDe(Map item) {
    final status = '${item['status'] ?? item['gravidade'] ?? ''}'
        .toLowerCase();
    if (status.contains('crít') || status.contains('critic')) {
      return NotificationSeverity.critical;
    }
    if (status.contains('aten') || status.contains('warn')) {
      return NotificationSeverity.warning;
    }
    return NotificationSeverity.info;
  }

  void _notificar({
    required String titulo,
    required String mensagem,
    required NotificationSeverity severidade,
    int extras = 0,
  }) {
    if (!AppSession.notificacoesAtivas.value) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);

    final overlay = _overlay;
    if (overlay == null || !overlay.mounted) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NotificationBanner(
        titulo: titulo,
        mensagem: extras > 0
            ? '$mensagem  (+$extras nova${extras == 1 ? '' : 's'})'
            : mensagem,
        severidade: severidade,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Timer(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _NotificationBanner extends StatefulWidget {
  const _NotificationBanner({
    required this.titulo,
    required this.mensagem,
    required this.severidade,
    required this.onDismiss,
  });

  final String titulo;
  final String mensagem;
  final NotificationSeverity severidade;
  final VoidCallback onDismiss;

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fechar() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  (Color, Color, IconData) get _estilo {
    switch (widget.severidade) {
      case NotificationSeverity.critical:
        return (const Color(0xFFB91C1C), const Color(0xFFD64545), Icons.error_outline);
      case NotificationSeverity.warning:
        return (const Color(0xFF92400E), const Color(0xFFE58A00), Icons.warning_amber_rounded);
      case NotificationSeverity.info:
        return (const Color(0xFF0B2A4A), const Color(0xFF0C46FF), Icons.notifications_active_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (corEscura, corClara, icone) = _estilo;
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: GestureDetector(
              onTap: _fechar,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [corEscura, corClara],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: corClara.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icone, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.mensagem.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.mensagem,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _fechar,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
