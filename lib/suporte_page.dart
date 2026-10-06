import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class SuportePage extends StatefulWidget {
  const SuportePage({super.key, this.motorista = false});

  final bool motorista;

  @override
  State<SuportePage> createState() => _SuportePageState();
}

class _SuportePageState extends State<SuportePage> {
  static const _azul = Color(0xFF1749E8);
  static const _tinta = Color(0xFF14213D);
  final _mensagemController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitacao(String canal, VoidCallback atualizarSheet) async {
    final mensagem = _mensagemController.text.trim();
    if (mensagem.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    atualizarSheet();
    var enviado = false;
    try {
      await ApiService.instance.criarContato(mensagem: mensagem, canal: canal);
      if (!mounted) return;
      enviado = true;
      setState(() => _enviando = false);
      atualizarSheet();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Solicitação enviada pelo $canal. Retornaremos em breve.'),
        ),
      );
      _mensagemController.clear();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(error.message)),
        );
      }
    } finally {
      if (mounted && !enviado) {
        setState(() => _enviando = false);
        atualizarSheet();
      }
    }
  }

  void _abrirFormulario(String titulo, String canal) {
    _mensagemController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Text(
                  'Conte o que aconteceu. Nossa equipe receberá sua mensagem e poderá ajudar.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _mensagemController,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Sua mensagem',
                    hintText: 'Descreva sua dúvida ou situação...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _enviando
                        ? null
                        : () {
                            _enviarSolicitacao(canal, () => setSheetState(() {}));
                          },
                    icon: _enviando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.send, size: 18),
                    label: Text(_enviando ? 'Enviando...' : 'Enviar mensagem'),
                    style: FilledButton.styleFrom(backgroundColor: _azul, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _abrirFaq() {
    final perguntas = widget.motorista
        ? const [
            ('Como atualizo meus dados?', 'Abra Configurações e acesse Dados pessoais para revisar suas informações.'),
            ('Como funciona a sincronização?', 'As alterações ficam salvas no aparelho e são enviadas quando houver conexão.'),
            ('Preciso de ajuda com uma entrega?', 'Abra a entrega correspondente e use Ajuda e suporte para enviar os detalhes à equipe.'),
          ]
        : const [
            ('Como acompanho uma remessa?', 'Acesse Remessas e selecione o pedido desejado para ver o rastreamento.'),
            ('Como atualizo meus dados?', 'Abra Perfil e toque em Editar perfil.'),
            ('Esqueci minha senha, o que faço?', 'Acesse Perfil e escolha Alterar senha.'),
          ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 22),
            Text('Perguntas frequentes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Respostas rápidas para as dúvidas mais comuns.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ...perguntas.map((item) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: const Icon(LucideIcons.circleHelp, color: _azul, size: 20),
                    title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(56, 0, 18, 16),
                    children: [Text(item.$2, style: TextStyle(height: 1.45, color: Theme.of(context).colorScheme.onSurfaceVariant))],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: const Text('Ajuda e suporte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1749E8), Color(0xFF3975FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: _azul.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Stack(
              children: [
                Positioned(right: -8, top: 8, child: Icon(LucideIcons.headset, size: 86, color: Colors.white.withValues(alpha: 0.14))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)), child: const Text('CENTRAL DE AJUDA', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800))),
                  const SizedBox(height: 15),
                  const Text('Como podemos\najudar você?', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Text('Encontre respostas ou fale com a equipe GeoSync.', style: TextStyle(color: Colors.white.withValues(alpha: 0.86), height: 1.4)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text('Acesso rápido', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _tinta, fontWeight: FontWeight.w800)),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(child: _AtalhoSuporte(icon: LucideIcons.messageCircle, titulo: 'Enviar mensagem', color: const Color(0xFF2563EB), onTap: () => _abrirFormulario('Fale com o suporte', 'chat'))),
            const SizedBox(width: 12),
            Expanded(child: _AtalhoSuporte(icon: LucideIcons.circleHelp, titulo: 'Dúvidas frequentes', color: const Color(0xFF7C3AED), onTap: _abrirFaq)),
          ]),
          const SizedBox(height: 27),
          Text('Outros canais', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _tinta, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _CanalSuporte(icon: LucideIcons.mail, cor: const Color(0xFF0F9D78), titulo: 'E-mail', detalhe: 'suporte@geosync.com.br', acao: 'Enviar mensagem', onTap: () => _abrirFormulario('Enviar e-mail', 'e-mail')),
          const SizedBox(height: 10),
          _CanalSuporte(icon: LucideIcons.phone, cor: const Color(0xFFEA8A16), titulo: 'Central telefônica', detalhe: '0800 123 4567 · Seg a sex, 8h às 18h', acao: 'Ver horário', onTap: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                icon: const Icon(LucideIcons.headset, color: _azul),
                title: const Text('Central telefônica'),
                content: const Text('Ligue gratuitamente para 0800 123 4567, de segunda a sexta, das 8h às 18h.'),
                actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Entendi'))],
              ))),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.shieldCheck, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 7),
            Text('Estamos aqui para ajudar você', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ]),
        ],
      ),
    );
  }
}

class _AtalhoSuporte extends StatelessWidget {
  const _AtalhoSuporte({required this.icon, required this.titulo, required this.color, required this.onTap});
  final IconData icon;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 138),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 21)),
              const SizedBox(height: 13),
              Row(children: [Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2))), Icon(LucideIcons.arrowUpRight, size: 17, color: color)]),
            ]),
          ),
        ),
      );
}

class _CanalSuporte extends StatelessWidget {
  const _CanalSuporte({required this.icon, required this.cor, required this.titulo, required this.detalhe, required this.acao, required this.onTap});
  final IconData icon;
  final Color cor;
  final String titulo;
  final String detalhe;
  final String acao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: cor, size: 21)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(detalhe, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))])),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant, size: 19),
          ]),
        ),
      ),
    );
  }
}
