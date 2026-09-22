import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/app_session.dart';

import 'package:mobile/perfil_page.dart';
import 'package:mobile/remessa_page.dart' hide RemessaCard;
import 'package:mobile/mapa_page.dart';
import 'package:mobile/carteira_page.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notification_center.dart';
import 'alerta_page.dart';

class TelaDashboard extends StatefulWidget {
  final String tipoUsuario;

  const TelaDashboard({super.key, this.tipoUsuario = 'Cliente'});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _currentIndex = 0;

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textLight => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get border => Theme.of(context).colorScheme.outlineVariant;
  Color get cardColor => Theme.of(context).colorScheme.surface;

  // ============================================================
  // DADOS DA OPERAÇÃO
  // ============================================================

  bool _carregandoResumo = true;
  List<Remessa> _remessas = [];
  List<Alerta> _alertas = [];
  double _saldoMovimentado = 0;
  double? _avaliacaoMedia;

  int get _totalRemessas => _remessas.length;
  int get _entregues =>
      _remessas.where((r) => r.status == 'Entregue').length;
  int get _emTransito => _remessas
      .where((r) => r.status == 'Em Trânsito' || r.status == 'Em rota')
      .length;
  int get _comOcorrencia => _remessas
      .where((r) => r.status == 'Alerta' || r.status == 'Atrasado')
      .length;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotificationCenter.instance.attach(
        context,
        fetch: () => ApiService.instance.alertas(),
      );
    });
  }

  @override
  void dispose() {
    AppNotificationCenter.instance.detach();
    super.dispose();
  }

  Future<void> _carregarResumo() async {
    if (mounted) setState(() => _carregandoResumo = true);
    final resultados = await Future.wait([
      _carregarRemessas(),
      _carregarAlertas(),
      _carregarSaldo(),
      _carregarAvaliacao(),
    ]);
    if (!mounted) return;
    setState(() {
      _remessas = resultados[0] as List<Remessa>;
      _alertas = resultados[1] as List<Alerta>;
      _saldoMovimentado = resultados[2] as double;
      _avaliacaoMedia = resultados[3] as double?;
      _carregandoResumo = false;
    });
  }

  Future<List<Remessa>> _carregarRemessas() async {
    try {
      final dados = await ApiService.instance.minhasRemessas(
        forceRefresh: true,
      );
      return dados.whereType<Map>().map((value) {
        final progresso = value['progresso'] ?? value['progress'] ?? 0;
        return Remessa(
          codigo: '${value['codigo'] ?? value['code'] ?? value['id'] ?? '-'}',
          status: '${value['status'] ?? value['situacao'] ?? 'Aguardando coleta'}',
          origem: '${value['origem'] ?? value['origin'] ?? '-'}',
          destino: '${value['destino'] ?? value['destination'] ?? '-'}',
          tipo: '${value['tipo'] ?? value['tipo_carga'] ?? value['cargo'] ?? '-'}',
          peso: '${value['peso'] ?? value['weight'] ?? '-'}',
          eta: '${value['eta'] ?? value['previsao_entrega'] ?? '-'}',
          progresso: progresso is num ? progresso.toDouble().clamp(0.0, 1.0) : 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Alerta>> _carregarAlertas() async {
    try {
      final dados = await ApiService.instance.alertas();
      return dados.whereType<Map>().map((value) {
        return Alerta(
          id: value['id'],
          titulo: '${value['titulo'] ?? value['title'] ?? 'Alerta'}',
          descricao:
              '${value['descricao'] ?? value['description'] ?? value['mensagem'] ?? '-'}',
          local: '${value['local'] ?? value['localizacao'] ?? value['rota'] ?? '-'}',
          horario: '${value['horario'] ?? value['created_at'] ?? '-'}',
          status: '${value['status'] ?? value['gravidade'] ?? 'Informativo'}',
          icone: Icons.warning_amber_outlined,
          lido: value['lido'] == true ||
              value['read'] == true ||
              value['read_at'] != null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<double> _carregarSaldo() async {
    try {
      final pagamentos = await ApiService.instance.pagamentos();
      return pagamentos.whereType<Map>().fold<double>(0, (total, item) {
        final texto = '${item['valor'] ?? 0}'
            .trim()
            .replaceAll('R\$', '')
            .replaceAll(' ', '');
        final valor = texto.contains(',')
            ? double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.')) ?? 0
            : double.tryParse(texto) ?? 0;
        return total + valor;
      });
    } catch (_) {
      return 0;
    }
  }

  Future<double?> _carregarAvaliacao() async {
    try {
      final resumo = await ApiService.instance.resumoAvaliacoes();
      final media = resumo['media'] ?? resumo['average'] ?? resumo['nota_media'] ?? resumo['nota'];
      if (media is num) return media.toDouble();
      return double.tryParse('$media');
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _home();

      case 1:
        return const RemessasPage();

      case 2:
        return const MapaPage();

      case 3:
        return const TelaAlertas();

      case 4:
        return const CarteiraPage();

      default:
        return _home();
    }
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: _buildAppBar(),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _getBody()),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 18,

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryDark, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GeoSync",
                style: TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Área do cliente",
                style: TextStyle(
                  color: textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),

      actions: [
        _notificationButton(),
        const SizedBox(width: 8),
        _profileButton(),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _notificationButton() {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _changePage(3),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_outlined,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ),

            ValueListenableBuilder<int>(
              valueListenable: AppNotificationCenter.instance.unreadCount,
              builder: (context, unread, _) {
                if (unread <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton() {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          'Abrir perfil de ${AppSession.nome.isEmpty ? 'usuário' : AppSession.nome}',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilClientePage()),
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              AppSession.inicialNome,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.dashboard_outlined,
                label: "Início",
                index: 0,
              ),

              _navItem(
                icon: Icons.inventory_2_outlined,
                label: "Remessas",
                index: 1,
              ),

              _navItem(icon: Icons.map_outlined, label: "Mapa", index: 2),

              ValueListenableBuilder<int>(
                valueListenable: AppNotificationCenter.instance.unreadCount,
                builder: (context, unread, _) => _navItem(
                  icon: Icons.warning_amber_outlined,
                  label: "Alertas",
                  index: 3,
                  badge: unread > 0 ? unread : null,
                ),
              ),

              _navItem(
                icon: Icons.account_balance_wallet_outlined,
                label: "Carteira",
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    int? badge,
  }) {
    final selected = _currentIndex == index;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: () => _changePage(index),
      child: GestureDetector(
        onTap: () => _changePage(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      size: 23,
                      color: selected ? primary : const Color(0xFF94A3B8),
                    ),
                  ),

                  if (badge != null)
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            "$badge",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _home() {
    return RefreshIndicator(
      color: primary,

      onRefresh: () async {
        await _carregarResumo();
        unawaited(AppNotificationCenter.instance.refreshNow());
      },

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAUDAÇÃO
            _buildWelcome(),

            const SizedBox(height: 18),

            // BUSCA
            _buildSearch(),

            const SizedBox(height: 18),

            // RESUMO DA OPERAÇÃO
            _buildOverviewCard(),

            const SizedBox(height: 22),

            // AÇÕES RÁPIDAS
            _buildQuickActions(),

            const SizedBox(height: 28),

            const SizedBox(height: 12),

            _buildStatistics(),

            const SizedBox(height: 4),

            // MINI MAPA
            _buildMiniMap(),

            const SizedBox(height: 28),

            // ALERTAS
            _buildCriticalAlerts(),

            const SizedBox(height: 28),

            // REMESSAS
            _buildRecentShipments(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildWelcome() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_saudacao()}, ${AppSession.nome.isEmpty ? 'cliente' : AppSession.nome.split(' ').first} 👋",
                style: TextStyle(
                  color: textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Tudo sob controle?",
                style: TextStyle(
                  color: textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAFBF1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                "Online",
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUSCA
  // ============================================================

  Widget _buildSearch() {
    return GestureDetector(
      onTap: () {
        _changePage(1);
      },

      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 15),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),

        child: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFF94A3B8), size: 21),

            SizedBox(width: 11),

            Expanded(
              child: Text(
                "Buscar remessa, código ou cidade...",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),

            Icon(Icons.tune, color: Color(0xFF64748B), size: 19),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, Color(0xFF123C69), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.white70,
                    size: 19,
                  ),

                  SizedBox(width: 8),

                  Text(
                    "OPERAÇÃO HOJE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                _carregandoResumo ? "-" : "$_totalRemessas",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),

              const Text(
                "remessas em operação",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 15,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          "$_entregues entregues",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      "R\$ ${_saldoMovimentado.toStringAsFixed(2).replaceAll('.', ',')} movimentados",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AÇÕES RÁPIDAS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ações rápidas",
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickAction(
                icon: Icons.inventory_2_outlined,
                title: "Remessas",
                subtitle: "Consultar",
                color: primary,
                onTap: () => _changePage(1),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _quickAction(
                icon: Icons.map_outlined,
                title: "Mapa",
                subtitle: "Ver frota",
                color: const Color(0xFF7C3AED),
                onTap: () => _changePage(2),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: AppNotificationCenter.instance.unreadCount,
                builder: (context, unread, _) => _quickAction(
                  icon: Icons.warning_amber_outlined,
                  title: "Alertas",
                  subtitle: unread > 0 ? "$unread pendente${unread == 1 ? '' : 's'}" : "Em dia",
                  color: const Color(0xFFEF4444),
                  onTap: () => _changePage(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(icon, color: color, size: 19),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(subtitle, style: TextStyle(color: textLight, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ESTATÍSTICAS
  // ============================================================

  Widget _buildStatistics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      mainAxisSpacing: 12,
      crossAxisSpacing: 12,

      childAspectRatio: 1.32,

      children: [
        _statTile(
          icon: Icons.local_shipping_outlined,
          valor: _carregandoResumo ? "-" : "$_emTransito",
          legenda: "Em trânsito",
          cor: primary,
        ),
        _statTile(
          icon: Icons.check_circle_outline,
          valor: _carregandoResumo ? "-" : "$_entregues",
          legenda: "Entregues",
          cor: const Color(0xFF16A34A),
        ),
        _statTile(
          icon: Icons.warning_amber_outlined,
          valor: _carregandoResumo ? "-" : "$_comOcorrencia",
          legenda: "Com ocorrência",
          cor: const Color(0xFFEF4444),
        ),
        _statTile(
          icon: Icons.star_outline,
          valor: _avaliacaoMedia == null
              ? "-"
              : _avaliacaoMedia!.toStringAsFixed(1),
          legenda: "Avaliação média",
          cor: const Color(0xFFE58A00),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String valor,
    required String legenda,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cor, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(legenda, style: TextStyle(color: textLight, fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================
  // MINI MAPA
  // ============================================================

  Widget _buildMiniMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Localização da frota",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    "Acompanhe os veículos em trânsito",
                    style: TextStyle(color: textLight, fontSize: 12),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(2),

              child: const Text(
                "Abrir mapa →",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => _changePage(2),

          child: Container(
            height: 190,
            width: double.infinity,

            clipBehavior: Clip.antiAlias,

            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),

            child: Stack(
              children: [
                // Fundo simulando mapa
                CustomPaint(size: Size.infinite, painter: _MapPatternPainter()),

                // Estradas
                Positioned(
                  left: -30,
                  top: 95,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 420,
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

                Positioned(
                  left: 80,
                  top: -30,
                  child: Transform.rotate(
                    angle: 0.9,
                    child: Container(
                      width: 260,
                      height: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Marcadores
                _mapMarker(left: 65, top: 55),

                _mapMarker(left: 170, top: 105),

                _mapMarker(left: 270, top: 45),

                _mapMarker(left: 315, top: 125),

                // Card inferior
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: primary,
                          size: 18,
                        ),

                        SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            _carregandoResumo
                                ? "Carregando frota..."
                                : "$_emTransito remessa${_emTransito == 1 ? '' : 's'} em trânsito",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        SizedBox(width: 8),

                        Icon(
                          Icons.arrow_forward,
                          color: textLight,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapMarker({required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,

      child: Container(
        width: 31,
        height: 31,

        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 8),
          ],
        ),

        child: const Icon(
          Icons.local_shipping_outlined,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  // ============================================================
  // ALERTAS
  // ============================================================

  Widget _buildCriticalAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,

              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E9),
                borderRadius: BorderRadius.circular(11),
              ),

              child: const Icon(
                Icons.warning_amber_outlined,
                color: Color(0xFFEF4444),
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Atenção necessária",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  Text(
                    _pendentesAlertas > 0
                        ? "Existem $_pendentesAlertas ocorrência${_pendentesAlertas == 1 ? '' : 's'} pendente${_pendentesAlertas == 1 ? '' : 's'}"
                        : "Nenhuma ocorrência pendente",
                    style: TextStyle(color: textLight, fontSize: 11),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(3),

              child: const Text(
                "Ver tudo",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        if (_carregandoResumo)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_alertasDestaque.isEmpty)
          _buildAlertasVazio()
        else
          for (final entry in _alertasDestaque.asMap().entries) ...[
            if (entry.key > 0) const SizedBox(height: 10),
            _buildAlert(
              title: entry.value.titulo,
              code: entry.value.local,
              time: entry.value.horario,
              severity: entry.value.status.toUpperCase(),
              color: _corAlerta(entry.value.status),
              route: entry.value.descricao,
            ),
          ],
      ],
    );
  }

  int get _pendentesAlertas => _alertas.where((a) => !a.lido).length;

  List<Alerta> get _alertasDestaque {
    final copia = List<Alerta>.from(_alertas)
      ..sort((a, b) => (a.lido ? 1 : 0).compareTo(b.lido ? 1 : 0));
    return copia.take(2).toList();
  }

  Color _corAlerta(String status) {
    switch (status) {
      case "Crítico":
        return const Color(0xFFEF4444);
      case "Atenção":
        return const Color(0xFFF59E0B);
      default:
        return primary;
    }
  }

  Widget _buildAlertasVazio() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    ),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline, color: textLight, size: 30),
        const SizedBox(height: 8),
        Text("Tudo certo por aqui", style: TextStyle(color: textLight, fontSize: 12)),
      ],
    ),
  );

  Widget _buildAlert({
    required String title,
    required String code,
    required String time,
    required String severity,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => _changePage(3),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,

                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Icon(Icons.warning_amber_outlined, color: color, size: 19),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),

                    child: Text(
                      severity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.route_outlined,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    route,
                    style: TextStyle(color: textLight, fontSize: 10),
                  ),
                ),

                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REMESSAS
  // ============================================================

  Widget _buildRecentShipments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remessas recentes",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    "Últimas movimentações",
                    style: TextStyle(color: textLight, fontSize: 12),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _changePage(1),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Row(
                  children: [
                    Text(
                      "Ver todas",
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(width: 4),

                    Icon(Icons.arrow_forward, color: primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        if (_carregandoResumo)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_remessas.isEmpty)
          _buildAlertasVazio()
        else
          for (final entry in _remessas.take(3).toList().asMap().entries) ...[
            if (entry.key > 0) const SizedBox(height: 10),
            _buildShipment(
              code: entry.value.codigo,
              route: "${entry.value.origem} → ${entry.value.destino}",
              type: entry.value.tipo,
              status: entry.value.status,
              progress: entry.value.progresso,
              eta: entry.value.eta,
              statusColor: _corRemessa(entry.value.status),
            ),
          ],
      ],
    );
  }

  Color _corRemessa(String status) {
    switch (status) {
      case "Entregue":
        return const Color(0xFF16A34A);
      case "Atrasado":
      case "Alerta":
        return const Color(0xFFEF4444);
      default:
        return primary;
    }
  }

  Widget _buildShipment({
    required String code,
    required String route,
    required String type,
    required String status,
    required double progress,
    required String eta,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  Icons.local_shipping_outlined,
                  color: statusColor,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textLight, fontSize: 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                color: Color(0xFF94A3B8),
                size: 15,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.schedule_outlined,
                color: Color(0xFF94A3B8),
                size: 14,
              ),

              const SizedBox(width: 4),

              Text(
                eta,
                style: TextStyle(
                  color: status == "Atrasado"
                      ? const Color(0xFFEF4444)
                      : textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,

              backgroundColor: const Color(0xFFE9EDF3),

              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Text(
                "Progresso da entrega",
                style: TextStyle(color: textLight, fontSize: 9),
              ),

              const Spacer(),

              Text(
                "${(progress * 100).round()}%",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAINEL DE MAPA SIMPLIFICADO
// ============================================================

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE4ED)
      ..strokeWidth = 1;

    const spacing = 35.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
