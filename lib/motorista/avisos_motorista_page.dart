import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/responsive_content.dart';

class AvisosMotoristaPage extends StatefulWidget {
  const AvisosMotoristaPage({super.key});

  @override
  State<AvisosMotoristaPage> createState() => _AvisosMotoristaPageState();
}

class _AvisosMotoristaPageState extends State<AvisosMotoristaPage> {
  static const _primary = Color(0xFF0C46FF);
  List<Map<String, dynamic>> _avisos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.avisosMotorista(forceRefresh: refresh);
      if (!mounted) return;
      setState(() {
        _avisos = response.whereType<Map>().map((a) => Map<String, dynamic>.from(a)).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  bool _read(Map<String, dynamic> aviso) =>
      aviso['lido'] == true || aviso['read'] == true || aviso['read_at'] != null;

  Future<void> _readOne(Map<String, dynamic> aviso) async {
    if (_read(aviso) || aviso['id'] == null) return;
    setState(() => aviso['lido'] = true);
    try {
      await ApiService.instance.marcarAvisoComoLido(aviso['id']);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => aviso['lido'] = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _readAll() async {
    setState(() => _avisos.forEach((a) => a['lido'] = true));
    try {
      await ApiService.instance.marcarTodosAvisosComoLidos();
    } on ApiException catch (error) {
      if (!mounted) return;
      await _load(refresh: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _avisos.where((a) => !_read(a)).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [TextButton(onPressed: _avisos.isEmpty ? null : _readAll, child: const Text('Marcar como lidos'))],
      ),
      body: ResponsiveContent(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(_error!))])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text('$unread aviso${unread == 1 ? '' : 's'} não lido${unread == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    if (_avisos.isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: Text('Não há avisos no momento.'))),
                    ..._avisos.map(_card),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> aviso) {
    final read = _read(aviso);
    final title = '${aviso['titulo'] ?? aviso['title'] ?? 'Aviso'}';
    final message = '${aviso['descricao'] ?? aviso['message'] ?? aviso['mensagem'] ?? ''}';
    final date = '${aviso['created_at'] ?? aviso['data'] ?? ''}';
    return Card(
      child: ListTile(
        onTap: () => _readOne(aviso),
        leading: CircleAvatar(backgroundColor: _primary.withValues(alpha: .12), child: const Icon(Icons.notifications_outlined, color: _primary)),
        title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.w500 : FontWeight.w800)),
        subtitle: Text(message),
        trailing: read ? Text(date, style: const TextStyle(fontSize: 10)) : const Badge(smallSize: 9),
      ),
    );
  }
}
