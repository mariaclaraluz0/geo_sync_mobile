import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:mobile/editar_perfil_page.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'alterar_senha_page.dart';
import 'configuracoes_page.dart';
import 'suporte_page.dart';

class PerfilClientePage extends StatefulWidget {
  const PerfilClientePage({super.key});

  @override
  State<PerfilClientePage> createState() => _PerfilClientePageState();
}

class _PerfilClientePageState extends State<PerfilClientePage> {
  // ============================================================
  // DADOS DO USUÁRIO
  // ============================================================

  String _nome = "Maria Clara";
  final String _tipoCliente = "Cliente Premium";
  String _email = "mariaclara@email.com";
  String _telefone = "(19) 99999-9999";
  String _endereco = "Campinas - SP";
  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final resposta = ApiService.instance.authData(
        await ApiService.instance.me(),
      );
      final usuario = ApiService.instance.authUser(resposta);
      if (!mounted || usuario.isEmpty) return;
      setState(() {
        _nome = '${usuario['name'] ?? usuario['nome'] ?? _nome}';
        _email = '${usuario['email'] ?? _email}';
        _telefone = '${usuario['telefone'] ?? usuario['phone'] ?? _telefone}';
        _endereco = '${usuario['endereco'] ?? usuario['address'] ?? _endereco}';
      });
    } on ApiException {
      // Mantém os dados locais enquanto a API estiver indisponível.
    }
  }

  // ============================================================
  // PALETA DE CORES — GEOSYNC
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);

  static const Color textLight = Color(0xFF718096);

  static const Color border = Color(0xFFE8ECF3);

  static const Color error = Color(0xFFD64545);

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: primaryDark,
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensagem,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _confirmarSaida() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return Dialog(
          backgroundColor: scheme.surface,
          elevation: 10,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ÍCONE
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: error,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Sair da conta?",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Você precisará entrar novamente para acessar sua conta.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    // CANCELAR
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          minimumSize: const Size(0, 48),
                          side: BorderSide(color: scheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // SAIR
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();

                          try {
                            await ApiService.instance.logout();
                          } catch (_) {
                            // Remove the local credentials if the server is unavailable.
                          }
                          await AppSession.encerrarSessao();
                          if (!mounted) return;

                          _mostrarSnackBar("Sessão encerrada com sucesso.");

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Sair",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // HEADER
          // ======================================================
          SliverToBoxAdapter(child: _buildHeader()),

          // ======================================================
          // CONTEÚDO
          // ======================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // MINHA CONTA
                  // ==================================================
                  _buildSectionTitle("Minha conta", "Seus dados pessoais"),

                  const SizedBox(height: 12),

                  _buildInfoSection(),

                  const SizedBox(height: 28),

                  // ==================================================
                  // CONTA
                  // ==================================================
                  _buildSectionTitle("Conta", "Gerencie seu perfil"),

                  const SizedBox(height: 12),

                  _buildMenuSection(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: "Editar perfil",
                        subtitle: "Atualize seus dados pessoais",
                        iconBackground: primary.withValues(alpha: 0.08),
                        iconColor: primary,
                        onTap: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarPerfilPage(
                                nome: _nome,
                                email: _email,
                                telefone: _telefone,
                                endereco: _endereco,
                                fotoBytes: _fotoBytes,
                              ),
                            ),
                          );

                          if (resultado != null) {
                            setState(() {
                              _nome = resultado['nome'];
                              _email = resultado['email'];
                              _telefone = resultado['telefone'];
                              _endereco = resultado['endereco'];
                              _fotoBytes = resultado['fotoBytes'];
                            });
                            try {
                              await ApiService.instance.updateProfile({
                                'name': _nome,
                                'email': _email,
                                'telefone': _telefone,
                                'endereco': _endereco,
                              });
                              if (mounted) {
                                _mostrarSnackBar(
                                  'Perfil atualizado no servidor.',
                                );
                              }
                            } on ApiException catch (error) {
                              if (mounted) _mostrarSnackBar(error.message);
                            }
                          }
                        },
                      ),

                      _buildDivider(),

                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: "Alterar senha",
                        subtitle: "Mantenha sua conta protegida",
                        iconBackground: primaryDark.withValues(alpha: 0.08),
                        iconColor: primaryDark,
                        onTap: () async {
                          final senhaAlterada = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AlterarSenhaPage(),
                            ),
                          );
                          if (senhaAlterada == true && mounted) {
                            _mostrarSnackBar('Senha atualizada com sucesso.');
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // AJUDA E PREFERÊNCIAS
                  // ==================================================
                  _buildSectionTitle(
                    "Ajuda e preferências",
                    "Personalize sua experiência",
                  ),

                  const SizedBox(height: 12),

                  _buildMenuSection(
                    children: [
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: "Configurações",
                        subtitle: "Preferências e acessibilidade",
                        iconBackground: primaryDark.withValues(alpha: 0.08),
                        iconColor: primaryDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConfiguracoesPage(),
                            ),
                          );
                        },
                      ),

                      _buildDivider(),

                      _buildMenuItem(
                        icon: Icons.support_agent_outlined,
                        title: "Suporte",
                        subtitle: "Precisa de ajuda? Fale conosco",
                        iconBackground: primary.withValues(alpha: 0.08),
                        iconColor: primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SuportePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ==================================================
                  // SAIR
                  // ==================================================
                  Center(
                    child: TextButton.icon(
                      onPressed: _confirmarSaida,
                      icon: const Icon(Icons.logout, size: 19),
                      label: const Text(
                        "Sair da conta",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // VERSÃO
                  // ==================================================
                  const Center(
                    child: Text(
                      "GeoSync • Perfil do Cliente",
                      style: TextStyle(
                        fontSize: 11,
                        color: textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarFoto(ImageSource source) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
      _mostrarSnackBar('Foto de perfil atualizada.');
    } catch (_) {
      if (!mounted) return;
      _mostrarSnackBar('Não foi possível carregar a imagem.');
    }
  }

  void _abrirSeletorFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          // ======================================================
          // TOP BAR
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GeoSync",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Meu perfil",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ======================================================
          // AVATAR
          // ======================================================
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Color(0xFFEAF0FF),
                  backgroundImage: _fotoBytes == null
                      ? null
                      : MemoryImage(_fotoBytes!),
                  child: _fotoBytes == null
                      ? const Icon(
                          Icons.person_outline,
                          size: 55,
                          color: primary,
                        )
                      : null,
                ),
              ),

              // ==================================================
              // BOTÃO EDITAR FOTO
              // ==================================================
              Positioned(
                right: -2,
                bottom: 0,
                child: Semantics(
                  button: true,
                  label: 'Alterar foto do perfil',
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _abrirSeletorFoto,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: primary,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // NOME
          // ======================================================
          Text(
            _nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // BADGE PREMIUM
          // ======================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                          Icons.workspace_premium_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _tipoCliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TÍTULO DE SEÇÃO
  // ============================================================

  Widget _buildSectionTitle(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEÇÃO DE INFORMAÇÕES
  // ============================================================

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: "E-mail",
            value: _email,
          ),

          _buildDivider(),

          _buildInfoItem(
            icon: Icons.phone_outlined,
            title: "Telefone",
            value: _telefone,
          ),

          _buildDivider(),

          _buildInfoItem(
            icon: Icons.location_on_outlined,
            title: "Localização",
            value: _endereco,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM DE INFORMAÇÃO
  // ============================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          // ÍCONE
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),

          const SizedBox(width: 13),

          // TEXTOS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEÇÃO DE MENU
  // ============================================================

  Widget _buildMenuSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ============================================================
  // ITEM DO MENU
  // ============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: primary.withValues(alpha: 0.06),
        highlightColor: primary.withValues(alpha: 0.025),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ==================================================
              // ÍCONE
              // ==================================================
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 13),

              // ==================================================
              // TEXTOS
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // SETA
              // ==================================================
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primaryDark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: textLight,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIVISOR
  // ============================================================

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 73),
      child: Divider(height: 1, thickness: 1, color: border),
    );
  }
}
