import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notification_center.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:mobile/motorista/avisos_motorista_page.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:mobile/motorista/documentos_page.dart';
import 'package:mobile/motorista/entrega_page.dart';
import 'package:mobile/motorista/mapa_motorista_page.dart';
import 'package:mobile/motorista/veiculo_motorista_page.dart';
import 'package:mobile/sync/background_location_service.dart';
import 'package:mobile/widgets/responsive_content.dart';

class MotoristaDashboard extends StatefulWidget {
  const MotoristaDashboard({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MotoristaDashboard> createState() => _MotoristaDashboardState();
}

class _MotoristaDashboardState extends State<MotoristaDashboard> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color primary = Color(0xFF0C46FF);
  static const Color primaryDark = Color(0xFF0B2A4A);
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(context).colorScheme.surface;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textLight => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get border => Theme.of(context).colorScheme.outlineVariant;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // ============================================================
  // ESTADO
  // ============================================================

  late int _currentIndex;
  List<Remessa> _remessas = [];
  Map<String, dynamic> _usuario = {};
  List<Map<String, dynamic>> _documentos = [];
  double? _avaliacaoMedia;
  bool _carregandoResumo = true;
  bool _falhaCarregamentoResumo = false;
  String? _erroCarregamentoResumo;
  bool _carregandoPerfil = true;
  bool _falhaCarregamentoPerfil = false;
  String? _erroCarregamentoPerfil;
  Timer? _novasEntregasTimer;
  int? _disponiveisConhecidas;

  String _normalizarStatus(Object? valor) {
    if (valor is Map) {
      valor = valor['nome'] ?? valor['name'] ?? valor['status'];
    }
    return '$valor'
        .trim()
        .toLowerCase()
        .replaceAll('\u00c3\u00a1', 'a')
        .replaceAll('\u00c3\u00a3', 'a')
        .replaceAll('\u00c3\u00a2', 'a')
        .replaceAll('\u00c3\u00a9', 'e')
        .replaceAll('\u00c3\u00aa', 'e')
        .replaceAll('\u00c3\u00ad', 'i')
        .replaceAll('\u00c3\u00b3', 'o')
        .replaceAll('\u00c3\u00b4', 'o')
        .replaceAll('\u00c3\u00b5', 'o')
        .replaceAll('\u00c3\u00ba', 'u')
        .replaceAll('\u00c3\u00a7', 'c')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00e7', 'c')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
  }

  bool _remessaEntregue(Remessa remessa) => {
    'entregue',
    'delivered',
    'completed',
    'concluida',
    'finalizada',
  }.contains(_normalizarStatus(remessa.status));

  bool _remessaCancelada(Remessa remessa) => {
    'cancelada',
    'cancelado',
    'cancelled',
    'canceled',
  }.contains(_normalizarStatus(remessa.status));

  bool _remessaEmRota(Remessa remessa) => {
    'em rota',
    'em transito',
    'em deslocamento',
    'saiu para entrega',
    'in transit',
    'in progress',
    'out for delivery',
  }.contains(_normalizarStatus(remessa.status));

  bool _remessaComOcorrencia(Remessa remessa) =>
      {
        'alerta',
        'atrasado',
        'atrasada',
        'problema',
        'ocorrencia',
        'com ocorrencia',
        'incident',
        'issue',
      }.contains(_normalizarStatus(remessa.status)) ||
      remessa.comOcorrencia;

  bool _temOcorrencia(Map value) {
    for (final chave in [
      'com_ocorrencia',
      'tem_ocorrencia',
      'has_occurrence',
      'has_incident',
      'ocorrencia',
      'incident',
    ]) {
      final raw = value[chave];
      if (raw == true || (raw is num && raw != 0)) return true;
      if (raw is String &&
          raw.trim().isNotEmpty &&
          !{
            'false',
            '0',
            'nao',
            'não',
            'null',
          }.contains(raw.trim().toLowerCase())) {
        return true;
      }
      if (raw is Map && raw.isNotEmpty || raw is List && raw.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<Remessa> get _paradasPendentes => _remessas
      .where(
        (remessa) => !_remessaEntregue(remessa) && !_remessaCancelada(remessa),
      )
      .toList();

  String _campoApi(Map value, List<String> chaves, {String fallback = ''}) {
    for (final chave in chaves) {
      final raw = value[chave];
      if (raw == null) continue;
      if (raw is Map) {
        final nested =
            raw['nome'] ??
            raw['name'] ??
            raw['label'] ??
            raw['descricao'] ??
            raw['status'] ??
            raw['value'] ??
            raw['endereco'] ??
            raw['endereco_completo'] ??
            raw['address'] ??
            raw['cidade'] ??
            raw['city'];
        if (nested != null && '$nested'.trim().isNotEmpty) {
          return '$nested'.trim();
        }
        continue;
      }
      final texto = '$raw'.trim();
      if (texto.isNotEmpty && texto != '-') return texto;
    }
    return fallback;
  }

  Remessa? get _rotaAtiva {
    for (final remessa in _remessas) {
      if (_remessaEmRota(remessa)) return remessa;
    }
    for (final remessa in _remessas) {
      if ({
        'aguardando coleta',
        'aguardando retirada',
        'pending pickup',
        'pendente',
        'pending',
        'assigned',
      }.contains(_normalizarStatus(remessa.status))) {
        return remessa;
      }
    }
    for (final remessa in _remessas) {
      if (!_remessaEntregue(remessa) && !_remessaCancelada(remessa)) {
        return remessa;
      }
    }
    return null;
  }

  Map<String, dynamic> get _dadosMotorista {
    final motorista = _usuario['motorista'] ?? _usuario['driver'];
    return motorista is Map ? Map<String, dynamic>.from(motorista) : _usuario;
  }

  String get _statusMotorista => _campoApi(_dadosMotorista, [
    'status',
    'situacao',
    'status_motorista',
  ], fallback: _campoApi(_usuario, ['status', 'situacao']));

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(0, 2).toInt();
    unawaited(SyncEngine.instance.atualizarContadores());
    _carregarResumo();
    _carregarPerfil();
    _carregarAvaliacao();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotificationCenter.instance.attach(
        context,
        fetch: () => ApiService.instance.avisosMotorista(),
      );
    });
    _novasEntregasTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _verificarNovasEntregas(),
    );
    _verificarNovasEntregas();
  }

  @override
  void dispose() {
    AppNotificationCenter.instance.detach();
    _novasEntregasTimer?.cancel();
    super.dispose();
  }

  Future<void> _verificarNovasEntregas() async {
    if (!AppSession.configuracoesMotorista.value.novasEntregas) return;
    try {
      final disponiveis = await ApiService.instance.remessasDisponiveis();
      final quantidade = disponiveis.length;
      final anterior = _disponiveisConhecidas;
      _disponiveisConhecidas = quantidade;
      if (anterior != null && quantidade > anterior) {
        final novas = quantidade - anterior;
        AppNotificationCenter.instance.notify(
          titulo: 'Nova entrega disponível',
          mensagem:
              '$novas nova${novas == 1 ? '' : 's'} entrega${novas == 1 ? '' : 's'} para aceitar.',
        );
      }
    } catch (_) {
      // Sem conexão: tenta novamente no próximo ciclo.
    }
  }

  Future<void> _carregarResumo() async {
    if (mounted) {
      setState(() {
        _carregandoResumo = _remessas.isEmpty;
        _falhaCarregamentoResumo = false;
        _erroCarregamentoResumo = null;
      });
    }
    try {
      final dados = await ApiService.instance.minhasRemessas(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _remessas = dados.whereType<Map>().map((value) {
          final rawProgress =
              value['progresso'] ??
              value['progress'] ??
              value['percentual'] ??
              0;
          final progress = rawProgress is num
              ? rawProgress.toDouble()
              : double.tryParse('$rawProgress'.replaceAll(',', '.')) ?? 0;
          final progressoNormalizado = progress > 1 ? progress / 100 : progress;
          return Remessa(
            codigo: _textoApi(
              _campoApi(value, ['codigo', 'code', 'tracking_code', 'id']),
            ),
            status: _textoApi(
              _campoApi(value, [
                'status',
                'situacao',
                'status_name',
              ], fallback: 'Status não informado'),
            ),
            origem: _textoApi(
              _campoApi(value, [
                'origem',
                'origin',
                'remetente_endereco',
                'pickup_address',
              ]),
            ),
            destino: _textoApi(
              _campoApi(value, [
                'destino',
                'destination',
                'destinatario_endereco',
                'delivery_address',
              ]),
            ),
            tipo: _textoApi(
              _campoApi(value, ['tipo', 'tipo_carga', 'cargo_type', 'cargo']),
            ),
            peso: _textoApi(_campoApi(value, ['peso', 'weight'])),
            eta: _textoApi(
              _campoApi(value, [
                'eta',
                'previsao_entrega',
                'estimated_delivery',
                'data_prevista_entrega',
                'delivery_date',
              ]),
            ),
            distancia: _textoApi(
              _campoApi(value, [
                'distancia',
                'distancia_km',
                'distance',
                'distance_km',
              ]),
            ),
            progresso: progressoNormalizado.clamp(0, 1).toDouble(),
            comOcorrencia: _temOcorrencia(value),
            id:
                value['id'] ??
                value['remessa_id'] ??
                value['shipment_id'] ??
                value['uuid'] ??
                value['codigo'] ??
                value['code'] ??
                value['tracking_code'] ??
                value['trackingCode'] ??
                value['numero'] ??
                value['reference'],
          );
        }).toList();
        _carregandoResumo = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _carregandoResumo = false;
          _falhaCarregamentoResumo = true;
          _erroCarregamentoResumo = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _carregandoResumo = false;
          _falhaCarregamentoResumo = true;
          _erroCarregamentoResumo = error.toString();
        });
      }
    }
  }

  Future<void> _carregarAvaliacao() async {
    double? media;
    try {
      final resumo = await ApiService.instance.resumoAvaliacoes();
      final dados = resumo['data'] is Map
          ? Map<String, dynamic>.from(resumo['data'] as Map)
          : resumo;
      final valor =
          dados['media'] ??
          dados['average'] ??
          dados['nota_media'] ??
          dados['rating_average'] ??
          dados['nota'];
      media = valor is num
          ? valor.toDouble()
          : double.tryParse('$valor'.replaceAll(',', '.'));
    } catch (_) {
      try {
        final avaliacoes = await ApiService.instance.avaliacoes();
        final notas = avaliacoes
            .whereType<Map>()
            .map((item) {
              final valor =
                  item['nota'] ??
                  item['rating'] ??
                  item['avaliacao'] ??
                  item['score'];
              return valor is num
                  ? valor.toDouble()
                  : double.tryParse('$valor'.replaceAll(',', '.'));
            })
            .whereType<double>()
            .toList();
        if (notas.isNotEmpty) {
          media = notas.reduce((a, b) => a + b) / notas.length;
        }
      } catch (_) {
        // A avaliação pode não estar disponível para esta conta/API.
      }
    }
    if (mounted) setState(() => _avaliacaoMedia = media);
  }

  Future<void> _configurarApi() async {
    var urlAtual = '';
    try {
      urlAtual = ApiService.baseUrl;
    } on ApiException {
      // Permite definir a primeira URL da API diretamente pelo painel.
    }
    final controller = TextEditingController(text: urlAtual);
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configurar servidor da API'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'URL do Laravel',
            hintText: 'https://api.suaempresa.com/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Salvar e atualizar'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 1), controller.dispose);
    if (url == null || !mounted) return;
    try {
      await ApiService.saveBaseUrl(url);
      await Future.wait([
        _carregarResumo(),
        _carregarPerfil(),
        _carregarAvaliacao(),
      ]);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _carregarPerfil() async {
    if (mounted) {
      setState(() {
        _carregandoPerfil = true;
        _falhaCarregamentoPerfil = false;
        _erroCarregamentoPerfil = null;
      });
    }
    Map<String, dynamic> usuario = {};
    List<Map<String, dynamic>>? documentos;
    final erros = <String>[];
    try {
      usuario = ApiService.instance.authUser(
        ApiService.instance.authData(await ApiService.instance.me()),
      );
    } on ApiException catch (error) {
      erros.add('Perfil: ${error.message}');
    } catch (error) {
      erros.add('Perfil: $error');
    }
    try {
      documentos = (await ApiService.instance.documentosMotorista())
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        // Algumas versões do backend ainda não implementam esta rota.
        // Usa os documentos que eventualmente vierem junto de auth/me.
        documentos = _documentosDoPerfil(usuario);
      } else {
        debugPrint('[Motorista] documentos indisponíveis: ${error.message}');
      }
    } catch (error) {
      debugPrint('[Motorista] falha ao carregar documentos: $error');
    }
    if (!mounted) return;
    setState(() {
      if (usuario.isNotEmpty) _usuario = usuario;
      _documentos = documentos ?? _documentos;
      _carregandoPerfil = false;
      _falhaCarregamentoPerfil = erros.isNotEmpty;
      _erroCarregamentoPerfil = erros.isEmpty ? null : erros.join('\n');
    });
    final veiculo = _veiculoDaApi(usuario);
    if (veiculo != null) await AppSession.salvarVeiculo(veiculo);
    final motorista = usuario['motorista'] ?? usuario['driver'];
    final perfilApi = motorista is Map ? motorista : usuario;
    final nome = _campoApi(perfilApi, [
      'name',
      'nome',
      'nome_completo',
    ], fallback: _campoApi(usuario, ['name', 'nome']));
    final email = _campoApi(perfilApi, [
      'email',
    ], fallback: _campoApi(usuario, ['email']));
    if (nome.isNotEmpty || email.isNotEmpty) {
      await AppSession.atualizarDadosUsuario(
        nome: nome.isEmpty ? AppSession.nome : nome,
        email: email.isEmpty ? AppSession.email : email,
      );
    }
  }

  List<Map<String, dynamic>> _documentosDoPerfil(Map<String, dynamic> usuario) {
    final motorista = usuario['motorista'] ?? usuario['driver'];
    final perfil = motorista is Map ? motorista : usuario;
    final documentos =
        perfil['documentos'] ??
        perfil['documents'] ??
        perfil['documentos_motorista'] ??
        perfil['driver_documents'] ??
        usuario['documentos'] ??
        usuario['documents'];
    if (documentos is! List) return <Map<String, dynamic>>[];
    return documentos
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  VeiculoMotorista? _veiculoDaApi(Map<String, dynamic> usuario) {
    final motorista = usuario['motorista'] ?? usuario['driver'];
    final veiculo =
        usuario['veiculo'] ??
        usuario['vehicle'] ??
        (motorista is Map
            ? motorista['veiculo'] ?? motorista['vehicle']
            : null);
    final dados = veiculo is Map
        ? veiculo
        : motorista is Map
        ? motorista
        : usuario;
    final resultado = VeiculoMotorista(
      modelo: _campoApi(dados, ['modelo', 'model', 'vehicle_model']),
      placa: _campoApi(dados, ['placa', 'plate', 'license_plate']),
      renavam: _campoApi(dados, ['renavam', 'renavam_code']),
      ano: _campoApi(dados, ['ano', 'year', 'vehicle_year']),
      capacidade: _campoApi(dados, ['capacidade', 'capacity', 'capacity_kg']),
    );
    return [
          resultado.modelo,
          resultado.placa,
          resultado.renavam,
          resultado.ano,
          resultado.capacidade,
        ].any((valor) => valor.isNotEmpty)
        ? resultado
        : null;
  }

  String get _nomeMotorista {
    final nomeApi = _campoApi(_dadosMotorista, [
      'name',
      'nome',
      'nome_completo',
    ], fallback: _campoApi(_usuario, ['name', 'nome']));
    if (nomeApi.isNotEmpty) return nomeApi;
    return AppSession.nome.isEmpty ? 'motorista' : AppSession.nome;
  }

  String _textoApi(Object? valor) {
    final texto = '${valor ?? ''}'.trim();
    return texto.isEmpty || texto == '-' ? 'Não informado' : texto;
  }

  String get _emailMotorista {
    final emailApi = _campoApi(_dadosMotorista, [
      'email',
    ], fallback: _campoApi(_usuario, ['email']));
    return emailApi.isNotEmpty ? emailApi : AppSession.email;
  }

  Color get _corStatusMotorista {
    final status = _normalizarStatus(_statusMotorista);
    if ({'ativo', 'active', 'aprovado', 'approved'}.contains(status)) {
      return success;
    }
    if (status.isEmpty) return textLight;
    return warning;
  }

  Color _corStatusDocumento(String tipo) {
    final status = _normalizarStatus(_statusDocumento(tipo));
    if ({
      'aprovado',
      'approved',
      'válido',
      'valido',
      'valid',
    }.contains(status)) {
      return success;
    }
    if (status == 'não informado' || status == 'nao informado') {
      return textLight;
    }
    return warning;
  }

  Color _corStatusRemessa(String status) {
    switch (_normalizarStatus(status)) {
      case 'em rota':
      case 'em transito':
      case 'em deslocamento':
      case 'saiu para entrega':
      case 'in transit':
      case 'in progress':
      case 'out for delivery':
      case 'entregue':
      case 'delivered':
        return success;
      case 'aguardando coleta':
      case 'pendente':
      case 'pending':
        return warning;
      case 'alerta':
      case 'atrasado':
      case 'problema':
      case 'com ocorrencia':
        return Theme.of(context).colorScheme.error;
      default:
        return textLight;
    }
  }

  String _statusDocumento(String tipo) {
    for (final documento in _documentos) {
      final tipoDocumento = _normalizarStatus(
        documento['tipo'] ??
            documento['tipo_documento'] ??
            documento['document_type'],
      );
      if (tipoDocumento == tipo || tipoDocumento.contains(tipo)) {
        final status = _campoApi(documento, [
          'status',
          'situacao',
          'status_documento',
        ]);
        if (status.isNotEmpty) return status;
      }
    }
    return 'Não informado';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;
          final content = ResponsiveContent(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _getBody(),
              ),
            ),
          );
          if (!desktop) return content;
          return Row(
            children: [
              _buildNavigationRail(),
              VerticalDivider(width: 1, color: border),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 800
          ? _buildBottomNavigation()
          : null,
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _inicio();

      case 2:
        return _perfil();

      default:
        return _inicio();
    }
  }

  void _changePage(int index) {
    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RemessasPage()));
      return;
    }

    setState(() {
      _currentIndex = index;
    });
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
      toolbarHeight: 72,
      titleSpacing: 18,
      title: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GeoSync',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Painel do motorista',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _notificationButton(),
        const SizedBox(width: 8),
        _profileButton(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(LucideIcons.truck, color: Colors.white, size: 23),
    );
  }

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  Widget _notificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AvisosMotoristaPage()));
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(LucideIcons.bell, color: Color(0xFF475569), size: 22),
            ),
            ValueListenableBuilder<int>(
              valueListenable: AppNotificationCenter.instance.unreadCount,
              builder: (context, unread, _) {
                if (unread <= 0) return const SizedBox.shrink();
                return Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

  // ============================================================
  // PERFIL NO APP BAR
  // ============================================================

  Widget _profileButton() {
    return GestureDetector(
      onTap: () {
        _changePage(2);
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF0FF), Color(0xFFDDE7FF)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            AppSession.inicialNome,
            style: const TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
        border: Border(top: BorderSide(color: border, width: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  icon: LucideIcons.house,
                  iconeAtivo: LucideIcons.house600,
                  label: 'Início',
                  index: 0,
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: LucideIcons.truck,
                  iconeAtivo: LucideIcons.truck600,
                  label: 'Entregas',
                  index: 1,
                ),
              ),
              Expanded(
                child: _navItem(
                  icon: LucideIcons.circleUserRound,
                  iconeAtivo: LucideIcons.circleUserRound600,
                  label: 'Perfil',
                  index: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRail() => NavigationRail(
    selectedIndex: _currentIndex,
    onDestinationSelected: _changePage,
    labelType: NavigationRailLabelType.all,
    leading: const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 24),
      child: Icon(LucideIcons.route, color: primary),
    ),
    destinations: const [
      NavigationRailDestination(
        icon: Icon(LucideIcons.house),
        selectedIcon: Icon(LucideIcons.house600),
        label: Text('Início'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.truck),
        selectedIcon: Icon(LucideIcons.truck600),
        label: Text('Entregas'),
      ),
      NavigationRailDestination(
        icon: Icon(LucideIcons.circleUserRound),
        selectedIcon: Icon(LucideIcons.circleUserRound600),
        label: Text('Perfil'),
      ),
    ],
  );

  Widget _navItem({
    required IconData icon,
    required IconData iconeAtivo,
    required String label,
    required int index,
  }) {
    final bool selected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _changePage(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 48),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? iconeAtivo : icon,
                size: 23,
                color: selected ? primary : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.2),
              style: TextStyle(
                color: selected ? primary : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INÍCIO
  // ============================================================

  Widget _inicio() {
    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        await Future.wait([
          _carregarResumo(),
          _carregarPerfil(),
          _carregarAvaliacao(),
          AppNotificationCenter.instance.refreshNow(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(),
            const SizedBox(height: 12),
            _buildStatusSincronizacao(),
            const SizedBox(height: 20),
            _cardRota(),
            const SizedBox(height: 24),
            _buildTelemetria(),
            const SizedBox(height: 24),
            _buildAcoesRapidas(),
            const SizedBox(height: 28),
            _buildResumo(),
            const SizedBox(height: 28),
            _buildDesempenho(),
            const SizedBox(height: 28),
            _buildProximasParadas(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SAUDAÇÃO
  // ============================================================

  Widget _buildWelcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final greeting = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_saudacao()}, $_nomeMotorista 👋',
              style: TextStyle(
                color: textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Sua rota',
              style: TextStyle(
                color: textDark,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: 10),
              _buildStatusOnline(compacto: true),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 12),
            _buildStatusOnline(compacto: false),
          ],
        );
      },
    );
  }

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildTelemetria() {
    return ValueListenableBuilder<bool>(
      valueListenable: BackgroundLocationService.instance.ativo,
      builder: (context, rastreando, _) => ValueListenableBuilder(
        valueListenable: BackgroundLocationService.instance.ultimaPosicao,
        builder: (context, ponto, _) {
          final detalhe = ponto == null
              ? 'Aguardando localização do dispositivo'
              : '${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}'
                    ' • ${TimeOfDay.fromDateTime(ponto.registradoEm.toLocal()).format(context)}';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.radio,
                  color: rastreando ? success : textLight,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rastreando
                            ? 'Rastreamento IoT ativo'
                            : 'Rastreamento IoT pausado',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detalhe,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir mapa',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MapaMotoristaPage(remessaInicial: _rotaAtiva?.codigo),
                    ),
                  ),
                  icon: const Icon(LucideIcons.map),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOnline({required bool compacto}) {
    final carregando = _carregandoResumo;
    final cor = carregando
        ? textLight
        : _falhaCarregamentoResumo
        ? warning
        : success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: cor),
          SizedBox(width: 6),
          if (compacto)
            Flexible(child: _textoStatusOnline(carregando))
          else
            _textoStatusOnline(carregando),
        ],
      ),
    );
  }

  Widget _textoStatusOnline(bool carregando) => Text(
    carregando
        ? 'Atualizando dados...'
        : _falhaCarregamentoResumo
        ? 'Falha ao atualizar'
        : 'Dados disponíveis',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: carregando
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : _falhaCarregamentoResumo
          ? Color(0xFF9A6700)
          : Color(0xFF15803D),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _buildStatusSincronizacao() {
    return ValueListenableBuilder<SyncState>(
      valueListenable: SyncEngine.instance.estado,
      builder: (context, sync, _) {
        final pendentes = sync.totalPendente;
        final erro = sync.erro != null;
        final cor = erro
            ? const Color(0xFFB42318)
            : pendentes > 0
            ? const Color(0xFFB7791F)
            : success;
        final titulo = sync.sincronizando
            ? 'Sincronizando alterações...'
            : erro
            ? 'Não foi possível sincronizar'
            : pendentes > 0
            ? '$pendentes ${pendentes == 1 ? 'item pendente' : 'itens pendentes'}'
            : 'Tudo sincronizado';
        final descricao = erro
            ? '${sync.erro} Suas alterações continuam salvas neste aparelho.'
            : pendentes > 0
            ? 'Elas serão enviadas quando a conexão estiver disponível.'
            : 'Suas entregas e atualizações estão em dia.';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(
                sync.sincronizando
                    ? LucideIcons.refreshCw
                    : erro || pendentes > 0
                    ? LucideIcons.cloudOff
                    : LucideIcons.cloudCheck,
                color: cor,
                size: 21,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: cor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: textLight,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sincronizar agora',
                onPressed: sync.sincronizando
                    ? null
                    : () => SyncEngine.instance.sincronizar(),
                icon: sync.sincronizando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.refreshCw, color: cor, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CARD DA ROTA
  // ============================================================

  Widget _cardRota() {
    final remessa = _rotaAtiva;
    if (_carregandoResumo) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_falhaCarregamentoResumo && _remessas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.cloudOff, size: 34, color: warning),
            const SizedBox(height: 10),
            const Text('Não foi possível atualizar suas entregas.'),
            const SizedBox(height: 12),
            if (_erroCarregamentoResumo != null) ...[
              const SizedBox(height: 6),
              Text(
                _erroCarregamentoResumo!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textLight, fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _carregarResumo,
              icon: const Icon(LucideIcons.refreshCw, size: 17),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _configurarApi,
              icon: const Icon(LucideIcons.settings, size: 17),
              label: const Text('Configurar servidor da API'),
            ),
          ],
        ),
      );
    }
    if (remessa == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.truck, size: 36),
            const SizedBox(height: 10),
            const Text('Nenhuma entrega ativa hoje'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemessasPage(mostrarDisponiveis: true),
                ),
              ),
              icon: const Icon(LucideIcons.packageSearch),
              label: const Text('Ver entregas disponíveis'),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, Color(0xFF123C69), primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -70,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.navigation,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _remessaEmRota(remessa)
                          ? 'VIAGEM EM ANDAMENTO'
                          : 'PRÓXIMA ENTREGA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      remessa.codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: _corStatusRemessa(remessa.status),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              remessa.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${remessa.origem} → ${remessa.destino}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (remessa.tipo != 'Não informado' ||
                  remessa.peso != 'Não informado') ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (remessa.tipo != 'Não informado') remessa.tipo,
                    if (remessa.peso != 'Não informado') remessa.peso,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  _routeInfo(
                    icon: LucideIcons.route,
                    value: _textoApi(remessa.distancia),
                    label: 'distância',
                  ),
                  const SizedBox(width: 10),
                  _routeInfo(
                    icon: LucideIcons.package,
                    value: '${_paradasPendentes.length}',
                    label: 'entregas',
                  ),
                  const SizedBox(width: 10),
                  _routeInfo(
                    icon: LucideIcons.clock,
                    value: _textoApi(remessa.eta),
                    label: 'previsão',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_remessaEmRota(remessa)) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MapaMotoristaPage(),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RemessasPage()),
                      );
                    }
                  },
                  icon: Icon(
                    _remessaEmRota(remessa)
                        ? LucideIcons.navigation
                        : LucideIcons.package,
                    size: 19,
                  ),
                  label: Text(
                    _remessaEmRota(remessa)
                        ? 'Continuar navegação'
                        : 'Ver entrega',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 15),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AÇÕES RÁPIDAS
  // ============================================================

  Widget _buildAcoesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acesso rápido',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _acaoRapida(
                icon: LucideIcons.truck,
                titulo: 'Entregas',
                subtitulo: 'Ver rota',
                cor: primary,
                onTap: () => _changePage(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _acaoRapida(
                icon: LucideIcons.map,
                titulo: 'Mapa',
                subtitulo: 'Navegação',
                cor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MapaMotoristaPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _acaoRapida(
                icon: LucideIcons.bell,
                titulo: 'Avisos',
                subtitulo: 'Atualizações',
                cor: warning,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AvisosMotoristaPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _acaoRapida({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitulo, style: TextStyle(color: textLight, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildResumo() {
    final entregues = _remessas.where(_remessaEntregue).length;
    final emRota = _remessas.where(_remessaEmRota).length;
    final ocorrencias = _remessas.where(_remessaComOcorrencia).length;
    final indisponivel =
        _carregandoResumo || (_falhaCarregamentoResumo && _remessas.isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo das entregas',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 520;
            final cards = [
              _resumo(
                icon: LucideIcons.package,
                valor: indisponivel ? '-' : '${_remessas.length}',
                legenda: 'Total',
                cor: primary,
              ),
              _resumo(
                icon: LucideIcons.clock,
                valor: indisponivel ? '-' : '$emRota',
                legenda: 'Em trânsito',
                cor: success,
              ),
              _resumo(
                icon: LucideIcons.badgeCheck,
                valor: indisponivel ? '-' : '$entregues',
                legenda: 'Entregues',
                cor: const Color(0xFF7C3AED),
              ),
              _resumo(
                icon: LucideIcons.alertTriangle,
                valor: indisponivel ? '-' : '$ocorrencias',
                legenda: 'Com ocorrência',
                cor: const Color(0xFFEF4444),
              ),
              _resumo(
                icon: LucideIcons.star,
                valor: _avaliacaoMedia == null
                    ? '-'
                    : _avaliacaoMedia!.toStringAsFixed(1),
                legenda: 'Avaliação média',
                cor: const Color(0xFFE58A00),
              ),
            ];
            final colunas = compacto ? 2 : 5;
            final espacamento = 10.0;
            final largura =
                (constraints.maxWidth - espacamento * (colunas - 1)) / colunas;
            return Wrap(
              spacing: espacamento,
              runSpacing: espacamento,
              children: [
                for (final card in cards) SizedBox(width: largura, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _resumo({
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
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cor, size: 19),
          ),
          const SizedBox(height: 11),
          Text(
            valor,
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(legenda, style: TextStyle(color: textLight, fontSize: 9)),
        ],
      ),
    );
  }

  // ============================================================
  // DESEMPENHO
  // ============================================================

  Map<String, dynamic> _desempenho() {
    final total = _remessas.length;
    final concluidas = _remessas.where(_remessaEntregue).length;
    final pendentes = _paradasPendentes.length;
    final atrasadas = _remessas.where((r) {
      final status = _normalizarStatus(r.status);
      return status == 'alerta' || status == 'atrasado' || status == 'atrasada';
    }).length;
    final ocorrencias = _remessas.where(_remessaComOcorrencia).length;
    return {
      'total': total,
      'concluidas': concluidas,
      'pendentes': pendentes,
      'atrasadas': atrasadas,
      'ocorrencias': ocorrencias,
    };
  }

  Widget _buildDesempenho() {
    final dados = _desempenho();
    final indisponivel =
        _carregandoResumo || (_falhaCarregamentoResumo && _remessas.isEmpty);
    final series = <MapEntry<String, int>>[
      MapEntry('Total', dados['total'] as int),
      MapEntry('Concl.', dados['concluidas'] as int),
      MapEntry('Pend.', dados['pendentes'] as int),
      MapEntry('Alerta', dados['atrasadas'] as int),
      MapEntry('Ocorr.', dados['ocorrencias'] as int),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desempenho',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        GridView(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: MediaQuery.textScalerOf(context).scale(14) > 22
                ? 176
                : MediaQuery.sizeOf(context).width < 420
                ? 138
                : 112,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _desempenhoCard(
              icon: LucideIcons.package,
              label: 'Total',
              valor: indisponivel ? '-' : '${dados['total']}',
              cor: primary,
            ),
            _desempenhoCard(
              icon: LucideIcons.badgeCheck,
              label: 'Concluídas',
              valor: indisponivel ? '-' : '${dados['concluidas']}',
              cor: success,
            ),
            _desempenhoCard(
              icon: LucideIcons.clock,
              label: 'Pendentes',
              valor: indisponivel ? '-' : '${dados['pendentes']}',
              cor: warning,
            ),
            _desempenhoCard(
              icon: LucideIcons.alertTriangle,
              label: 'Atrasadas',
              valor: indisponivel ? '-' : '${dados['atrasadas']}',
              cor: const Color(0xFFEF4444),
            ),
            _desempenhoCard(
              icon: LucideIcons.octagonAlert,
              label: 'Ocorrências',
              valor: indisponivel ? '-' : '${dados['ocorrencias']}',
              cor: const Color(0xFF7C3AED),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: BackgroundLocationService.instance.ativo,
              builder: (context, ativo, _) => _desempenhoCard(
                icon: LucideIcons.truck,
                label: 'Rastreamento',
                valor: ativo ? 'Ativo' : 'Pausado',
                cor: const Color(0xFF0F766E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribuição atual das remessas',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final max = series.fold<int>(
                    0,
                    (a, b) => a > b.value ? a : b.value,
                  );
                  if (indisponivel) {
                    return SizedBox(
                      height: 108,
                      child: Center(
                        child: Text(
                          'Aguardando dados das entregas...',
                          style: TextStyle(color: textLight, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return Row(
                    children: [
                      for (final item in series)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 86,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: math.min(
                                        24.0,
                                        constraints.maxWidth /
                                            series.length *
                                            0.46,
                                      ),
                                      height: max == 0
                                          ? 0
                                          : (item.value / max * 86)
                                                .clamp(8, 86)
                                                .toDouble(),
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.key,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desempenhoCard({
    required IconData icon,
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cor, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRÓXIMAS PARADAS
  // ============================================================

  Widget _buildProximasParadas() {
    final paradas = _paradasPendentes.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Próximas paradas',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _changePage(1),
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_carregandoResumo)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_falhaCarregamentoResumo && _remessas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Não foi possível carregar as paradas. Puxe para atualizar.',
              style: TextStyle(color: textLight, fontSize: 12),
            ),
          )
        else if (paradas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma parada pendente.'),
          )
        else
          ...paradas.asMap().entries.map((entry) {
            final remessa = entry.value;
            final entregue = _remessaEntregue(remessa);
            final cor = _corStatusRemessa(remessa.status);
            return _parada(
              numero: '${entry.key + 1}',
              titulo: remessa.destino,
              detalhe: 'Previsão • ${remessa.eta}',
              icon: entregue ? LucideIcons.circleCheckBig : LucideIcons.mapPin,
              status: remessa.status,
              statusColor: cor,
              isFirst: entry.key == 0,
            );
          }),
      ],
    );
  }

  Widget _parada({
    required String numero,
    required String titulo,
    required String detalhe,
    required IconData icon,
    required String status,
    required Color statusColor,
    required bool isFirst,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalhe,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textLight, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: statusColor, size: 19),
              const SizedBox(height: 5),
              SizedBox(
                width: 70,
                child: Text(
                  status,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFIL
  // ============================================================

  Widget _perfil() {
    return RefreshIndicator(
      color: primary,
      onRefresh: _carregarPerfil,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // AVATAR
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF0FF), Color(0xFFDCE7FF)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.circleUserRound,
                size: 46,
                color: primary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _nomeMotorista == 'motorista' ? 'Motorista' : _nomeMotorista,
              style: TextStyle(
                color: textDark,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),

            if (_emailMotorista.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                _emailMotorista,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textLight, fontSize: 12),
              ),
            ],

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.badgeCheck,
                  color: _corStatusDocumento('cnh'),
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Motorista • CNH ${_statusDocumento('cnh')}',
                  style: TextStyle(color: textLight, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // STATUS
            _buildProfileStatus(),

            const SizedBox(height: 18),

            _perfilItem(
              icon: LucideIcons.idCard,
              titulo: 'Documentos',
              subtitulo: 'CNH e documentos do motorista',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentosMotoristaPage(),
                  ),
                );
              },
            ),

            ValueListenableBuilder<VeiculoMotorista>(
              valueListenable: AppSession.veiculoMotorista,
              builder: (context, veiculo, _) => _perfilItem(
                icon: LucideIcons.truck,
                titulo: 'Meu veículo',
                subtitulo:
                    '${veiculo.modelo.isEmpty ? 'Modelo não informado' : veiculo.modelo} • ${veiculo.placa.isEmpty ? 'Placa não informada' : veiculo.placa}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VeiculoMotoristaPage(),
                    ),
                  );
                },
              ),
            ),

            _perfilItem(
              icon: LucideIcons.settings,
              titulo: 'Configurações',
              subtitulo: 'Preferências da conta',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfiguracoesMotoristaPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF6F8FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: _corStatusMotorista, size: 9),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _carregandoPerfil
                      ? 'Carregando perfil...'
                      : _falhaCarregamentoPerfil && _statusMotorista.isEmpty
                      ? 'Falha ao carregar perfil'
                      : _textoApi(_statusMotorista),
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'CNH: ${_statusDocumento('cnh')} • CRLV: ${_statusDocumento('crlv')}',
                  style: TextStyle(color: textLight, fontSize: 10),
                ),
                if (_erroCarregamentoPerfil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _erroCarregamentoPerfil!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: primary, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM DO PERFIL
  // ============================================================

  Widget _perfilItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(color: textLight, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFF94A3B8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO SAIR
  // ============================================================

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _sair,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFFFDADA)),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.logOut, color: Colors.redAccent, size: 21),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: Colors.redAccent, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAIR
  // ============================================================

  Future<void> _sair() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {
      // Remove the local credentials if the server is unavailable.
    }
    await AppSession.encerrarSessao();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
