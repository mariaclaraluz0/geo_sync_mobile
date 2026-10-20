import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/mapa_page.dart';
import 'package:mobile/suporte_page.dart';
import 'package:mobile/widgets/data_state_widgets.dart';

class RemessasPage extends StatefulWidget {
  const RemessasPage({super.key});

  @override
  State<RemessasPage> createState() => _RemessasPageState();
}

class _RemessasPageState extends State<RemessasPage> {
  final TextEditingController _searchController = TextEditingController();

  String filtroSelecionado = "Todas";

  String _normalizarTexto(String texto) => texto
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  final List<Remessa> remessas = [];
  bool _carregando = true;
  String? _erro;

  List<Remessa> get remessasFiltradas {
    final pesquisa = _normalizarTexto(_searchController.text);
    final filtro = _normalizarTexto(filtroSelecionado);

    return remessas.where((remessa) {
      final status = _normalizarTexto(remessa.status);
      final correspondeFiltro =
          filtro == 'todas' ||
          (filtro == 'transito' &&
              (status.contains('transito') || status == 'em rota')) ||
          (filtro == 'entregue' && status == 'entregue') ||
          (filtro == 'atrasado' && status == 'atrasado') ||
          (filtro == 'alerta' && status == 'alerta');

      final correspondeBusca =
          pesquisa.isEmpty ||
          _normalizarTexto(remessa.codigo).contains(pesquisa) ||
          _normalizarTexto(remessa.origem).contains(pesquisa) ||
          _normalizarTexto(remessa.destino).contains(pesquisa) ||
          _normalizarTexto(remessa.tipo).contains(pesquisa);

      return correspondeFiltro && correspondeBusca;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
    _carregarRemessas();
  }

  Future<void> _carregarRemessas() async {
    if (mounted) {
      setState(() {
        _carregando = remessas.isEmpty;
        _erro = null;
      });
    }
    try {
      // A listagem do cliente é diferente da fila sincronizada do motorista.
      final resposta = await ApiService.instance.remessasAutorizadas();
      final dados = resposta.whereType<Map>().map(_remessaFromApi).toList();
      if (!mounted) return;
      setState(() {
        remessas
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível atualizar suas remessas.';
        _carregando = false;
      });
    }
  }

  Remessa _remessaFromApi(Map value) {
    final progresso = value['progresso'] ?? value['progress'] ?? 0;
    return Remessa(
      id: value['id'] ?? value['remessa_id'],
      codigo: '${value['codigo'] ?? value['code'] ?? value['id'] ?? '-'}',
      status: '${value['status'] ?? value['situacao'] ?? 'Aguardando coleta'}',
      origem: '${value['origem'] ?? value['origin'] ?? '-'}',
      destino: '${value['destino'] ?? value['destination'] ?? '-'}',
      tipo: '${value['tipo'] ?? value['tipo_carga'] ?? value['cargo'] ?? '-'}',
      peso: '${value['peso'] ?? value['weight'] ?? '-'}',
      eta: _formatarData(
        value['previsao_entrega'] ??
            value['eta'] ??
            value['estimated_delivery_at'],
      ),
      progresso: progresso is num ? progresso.toDouble().clamp(0.0, 1.0) : 0,
      atualizadoEm: DateTime.tryParse(
        '${value['updated_at'] ?? value['updatedAt'] ?? ''}',
      ),
      ultimoLocal:
          '${value['local_atual'] ?? value['localizacao_atual'] ?? value['ultimo_local'] ?? ''}',
    );
  }

  String _formatarData(dynamic valor) {
    final data = DateTime.tryParse('$valor');
    if (data == null) {
      return valor == null || '$valor'.trim().isEmpty || valor == '-'
          ? 'Não informada pela API'
          : '$valor';
    }
    final local = data.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} às ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int quantidadePorStatus(String status) {
    if (status == "Todas") {
      return remessas.length;
    }

    if (status == "Trânsito") {
      return remessas
          .where(
            (r) =>
                _normalizarTexto(r.status).contains('transito') ||
                _normalizarTexto(r.status) == 'em rota',
          )
          .length;
    }

    final alvo = switch (status) {
      'Entregue' => 'entregue',
      'Atrasado' => 'atrasado',
      'Alerta' => 'alerta',
      _ => _normalizarTexto(status),
    };
    return remessas.where((r) => _normalizarTexto(r.status) == alvo).length;
  }

  void limparBusca() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void limparFiltrosEBusca() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => filtroSelecionado = 'Todas');
  }

  void abrirDetalhes(Remessa remessa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DetalhesRemessa(remessa: remessa);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fonteAmpliada = MediaQuery.textScalerOf(context).scale(14) > 22;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GeoSync",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            Text(
              "Minhas Remessas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Atualizar",
            onPressed: () async {
              await _carregarRemessas();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _erro == null
                        ? 'Lista atualizada.'
                        : 'Falha ao atualizar. Os dados anteriores continuam visíveis.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(CupertinoIcons.arrow_clockwise),
          ),
        ],
      ),

      body: Column(
        children: [
          // ============================================================
          // ÁREA SUPERIOR
          // ============================================================
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              16,
              fonteAmpliada ? 8 : 18,
              16,
              fonteAmpliada ? 8 : 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0B2A4A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // BUSCA
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Buscar ID, cidade ou carga...",
                      labelText: 'Buscar remessas',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Color(0xFF0B2A4A),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: limparBusca,
                              icon: const Icon(CupertinoIcons.xmark),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: fonteAmpliada ? 8 : 18),

                // RESUMO
                Row(
                  children: [
                    Expanded(
                      child: ResumoItem(
                        icone: CupertinoIcons.cube_box,
                        titulo: "Total",
                        valor: "${remessas.length}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: CupertinoIcons.cube_box,
                        titulo: "Em rota",
                        valor: "${quantidadePorStatus("Trânsito")}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: CupertinoIcons.checkmark_circle,
                        titulo: "Entregues",
                        valor: "${quantidadePorStatus("Entregue")}",
                      ),
                    ),
                    Expanded(
                      child: ResumoItem(
                        icone: CupertinoIcons.exclamationmark_triangle,
                        titulo: "Alertas",
                        valor:
                            "${quantidadePorStatus("Alerta") + quantidadePorStatus("Atrasado")}",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_erro != null && remessas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DataFreshnessBanner(
                message:
                    'Não foi possível atualizar. Exibindo os últimos dados carregados.',
                onRetry: _carregarRemessas,
              ),
            ),

          const SizedBox(height: 16),

          // ============================================================
          // FILTROS
          // ============================================================
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FiltroChip(
                  texto: "Todas",
                  selecionado: filtroSelecionado == "Todas",
                  quantidade: quantidadePorStatus("Todas"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Todas";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Trânsito",
                  selecionado: filtroSelecionado == "Trânsito",
                  quantidade: quantidadePorStatus("Trânsito"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Trânsito";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Entregues",
                  selecionado: filtroSelecionado == "Entregue",
                  quantidade: quantidadePorStatus("Entregue"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Entregue";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Atrasadas",
                  selecionado: filtroSelecionado == "Atrasado",
                  quantidade: quantidadePorStatus("Atrasado"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Atrasado";
                    });
                  },
                ),
                FiltroChip(
                  texto: "Alertas",
                  selecionado: filtroSelecionado == "Alerta",
                  quantidade: quantidadePorStatus("Alerta"),
                  onTap: () {
                    setState(() {
                      filtroSelecionado = "Alerta";
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ============================================================
          // RESULTADO
          // ============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  "${remessasFiltradas.length} remessa(s)",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                if (filtroSelecionado != "Todas" ||
                    _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: limparFiltrosEBusca,
                    child: const Text("Limpar busca e filtros"),
                  ),
              ],
            ),
          ),

          // ============================================================
          // LISTA
          // ============================================================
          Expanded(
            child: _carregando && remessas.isEmpty
                ? const DataStatePanel(
                    kind: DataStateKind.loading,
                    title: 'Carregando remessas',
                    message: 'Buscando as remessas autorizadas para sua conta.',
                  )
                : _erro != null && remessas.isEmpty
                ? _buildErro()
                : remessasFiltradas.isEmpty
                ? EstadoVazio(
                    temRemessas: remessas.isNotEmpty,
                    onLimpar: limparFiltrosEBusca,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
                    itemCount: remessasFiltradas.length,
                    itemBuilder: (context, index) {
                      final remessa = remessasFiltradas[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RemessaCard(
                          remessa: remessa,
                          onTap: () => abrirDetalhes(remessa),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() => DataStatePanel(
    kind: DataStateKind.error,
    title: 'Não foi possível carregar as remessas',
    message: _erro ?? 'Confira sua conexão e tente novamente.',
    onRetry: _carregarRemessas,
  );
}

// ============================================================================
// MODELO
// ============================================================================

class Remessa {
  final Object? id;
  final String codigo;
  final String status;
  final String origem;
  final String destino;
  final String tipo;
  final String peso;
  final String eta;
  final double progresso;
  final DateTime? atualizadoEm;
  final String ultimoLocal;

  bool favorita;

  Remessa({
    this.id,
    required this.codigo,
    required this.status,
    required this.origem,
    required this.destino,
    required this.tipo,
    required this.peso,
    required this.eta,
    required this.progresso,
    this.atualizadoEm,
    this.ultimoLocal = '',
    this.favorita = false,
  });
}

// ============================================================================
// RESUMO
// ============================================================================

class ResumoItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const ResumoItem({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

// ============================================================================
// FILTRO
// ============================================================================

class FiltroChip extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final int quantidade;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.quantidade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      excludeSemantics: true,
      label: '$texto, $quantidade ${quantidade == 1 ? 'remessa' : 'remessas'}',
      hint: selecionado ? 'Filtro selecionado' : 'Aplicar filtro',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? const Color(0xFF0B2A4A) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selecionado
                  ? const Color(0xFF0B2A4A)
                  : Colors.grey.shade300,
            ),
            boxShadow: [
              if (selecionado)
                BoxShadow(
                  color: const Color(0xFF0B2A4A).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: selecionado ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selecionado
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$quantidade",
                  style: TextStyle(
                    color: selecionado ? Colors.white : const Color(0xFF475569),
                    fontSize: 11,
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
}

// ============================================================================
// CARD DA REMESSA
// ============================================================================

class RemessaCard extends StatefulWidget {
  final Remessa remessa;
  final VoidCallback onTap;

  const RemessaCard({super.key, required this.remessa, required this.onTap});

  @override
  State<RemessaCard> createState() => _RemessaCardState();
}

class _RemessaCardState extends State<RemessaCard> {
  Color get statusColor {
    switch (widget.remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Atrasado":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData get statusIcon {
    switch (widget.remessa.status) {
      case "Entregue":
        return CupertinoIcons.checkmark_circle;

      case "Atrasado":
        return CupertinoIcons.clock;

      case "Alerta":
        return CupertinoIcons.exclamationmark_triangle;

      default:
        return CupertinoIcons.cube_box;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOPO
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(CupertinoIcons.cube_box, color: statusColor),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.remessa.codigo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.remessa.tipo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        widget.remessa.favorita = !widget.remessa.favorita;
                      });
                    },
                    icon: Icon(
                      widget.remessa.favorita
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: widget.remessa.favorita
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      widget.remessa.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ROTA
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        CupertinoIcons.largecircle_fill_circle,
                        size: 17,
                        color: Color(0xFF2563EB),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        color: Colors.grey.shade300,
                      ),
                      const Icon(
                        CupertinoIcons.placemark,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Origem",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          widget.remessa.origem,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Destino",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          widget.remessa.destino,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ETA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "ETA",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.remessa.eta,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // PROGRESSO
              Row(
                children: [
                  Text(
                    "Progresso da entrega",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    "${(widget.remessa.progresso * 100).toInt()}%",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.remessa.progresso,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),

              const SizedBox(height: 14),

              // RODAPÉ
              Row(
                children: [
                  Icon(
                    CupertinoIcons.gauge,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.remessa.peso,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  const Text(
                    "Ver detalhes",
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ESTADO VAZIO
// ============================================================================

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.temRemessas,
    required this.onLimpar,
  });

  final bool temRemessas;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 300;
        final iconSize = compact ? 64.0 : 90.0;
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2A4A).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.cube_box,
                    size: compact ? 32 : 42,
                    color: Color(0xFF0B2A4A),
                  ),
                ),
                SizedBox(height: compact ? 10 : 18),
                Text(
                  temRemessas
                      ? "Nenhum resultado encontrado"
                      : "Nenhuma remessa cadastrada",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  temRemessas
                      ? "Ajuste a busca ou os filtros para ver outras remessas."
                      : "Suas remessas aparecerão aqui quando forem cadastradas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (temRemessas) ...[
                  SizedBox(height: compact ? 4 : 10),
                  OutlinedButton.icon(
                    onPressed: onLimpar,
                    icon: const Icon(CupertinoIcons.clear),
                    label: const Text('Limpar busca e filtros'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// DETALHES
// ============================================================================

class DetalhesRemessa extends StatefulWidget {
  final Remessa remessa;

  const DetalhesRemessa({super.key, required this.remessa});

  @override
  State<DetalhesRemessa> createState() => _DetalhesRemessaState();
}

class _DetalhesRemessaState extends State<DetalhesRemessa> {
  late final Future<List<dynamic>> _historico = widget.remessa.id == null
      ? Future.value(const [])
      : ApiService.instance.historicoRemessa(widget.remessa.id!);

  Remessa get remessa => widget.remessa;

  Color get statusColor {
    switch (remessa.status) {
      case "Entregue":
        return const Color(0xFF16A34A);

      case "Atrasado":
        return const Color(0xFFF59E0B);

      case "Alerta":
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CupertinoIcons.cube_box,
                      color: statusColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remessa.codigo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          remessa.tipo,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Status da remessa",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.circle_fill,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      remessa.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Próximo passo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              _proximoPasso(),
              const SizedBox(height: 22),
              const Text(
                'Histórico de acompanhamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _historico,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final eventos = snapshot.data ?? const <dynamic>[];
                  if (eventos.isEmpty) {
                    return _eventoTimeline(
                      remessa.status,
                      remessa.ultimoLocal.isEmpty
                          ? 'Local não informado pela API'
                          : remessa.ultimoLocal,
                      remessa.atualizadoEm,
                      snapshot.hasError
                          ? 'Não foi possível carregar o histórico.'
                          : 'Último status recebido da API.',
                    );
                  }
                  final ordenados = eventos.whereType<Map>().toList()
                    ..sort((a, b) {
                      final dataA = DateTime.tryParse(
                        '${a['data_hora'] ?? a['ocorrida_em'] ?? a['created_at'] ?? a['updated_at'] ?? ''}',
                      );
                      final dataB = DateTime.tryParse(
                        '${b['data_hora'] ?? b['ocorrida_em'] ?? b['created_at'] ?? b['updated_at'] ?? ''}',
                      );
                      if (dataA == null) return 1;
                      if (dataB == null) return -1;
                      return dataB.compareTo(dataA);
                    });
                  return Column(
                    children: ordenados
                        .map(
                          (evento) => _eventoTimeline(
                            '${evento['status'] ?? evento['titulo'] ?? evento['evento'] ?? evento['tipo'] ?? 'Atualização'}',
                            '${evento['local'] ?? evento['localizacao'] ?? evento['endereco'] ?? 'Local não informado pela API'}',
                            DateTime.tryParse(
                              '${evento['data_hora'] ?? evento['ocorrida_em'] ?? evento['created_at'] ?? evento['updated_at'] ?? ''}',
                            ),
                            '${evento['descricao'] ?? evento['mensagem'] ?? ''}',
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                "Informações da carga",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),

              const SizedBox(height: 12),

              InfoDetalhe(
                icone: CupertinoIcons.square_stack_3d_up,
                titulo: "Tipo de carga",
                valor: remessa.tipo,
              ),

              InfoDetalhe(
                icone: CupertinoIcons.gauge,
                titulo: "Peso",
                valor: remessa.peso,
              ),

              InfoDetalhe(
                icone: CupertinoIcons.clock,
                titulo: "Previsão",
                valor: remessa.eta,
              ),

              const SizedBox(height: 20),

              const Text(
                "Rota",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),

              const SizedBox(height: 15),

              RotaDetalhe(
                icone: CupertinoIcons.largecircle_fill_circle,
                titulo: "Origem",
                valor: remessa.origem,
                cor: Colors.blue,
              ),

              RotaDetalhe(
                icone: CupertinoIcons.placemark,
                titulo: "Destino",
                valor: remessa.destino,
                cor: Colors.red,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: remessa.id == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MapaPage()),
                          );
                        },
                  icon: const Icon(CupertinoIcons.map),
                  label: const Text(
                    "Ver no mapa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SuportePage(referenciaRemessa: remessa.codigo),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: Text(
                    remessa.status.toLowerCase().contains('atras') ||
                            remessa.status.toLowerCase().contains('alerta')
                        ? 'Precisa de ajuda? Fale com o suporte'
                        : 'Ajuda e suporte',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _proximoPasso() {
    final status = remessa.status.toLowerCase();
    final mensagem = status.contains('entregue')
        ? 'Remessa entregue. Consulte o histórico e o comprovante.'
        : status.contains('alerta') || status.contains('atras')
        ? 'Há um problema ou atraso. Fale com o suporte para receber ajuda.'
        : status.contains('rota') ||
              status.contains('trânsito') ||
              status.contains('transito')
        ? 'A remessa está em transporte. Acompanhe esta tela para novas atualizações.'
        : 'Aguarde a coleta e acompanhe esta tela para ver novas atualizações.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(mensagem),
    );
  }

  Widget _eventoTimeline(
    String titulo,
    String local,
    DateTime? quando,
    String detalhe,
  ) {
    final data = quando == null
        ? 'Data e hora não informadas pela API'
        : '${quando.toLocal().day.toString().padLeft(2, '0')}/${quando.toLocal().month.toString().padLeft(2, '0')}/${quando.toLocal().year} às ${quando.toLocal().hour.toString().padLeft(2, '0')}:${quando.toLocal().minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 12, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  data,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(local, style: const TextStyle(fontSize: 13)),
                if (detalhe.trim().isNotEmpty)
                  Text(
                    detalhe,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFORMAÇÃO
// ============================================================================

class InfoDetalhe extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const InfoDetalhe({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, size: 19, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Text(
            titulo,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ROTA
// ============================================================================

class RotaDetalhe extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color cor;

  const RotaDetalhe({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
