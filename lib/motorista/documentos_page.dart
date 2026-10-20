import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/app_gradient_header.dart';
import 'package:mobile/widgets/responsive_content.dart';

class DocumentosMotoristaPage extends StatefulWidget {
  const DocumentosMotoristaPage({super.key});
  @override
  State<DocumentosMotoristaPage> createState() =>
      _DocumentosMotoristaPageState();
}

class _DocumentosMotoristaPageState extends State<DocumentosMotoristaPage> {
  static const primary = Color(0xFF0C46FF);
  bool _enviando = false;
  bool _carregando = true;
  List<Map<String, dynamic>> _documentosApi = [];
  Map<String, dynamic> _perfilApi = {};
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final resposta = await ApiService.instance.documentosMotorista();
      if (mounted) {
        setState(() {
          _documentosApi = resposta
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }
    } on ApiException catch (error) {
      if (error.statusCode != 404) _erro = error.message;
      // A tela permanece disponível quando a consulta estiver offline.
    } catch (error) {
      _erro = error.toString();
    }
    try {
      final usuario = ApiService.instance.authUser(
        await ApiService.instance.me(),
      );
      final motorista = usuario['motorista'] ?? usuario['driver'];
      if (mounted) {
        setState(() {
          _perfilApi = motorista is Map
              ? Map<String, dynamic>.from(motorista)
              : usuario;
          if (_documentosApi.isEmpty) {
            final documentos =
                _perfilApi['documentos'] ??
                _perfilApi['documents'] ??
                _perfilApi['documentos_motorista'] ??
                _perfilApi['driver_documents'];
            if (documentos is List) {
              _documentosApi = documentos
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
          }
        });
      }
    } on ApiException catch (error) {
      if (mounted && _erro == null) setState(() => _erro = error.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _status(String tipo, bool enviado) {
    Map<String, dynamic>? documento;
    for (final item in _documentosApi) {
      final tipoApi =
          '${item['tipo'] ?? item['tipo_documento'] ?? item['document_type']}'
              .toLowerCase();
      if (tipoApi == tipo || tipoApi.contains(tipo)) {
        documento = item;
        break;
      }
    }
    final perfilDocumento = _perfilApi[tipo];
    final status =
        documento?['status'] ??
        documento?['situacao'] ??
        documento?['status_documento'] ??
        (perfilDocumento is Map
            ? perfilDocumento['status'] ?? perfilDocumento['situacao']
            : null) ??
        _perfilApi['${tipo}_status'] ??
        _perfilApi['status_$tipo'];
    final validade = _validade(tipo);
    final dataValidade = DateTime.tryParse(validade) ?? _dataBr(validade);
    if (dataValidade != null &&
        DateTime(
          dataValidade.year,
          dataValidade.month,
          dataValidade.day,
        ).isBefore(DateTime.now())) {
      return 'expired';
    }
    if (status != null && '$status'.trim().isNotEmpty) return '$status';
    return enviado ? 'pendente' : 'não informado';
  }

  DateTime? _dataBr(String valor) {
    final partes = valor.split(RegExp(r'[/.-]'));
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null || ano < 1000) return null;
    return DateTime(ano, mes, dia);
  }

  String _validade(String tipo) {
    final registro = _documentosApi
        .where(
          (item) =>
              '${item['tipo'] ?? item['tipo_documento'] ?? item['document_type']}'
                  .toLowerCase()
                  .contains(tipo),
        )
        .firstOrNull;
    final perfilDocumento = _perfilApi[tipo];
    final fontes = <Map>[
      if (registro case final Map registroEncontrado) registroEncontrado,
      if (perfilDocumento is Map) perfilDocumento,
      _perfilApi,
    ];
    final chaves = tipo == 'cnh'
        ? ['validade', 'validade_cnh', 'cnh_validade', 'data_validade_cnh']
        : ['validade', 'validade_crlv', 'crlv_validade', 'data_validade_crlv'];
    for (final fonte in fontes) {
      for (final chave in chaves) {
        final valor = fonte[chave];
        if (valor != null && '$valor'.trim().isNotEmpty) return '$valor';
      }
    }
    return '';
  }

  String _detalheDocumento(String tipo, String status) {
    final validade = _validade(tipo);
    final registro = _documentosApi
        .where(
          (item) =>
              '${item['tipo'] ?? item['tipo_documento'] ?? item['document_type']}'
                  .toLowerCase()
                  .contains(tipo),
        )
        .firstOrNull;
    final motivo =
        registro?['motivo_reprovacao'] ??
        registro?['motivo'] ??
        registro?['observacao'] ??
        registro?['mensagem_rejeicao'] ??
        registro?['rejection_reason'];
    final dados = <String>[
      'Status: ${_rotuloStatus(status)}',
      'Validade: ${validade.isEmpty ? 'não informada pela API' : validade}',
    ];
    if (motivo != null && '$motivo'.trim().isNotEmpty) {
      dados.add('Correção: $motivo');
    } else if ({'rejected', 'recusado'}.contains(status.toLowerCase())) {
      dados.add('Envie uma imagem legível e atualizada para nova análise.');
    } else if ({
      'expired',
      'vencido',
      'expirado',
    }.contains(status.toLowerCase())) {
      dados.add('Atualize o documento vencido.');
    }
    return dados.join(' • ');
  }

  String _rotuloStatus(String status) {
    final normalizado = status
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
    switch (normalizado) {
      case 'approved':
      case 'aprovado':
      case 'valid':
      case 'valido':
        return 'Aprovado';
      case 'rejected':
      case 'recusado':
        return 'Recusado';
      case 'pending':
      case 'pendente':
        return 'Pendente para an\u00e1lise';
      case 'expired':
      case 'vencido':
      case 'expirado':
        return 'Vencido';
      case 'nao informado':
        return 'N\u00e3o informado pela API';
      default:
        return status;
    }
  }

  String _campoCnh(List<String> chaves) {
    final cnh = _perfilApi['cnh'];
    final fontes = <Map>[
      if (cnh is Map) cnh,
      _perfilApi,
      ..._documentosApi.where((item) {
        final tipo =
            '${item['tipo'] ?? item['tipo_documento'] ?? item['document_type']}'
                .toLowerCase();
        return tipo.contains('cnh');
      }),
    ];
    for (final fonte in fontes) {
      for (final chave in chaves) {
        final valor = fonte[chave];
        if (valor != null && '$valor'.trim().isNotEmpty) {
          return '$valor'.trim();
        }
      }
    }
    return '';
  }

  Future<void> _enviar(bool cnh) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (imagem == null || !mounted) return;
      setState(() => _enviando = true);
      await ApiService.instance.enviarDocumentoMotorista(
        tipo: cnh ? 'cnh' : 'crlv',
        caminhoArquivo: imagem.path,
      );
      if (!mounted) return;
      final docs = AppSession.documentosMotorista.value;
      AppSession.salvarDocumentos(
        cnh
            ? docs.copyWith(cnhEnviada: true)
            : docs.copyWith(crlvEnviado: true),
      );
      await _carregarDocumentos();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cnh ? 'CNH' : 'CRLV'} enviado para análise.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a galeria.')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _escolherDocumento() => showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.idCard),
            title: const Text('Atualizar CNH'),
            onTap: () {
              Navigator.pop(context);
              _enviar(true);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.fileText),
            title: const Text('Atualizar CRLV'),
            onTap: () {
              Navigator.pop(context);
              _enviar(false);
            },
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final docs = AppSession.documentosMotorista.value;
    final cnhStatus = _status('cnh', docs.cnhEnviada);
    final crlvStatus = _status('crlv', docs.crlvEnviado);
    String normalizar(String valor) => valor
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
    final cnhNormalizada = normalizar(cnhStatus);
    final crlvNormalizada = normalizar(crlvStatus);
    final pendente =
        {'pendente', 'pending'}.contains(cnhNormalizada) ||
        {'pendente', 'pending'}.contains(crlvNormalizada);
    final aprovados = {'aprovado', 'approved', 'valid', 'valido'};
    final regularizada =
        aprovados.contains(cnhNormalizada) &&
        aprovados.contains(crlvNormalizada);
    final numeroCnh = _campoCnh([
      'numero',
      'numero_cnh',
      'cnh_numero',
      'registro_cnh',
    ]);
    final categoriaCnh = _campoCnh([
      'categoria',
      'categoria_cnh',
      'cnh_categoria',
    ]);
    final validadeCnh = _validade('cnh');
    final validadeCrlv = _validade('crlv');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppGradientHeader(
              title: 'Documentos',
              subtitle: 'CNH e CRLV do motorista',
              icon: LucideIcons.idCard,
            ),
            Expanded(
              child: ResponsiveContent(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B2A4A), primary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              LucideIcons.badgeCheck,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pendente
                                      ? 'Documentos em análise'
                                      : regularizada
                                      ? 'Documentação regularizada'
                                      : 'Documentação incompleta',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pendente
                                      ? 'Você receberá um aviso após a validação.'
                                      : regularizada
                                      ? 'CNH e CRLV aprovados pela API.'
                                      : 'Confira os status e envie os documentos que faltam.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Documentos pessoais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_carregando) const LinearProgressIndicator(),
                    if (_erro != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Não foi possível atualizar os documentos: $_erro',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    _documento(
                      LucideIcons.idCard,
                      'CNH',
                      AppSession.nome.isEmpty ? 'Motorista' : AppSession.nome,
                      _detalheDocumento('cnh', cnhStatus),
                      cnhStatus,
                      () => _enviar(true),
                    ),
                    _documento(
                      LucideIcons.fileText,
                      'Documento do veículo',
                      'CRLV',
                      _detalheDocumento('crlv', crlvStatus),
                      crlvStatus,
                      () => _enviar(false),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Dados da habilitação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (numeroCnh.isNotEmpty)
                      _info(LucideIcons.creditCard, 'Número da CNH', numeroCnh),
                    if (categoriaCnh.isNotEmpty)
                      _info(LucideIcons.layoutGrid, 'Categoria', categoriaCnh),
                    if (validadeCnh.isNotEmpty)
                      _info(LucideIcons.calendarDays, 'Validade', validadeCnh),
                    if (validadeCrlv.isNotEmpty)
                      _info(
                        LucideIcons.calendarDays,
                        'Validade do CRLV',
                        validadeCrlv,
                      ),
                    if (numeroCnh.isEmpty &&
                        categoriaCnh.isEmpty &&
                        validadeCnh.isEmpty &&
                        validadeCrlv.isEmpty)
                      const Text(
                        'Dados da habilitação ainda não disponíveis na API.',
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _enviando ? null : _escolherDocumento,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.fileUp),
                      label: Text(
                        _enviando ? 'Enviando...' : 'Atualizar documentos',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documento(
    IconData icon,
    String titulo,
    String subtitulo,
    String detalhe,
    String status,
    VoidCallback tap,
  ) {
    final normalizado = status.toLowerCase();
    final aprovado = {
      'approved',
      'aprovado',
      'valid',
      'válido',
    }.contains(normalizado);
    final pendente = {'pending', 'pendente'}.contains(normalizado);
    final rejeitado = {
      'rejected',
      'recusado',
      'expired',
      'vencido',
      'expirado',
    }.contains(normalizado);
    final cor = aprovado
        ? Colors.green
        : pendente
        ? Colors.orange
        : rejeitado
        ? Colors.red
        : Colors.grey;
    final statusIcone = aprovado
        ? LucideIcons.circleCheckBig
        : pendente
        ? LucideIcons.hourglass
        : rejeitado
        ? LucideIcons.circleAlert
        : LucideIcons.circleHelp;
    return Card(
      child: ListTile(
        onTap: tap,
        leading: Icon(icon, color: primary),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$subtitulo\n$detalhe'),
        isThreeLine: true,
        trailing: Icon(statusIcone, color: cor),
      ),
    );
  }

  Widget _info(IconData icon, String titulo, String valor) => Card(
    child: ListTile(
      leading: Icon(icon, color: primary),
      title: Text(titulo),
      subtitle: Text(
        valor,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
