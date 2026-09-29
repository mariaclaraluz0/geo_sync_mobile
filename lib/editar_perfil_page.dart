import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/form_widgets.dart';

/// Edição dos dados do perfil. Fecha devolvendo um mapa com `nome`,
/// `email`, `telefone`, `endereco` e `fotoBytes` quando o usuário salva.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({
    super.key,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.endereco,
    this.fotoBytes,
  });

  final String nome;
  final String email;
  final String telefone;
  final String endereco;
  final Uint8List? fotoBytes;

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  static const _larguraDuasColunas = 760.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _endereco;
  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.nome);
    _email = TextEditingController(text: widget.email);
    _telefone = TextEditingController(text: formatarTelefone(widget.telefone));
    _endereco = TextEditingController(text: widget.endereco);
    _fotoBytes = widget.fotoBytes;
    for (final c in [_nome, _email, _telefone, _endereco]) {
      c.addListener(_atualizar);
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _endereco]) {
      c.dispose();
    }
    super.dispose();
  }

  void _atualizar() => setState(() {});

  bool get _alterado =>
      _nome.text.trim() != widget.nome.trim() ||
      _email.text.trim() != widget.email.trim() ||
      _telefone.text != formatarTelefone(widget.telefone) ||
      _endereco.text.trim() != widget.endereco.trim() ||
      _fotoBytes != widget.fotoBytes;

  String get _iniciais {
    final partes = _nome.text.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (partes.isEmpty) return '';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  void _salvar() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _mostrarMensagem('Revise os campos destacados.');
      return;
    }
    Navigator.pop(context, {
      'nome': _nome.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'telefone': _telefone.text.trim(),
      'endereco': _endereco.text.trim(),
      'fotoBytes': _fotoBytes,
    });
  }

  Future<void> _sairSemSalvar() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(CupertinoIcons.square_pencil, size: 32),
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você alterou seus dados e ainda não salvou. Se sair agora, as '
          'mudanças serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) Navigator.pop(context);
  }

  Future<void> _selecionarFoto(ImageSource source) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (mounted) setState(() => _fotoBytes = bytes);
    } catch (_) {
      _mostrarMensagem('Não foi possível carregar a imagem.');
    }
  }

  void _abrirOpcoesFoto() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) {
        final scheme = Theme.of(sheet).colorScheme;
        Widget opcao(
          IconData icone,
          String titulo,
          String subtitulo,
          VoidCallback acao, {
          Color? cor,
        }) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (cor ?? scheme.primary).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: cor ?? scheme.primary),
          ),
          title: Text(
            titulo,
            style: TextStyle(fontWeight: FontWeight.w600, color: cor),
          ),
          subtitle: Text(subtitulo),
          onTap: () {
            Navigator.pop(sheet);
            acao();
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Foto do perfil',
                style: Theme.of(
                  sheet,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              opcao(
                CupertinoIcons.camera,
                'Tirar foto',
                'Use a câmera do aparelho',
                () => _selecionarFoto(ImageSource.camera),
              ),
              opcao(
                CupertinoIcons.photo_on_rectangle,
                'Escolher da galeria',
                'Selecione uma imagem salva',
                () => _selecionarFoto(ImageSource.gallery),
              ),
              if (_fotoBytes != null)
                opcao(
                  CupertinoIcons.trash,
                  'Remover foto',
                  'Voltar a exibir suas iniciais',
                  () => setState(() => _fotoBytes = null),
                  cor: scheme.error,
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _sairSemSalvar();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= _larguraDuasColunas;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _cabecalho()),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            largo ? 24 : 0,
                            16,
                            24,
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: AutofillGroup(
                              child: largo
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 280,
                                          child: _cartaoIdentidade(),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(child: _secoes()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _identidadeSobreposta(),
                                        const SizedBox(height: 20),
                                        _secoes(),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: Padding(
          // Mantém a barra de ações visível acima do teclado.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FormActionBar(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _alterado ? _salvar : null,
                  icon: const Icon(CupertinoIcons.checkmark),
                  label: const Text('Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() => AppGradientHeader(
    title: 'Editar perfil',
    subtitle: _alterado
        ? 'Você tem alterações não salvas'
        : 'Mantenha seus dados atualizados',
    icon: CupertinoIcons.person_crop_circle,
  );

  /// Avatar com nome e e-mail logo abaixo do cabeçalho (celular).
  Widget _identidadeSobreposta() =>
      Padding(padding: const EdgeInsets.only(top: 20), child: _identidade());

  /// Mesmo conteúdo em um cartão lateral (tablet).
  Widget _cartaoIdentidade() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          _identidade(),
          const SizedBox(height: 20),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 12),
          _dica(
            CupertinoIcons.checkmark_shield,
            'Seus dados são usados apenas para suas entregas e contato.',
          ),
        ],
      ),
    );
  }

  Widget _identidade() {
    final scheme = Theme.of(context).colorScheme;
    final nome = _nome.text.trim();
    final email = _email.text.trim();
    return Column(
      children: [
        _avatar(),
        const SizedBox(height: 14),
        Text(
          nome.isEmpty ? 'Seu nome' : nome,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _abrirOpcoesFoto,
          icon: const Icon(CupertinoIcons.camera, size: 18),
          label: Text(_fotoBytes == null ? 'Adicionar foto' : 'Alterar foto'),
        ),
      ],
    );
  }

  Widget _avatar() {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Alterar foto do perfil',
      child: GestureDetector(
        onTap: _abrirOpcoesFoto,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Anel em gradiente ao redor da foto.
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0B2A4A), Color(0xFF0C46FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  backgroundImage: _fotoBytes == null
                      ? null
                      : MemoryImage(_fotoBytes!),
                  child: _fotoBytes != null
                      ? null
                      : _iniciais.isEmpty
                      ? Icon(
                          CupertinoIcons.person_fill,
                          size: 52,
                          color: scheme.primary,
                        )
                      : Text(
                          _iniciais,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 3),
                ),
                child: Icon(
                  CupertinoIcons.camera_fill,
                  size: 19,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secoes() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormSectionCard(
        title: 'Informações pessoais',
        subtitle: 'Como você aparece no app',
        icon: CupertinoIcons.person_crop_rectangle,
        children: [
          _campo(
            controller: _nome,
            label: 'Nome completo',
            icon: CupertinoIcons.person,
            hint: 'Ex.: Maria da Silva',
            autofill: AutofillHints.name,
            capitalization: TextCapitalization.words,
            validator: (v) {
              final nome = v?.trim() ?? '';
              if (nome.isEmpty) return 'Informe seu nome';
              if (nome.length < 3) return 'Nome muito curto';
              return null;
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormSectionCard(
        title: 'Contato',
        subtitle: 'Usado para avisos sobre suas entregas',
        icon: CupertinoIcons.person_crop_square,
        children: [
          _campo(
            controller: _email,
            label: 'E-mail',
            icon: CupertinoIcons.at,
            hint: 'voce@exemplo.com',
            keyboard: TextInputType.emailAddress,
            autofill: AutofillHints.email,
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) return 'Informe seu e-mail';
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                  ? null
                  : 'E-mail inválido';
            },
          ),
          _campo(
            controller: _telefone,
            label: 'Telefone',
            icon: CupertinoIcons.device_phone_portrait,
            hint: '(11) 91234-5678',
            keyboard: TextInputType.phone,
            autofill: AutofillHints.telephoneNumber,
            formatter: TelefoneInputFormatter(),
            validator: (v) {
              final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digitos.isEmpty) return 'Informe seu telefone';
              return digitos.length < 10 ? 'Telefone incompleto' : null;
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      FormSectionCard(
        title: 'Endereço',
        subtitle: 'Local padrão para coletas e entregas',
        icon: CupertinoIcons.map,
        children: [
          _campo(
            controller: _endereco,
            label: 'Endereço completo',
            icon: CupertinoIcons.house,
            hint: 'Rua, número, bairro, cidade - UF',
            autofill: AutofillHints.fullStreetAddress,
            capitalization: TextCapitalization.words,
            maxLines: 2,
            ultimo: true,
            validator: (v) => (v?.trim().length ?? 0) < 5
                ? 'Informe o endereço completo'
                : null,
          ),
        ],
      ),
    ],
  );

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    String? autofill,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputFormatter? formatter,
    int maxLines = 1,
    bool ultimo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: maxLines > 1 ? TextInputType.streetAddress : keyboard,
        textCapitalization: capitalization,
        autofillHints: autofill == null ? null : [autofill],
        inputFormatters: formatter == null ? null : [formatter],
        minLines: 1,
        maxLines: maxLines,
        textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: ultimo && _alterado ? (_) => _salvar() : null,
        validator: validator,
        decoration: modernInputDecoration(
          context,
          label: label,
          icon: icon,
          hint: hint,
          suffix: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  icon: const Icon(CupertinoIcons.xmark, size: 20),
                  onPressed: controller.clear,
                ),
        ),
      ),
    );
  }

  Widget _dica(IconData icone, String texto) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
