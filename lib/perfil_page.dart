import 'package:flutter/material.dart';
import 'package:mobile/editarPerfil_page.dart';
import 'package:mobile/login_screen.dart';
import 'alterarSenha_page.dart';
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
  String _tipoCliente = "Cliente Premium";
  String _email = "mariaclara@email.com";
  String _telefone = "(19) 99999-9999";
  String _endereco = "Campinas - SP";

  // ============================================================
  // PALETA DE CORES — GEOSYNC
  // ============================================================

  // Azul principal — identidade visual
  static const Color _azulPrincipal = Color(0xFF123B5D);

  // Azul secundário — utilizado no gradiente do Header
  static const Color _azulSecundario = Color(0xFF1B5E85);

  // Azul claro — fundos de destaque e ícones
  static const Color _azulDestaque = Color(0xFFE8F3F8);

  // Fundo geral da página
  static const Color _fundo = Color(0xFFF7F9FC);

  // Superfície dos cards
  static const Color _superficie = Color(0xFFFFFFFF);

  // Textos
  static const Color _textoPrincipal = Color(0xFF102A43);
  static const Color _textoSecundario = Color(0xFF627D98);

  // Bordas e divisores
  static const Color _borda = Color(0xFFD9E2EC);
  static const Color _divisor = Color(0xFFEAF0F6);

  // Ícones secundários
  static const Color _cinzaIcones = Color(0xFFF1F5F9);
  static const Color _cinzaIconesTexto = Color(0xFF486581);

  // Ações destrutivas
  static const Color _erro = Color(0xFFC94B4B);

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
          backgroundColor: _azulPrincipal,
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
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
        return Dialog(
          backgroundColor: _superficie,
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
                    color: _erro.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: _erro,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Sair da conta?",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _textoPrincipal,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Você precisará entrar novamente para acessar sua conta.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _textoSecundario,
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
                          foregroundColor: _textoPrincipal,
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(
                            color: _borda,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // SAIR
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();

                          _mostrarSnackBar(
                            "Sessão encerrada com sucesso.",
                          );

                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () {
                              if (!mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _erro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Sair",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
      backgroundColor: _fundo,

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),

        slivers: [
          // ======================================================
          // HEADER
          // ======================================================

          SliverToBoxAdapter(
            child: _buildHeader(),
          ),

          // ======================================================
          // CONTEÚDO
          // ======================================================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MINHA CONTA
                  _buildSectionTitle(
                    "Minha conta",
                    "Seus dados pessoais",
                  ),

                  const SizedBox(height: 12),

                  _buildInfoSection(),

                  const SizedBox(height: 28),

                  // CONTA
                  _buildSectionTitle(
                    "Conta",
                    "Gerencie seu perfil",
                  ),

                  const SizedBox(height: 12),

                  _buildMenuSection(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: "Editar perfil",
                        subtitle: "Atualize seus dados pessoais",
                        iconBackground: _azulDestaque,
                        iconColor: _azulPrincipal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditarPerfilPage(),
                            ),
                          );
                        },
                      ),

                      _buildDivider(),

                      _buildMenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: "Alterar senha",
                        subtitle: "Mantenha sua conta protegida",
                        iconBackground: _cinzaIcones,
                        iconColor: _cinzaIconesTexto,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AlterarSenhaPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // AJUDA E PREFERÊNCIAS
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
                        iconBackground: _cinzaIcones,
                        iconColor: _cinzaIconesTexto,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ConfiguracoesPage(),
                            ),
                          );
                        },
                      ),

                      _buildDivider(),

                      _buildMenuItem(
                        icon: Icons.support_agent_outlined,
                        title: "Suporte",
                        subtitle: "Precisa de ajuda? Fale conosco",
                        iconBackground: _azulDestaque,
                        iconColor: _azulPrincipal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SuportePage(),
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
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        "Sair da conta",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _erro,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // VERSÃO
                  const Center(
                    child: Text(
                      "GeoSync • Perfil do Cliente",
                      style: TextStyle(
                        fontSize: 11,
                        color: _textoSecundario,
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 28,
      ),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _azulPrincipal,
            _azulSecundario,
          ],
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
                  color: _superficie,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.75),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: _azulDestaque,
                  child: Icon(
                    Icons.person_rounded,
                    size: 55,
                    color: _azulPrincipal,
                  ),
                ),
              ),

              // BOTÃO EDITAR FOTO
              Positioned(
                right: -2,
                bottom: 0,
                child: Material(
                  color: _superficie,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _mostrarSnackBar(
                        "Alterar foto de perfil",
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _superficie,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: _azulPrincipal,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // NOME
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

          // BADGE PREMIUM
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
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

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: _textoSecundario,
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
        color: _superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borda,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _azulDestaque,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: _azulPrincipal,
              size: 20,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: _textoSecundario,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEÇÃO DE MENU
  // ============================================================

  Widget _buildMenuSection({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borda,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: children,
      ),
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
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: _azulPrincipal.withOpacity(0.05),
        highlightColor: _azulPrincipal.withOpacity(0.025),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          child: Row(
            children: [
              // ÍCONE
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              // TEXTOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textoPrincipal,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // SETA
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _cinzaIcones,
                  borderRadius: BorderRadius.circular(9),
                ),

                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _textoSecundario,
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
      child: Divider(
        height: 1,
        thickness: 1,
        color: _divisor,
      ),
    );
  }
}