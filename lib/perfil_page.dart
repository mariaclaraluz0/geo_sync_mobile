import 'package:flutter/material.dart';

import 'package:mobile/editar_perfil_page.dart';
import 'package:mobile/login_screen.dart';
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

  // ============================================================
  // PALETA DE CORES — GEOSYNC
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);

  static const Color background = Color(0xFFF5F7FB);

  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);

  static const Color border = Color(0xFFE8ECF3);

  static const Color surface = Colors.white;
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
          backgroundColor: surface,
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
                    Icons.logout_rounded,
                    color: error,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Sair da conta?",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Você precisará entrar novamente para acessar sua conta.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4, color: textLight),
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
                          foregroundColor: textDark,
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: border),
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
                        onPressed: () {
                          Navigator.of(dialogContext).pop();

                          _mostrarSnackBar("Sessão encerrada com sucesso.");

                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (!mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          });
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
      backgroundColor: background,
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
                              ),
                            ),
                          );

                          if (resultado != null) {
                            setState(() {
                              _nome = resultado['nome'];
                              _email = resultado['email'];
                              _telefone = resultado['telefone'];
                              _endereco = resultado['endereco'];
                            });
                          }
                        },
                      ),

                      _buildDivider(),

                      _buildMenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: "Alterar senha",
                        subtitle: "Mantenha sua conta protegida",
                        iconBackground: primaryDark.withValues(alpha: 0.08),
                        iconColor: primaryDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AlterarSenhaPage(),
                            ),
                          );
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
                      icon: const Icon(Icons.logout_rounded, size: 19),
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
                  color: surface,
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
                child: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF0FF),
                  child: Icon(Icons.person_rounded, size: 55, color: primary),
                ),
              ),

              // ==================================================
              // BOTÃO EDITAR FOTO
              // ==================================================
              Positioned(
                right: -2,
                bottom: 0,
                child: Material(
                  color: surface,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _mostrarSnackBar("Alterar foto de perfil");
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: surface,
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: textLight,
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
        color: surface,
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
                  style: const TextStyle(
                    color: textLight,
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
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: textLight, size: 22),
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
        color: surface,
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
                      style: const TextStyle(
                        color: textDark,
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
                        color: textLight,
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
