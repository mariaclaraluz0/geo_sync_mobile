import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notification_center.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: TelaAlertas()),
  );
}

// ============================================================
// MODELO DE ALERTA
// ============================================================

class Alerta {
  final Object? id;
  final String titulo;
  final String descricao;
  final String local;
  final String horario;
  final String status;
  final IconData icone;
  bool lido;

  Alerta({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.local,
    required this.horario,
    required this.status,
    required this.icone,
    this.lido = false,
  });
}

// ============================================================
// TELA DE ALERTAS
// ============================================================

class TelaAlertas extends StatefulWidget {
  const TelaAlertas({super.key});

  @override
  State<TelaAlertas> createState() => _TelaAlertasState();
}

class _TelaAlertasState extends State<TelaAlertas> {
  // ============================================================
  // PALETA GEOSYNC
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);

  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF718096);

  static const Color border = Color(0xFFE8ECF3);

  Color get surface => Theme.of(context).colorScheme.surface;

  // ============================================================
  // FILTRO ATUAL
  // ============================================================

  String filtroSelecionado = "Todos";

  // ============================================================
  // LISTA DE ALERTAS
  // ============================================================

  final List<Alerta> alertas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAlertas();
  }

  Future<void> _carregarAlertas({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final resposta = await ApiService.instance.alertas(
        forceRefresh: forceRefresh,
      );
      final dados = resposta.whereType<Map>().map(_alertaFromApi).toList();
      if (!mounted) return;
      setState(() {
        alertas
          ..clear()
          ..addAll(dados);
        _carregando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.message;
        _carregando = false;
      });
    }
  }

  Alerta _alertaFromApi(Map value) => Alerta(
    id: value['id'],
    titulo: '${value['titulo'] ?? value['title'] ?? 'Alerta'}',
    descricao:
        '${value['descricao'] ?? value['description'] ?? value['mensagem'] ?? '-'}',
    local: '${value['local'] ?? value['localizacao'] ?? '-'}',
    horario: '${value['horario'] ?? value['created_at'] ?? '-'}',
    status: '${value['status'] ?? value['gravidade'] ?? 'Informativo'}',
    icone: Icons.warning_amber_outlined,
    lido: value['lido'] == true || value['read'] == true || value['read_at'] != null,
  );

  int get _quantidadeNaoLidos => alertas.where((a) => !a.lido).length;

  Future<void> _marcarComoLido(Alerta alerta) async {
    if (alerta.lido || alerta.id == null) return;
    setState(() => alerta.lido = true);
    try {
      await ApiService.instance.atualizarAlerta(alerta.id!, {'lido': true});
    } on ApiException catch (_) {
      // Mantém como lido localmente mesmo se o backend não confirmar,
      // para não reabrir um alerta que o usuário já visualizou.
    } finally {
      unawaited(AppNotificationCenter.instance.refreshNow());
    }
  }

  Future<void> _marcarTodosComoLidos() async {
    final pendentes = alertas.where((a) => !a.lido).toList();
    if (pendentes.isEmpty) return;
    setState(() {
      for (final alerta in pendentes) {
        alerta.lido = true;
      }
    });
    await Future.wait([
      for (final alerta in pendentes)
        if (alerta.id != null)
          ApiService.instance
              .atualizarAlerta(alerta.id!, {'lido': true})
              .catchError((_) => <String, dynamic>{}),
    ]);
    unawaited(AppNotificationCenter.instance.refreshNow());
  }

  // ============================================================
  // FILTRAR ALERTAS
  // ============================================================

  List<Alerta> get alertasFiltrados {
    if (filtroSelecionado == "Todos") {
      return alertas;
    }

    return alertas
        .where((alerta) => alerta.status == filtroSelecionado)
        .toList();
  }

  // ============================================================
  // CONTADORES
  // ============================================================

  int get quantidadeCriticos {
    return alertas.where((alerta) => alerta.status == "Crítico").length;
  }

  int get quantidadeAtencao {
    return alertas.where((alerta) => alerta.status == "Atenção").length;
  }

  int get quantidadeInformativos {
    return alertas.where((alerta) => alerta.status == "Informativo").length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erro != null
                  ? _buildErro()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                      children: [
                        const SizedBox(height: 20),

                        _buildResumo(),

                        const SizedBox(height: 24),

                        _buildTituloSecao(),

                        const SizedBox(height: 12),

                        _buildFiltros(),

                        const SizedBox(height: 18),

                        if (alertasFiltrados.isEmpty)
                          _buildEstadoVazio()
                        else
                          ...alertasFiltrados.map(
                            (alerta) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildAlertaCard(alerta),
                            ),
                          ),
                      ],
                    ),
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
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // ÍCONE
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (_quantidadeNaoLidos > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryDark, width: 2),
                    ),
                    child: Text(
                      '$_quantidadeNaoLidos',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // TÍTULO
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Alertas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Acompanhe sua frota em tempo real",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // MARCAR TODOS COMO LIDOS
          if (_quantidadeNaoLidos > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _marcarTodosComoLidos,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.done_all,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // BOTÃO ATUALIZAR
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await _carregarAlertas(forceRefresh: true);
                if (!mounted) return;
                _mostrarMensagem("Alertas atualizados.");
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_erro!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _carregarAlertas(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildResumo() {
    return Row(
      children: [
        Expanded(
          child: _buildResumoCard(
            titulo: "Total",
            valor: alertas.length.toString(),
            icone: Icons.notifications_outlined,
            cor: primary,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildResumoCard(
            titulo: "Críticos",
            valor: quantidadeCriticos.toString(),
            icone: Icons.warning_amber_outlined,
            cor: const Color(0xFFD64545),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildResumoCard(
            titulo: "Atenção",
            valor: quantidadeAtencao.toString(),
            icone: Icons.priority_high,
            cor: const Color(0xFFE58A00),
          ),
        ),
      ],
    );
  }

  Widget _buildResumoCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 18),
          ),

          const SizedBox(height: 10),

          Text(
            valor,
            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            titulo,
            style: const TextStyle(
              color: textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TÍTULO DA SEÇÃO
  // ============================================================

  Widget _buildTituloSecao() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Central de alertas",
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 3),
        Text(
          "Filtre os eventos para encontrar rapidamente o que precisa.",
          style: TextStyle(color: textLight, fontSize: 12),
        ),
      ],
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFiltro(texto: "Todos", quantidade: alertas.length),

          _buildFiltro(texto: "Crítico", quantidade: quantidadeCriticos),

          _buildFiltro(texto: "Atenção", quantidade: quantidadeAtencao),

          _buildFiltro(
            texto: "Informativo",
            quantidade: quantidadeInformativos,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltro({required String texto, required int quantidade}) {
    final bool selecionado = filtroSelecionado == texto;

    final Color cor = _corStatus(texto);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            filtroSelecionado = texto;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? cor : surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selecionado ? cor : border),
            boxShadow: selecionado
                ? [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: selecionado ? Colors.white : textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),

              const SizedBox(width: 7),

              Container(
                constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selecionado
                      ? Colors.white.withValues(alpha: 0.20)
                      : cor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  quantidade.toString(),
                  style: TextStyle(
                    color: selecionado ? Colors.white : cor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE ALERTA
  // ============================================================

  Widget _buildAlertaCard(Alerta alerta) {
    final Color cor = _corStatus(alerta.status);
    final bool naoLido = !alerta.lido;

    return Container(
      decoration: BoxDecoration(
        color: naoLido ? cor.withValues(alpha: 0.045) : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: naoLido ? cor.withValues(alpha: 0.35) : border),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _marcarComoLido(alerta);
            _mostrarDetalhes(alerta);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // ÍCONE
                    // ==================================================
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(alerta.icone, color: cor, size: 25),
                    ),

                    const SizedBox(width: 13),

                    // ==================================================
                    // TÍTULO E DESCRIÇÃO
                    // ==================================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (naoLido)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 7),
                                  decoration: BoxDecoration(
                                    color: cor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  alerta.titulo,
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 15,
                                    fontWeight: naoLido
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),

                              Text(
                                alerta.horario,
                                style: const TextStyle(
                                  color: textLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Text(
                            alerta.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textLight,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // ==================================================
                // LINHA INFERIOR
                // ==================================================
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: cor,
                        size: 17,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        alerta.local,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        alerta.status,
                        style: TextStyle(
                          color: cor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 45),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_outlined, color: textLight, size: 52),

          SizedBox(height: 14),

          Text(
            "Nenhum alerta encontrado",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Não existem alertas para o filtro selecionado.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COR DO STATUS
  // ============================================================

  Color _corStatus(String status) {
    switch (status) {
      case "Crítico":
        return const Color(0xFFD64545);

      case "Atenção":
        return const Color(0xFFE58A00);

      case "Informativo":
        return primary;

      case "Todos":
        return primaryDark;

      default:
        return primary;
    }
  }

  // ============================================================
  // DETALHES DO ALERTA
  // ============================================================

  void _mostrarDetalhes(Alerta alerta) {
    final Color cor = _corStatus(alerta.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(alerta.icone, color: cor),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      alerta.titulo,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildDetalhe(
                Icons.description_outlined,
                "Descrição",
                alerta.descricao,
              ),

              _buildDetalhe(
                Icons.location_on_outlined,
                "Localização",
                alerta.local,
              ),

              _buildDetalhe(
                Icons.access_time_outlined,
                "Horário",
                alerta.horario,
              ),

              _buildDetalhe(Icons.flag_outlined, "Status", alerta.status),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalhe(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: primary, size: 20),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  valor,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
  // SNACKBAR
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
