import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  AppSession._();

  static String _email = '';
  static String _nome = '';
  static String _token = '';
  static String _tipoUsuario = 'Cliente';
  static bool _restaurada = false;
  static final modoEscuro = ValueNotifier<bool>(false);
  static final notificacoesAtivas = ValueNotifier<bool>(true);
  static final sessaoAtualizada = ValueNotifier<int>(0);
  static final veiculoMotorista = ValueNotifier<VeiculoMotorista>(
    const VeiculoMotorista(
      modelo: 'Volvo VM 270',
      placa: 'ABC-1D23',
      renavam: '12345678901',
      ano: '2024',
      capacidade: '14 toneladas',
    ),
  );
  static final configuracoesMotorista = ValueNotifier<ConfiguracoesMotorista>(
    const ConfiguracoesMotorista(),
  );
  static final documentosMotorista = ValueNotifier<DocumentosMotorista>(
    const DocumentosMotorista(),
  );

  static Future<void> definirModoEscuro(bool ativado) async {
    modoEscuro.value = ativado;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', ativado);
  }

  static Future<void> definirNotificacoesAtivas(bool ativado) async {
    notificacoesAtivas.value = ativado;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacoes_ativas', ativado);
  }

  static String get token => _token;
  static String get nome => _nome;
  static String get email => _email;
  static String get inicialNome {
    final fonte = _nome.trim().isNotEmpty ? _nome.trim() : _email.trim();
    return fonte.isEmpty ? 'U' : fonte.substring(0, 1).toUpperCase();
  }

  static String get tipoUsuario => _tipoUsuario;
  static bool get autenticada => _token.isNotEmpty;
  static bool get restaurada => _restaurada;

  static Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    _tipoUsuario = prefs.getString('user_type') ?? 'Cliente';
    _email = prefs.getString('user_email') ?? '';
    _nome = prefs.getString('user_name') ?? '';
    modoEscuro.value = prefs.getBool('dark_mode') ?? false;
    notificacoesAtivas.value = prefs.getBool('notificacoes_ativas') ?? true;
    configuracoesMotorista.value = ConfiguracoesMotorista(
      notificacoes: notificacoesAtivas.value,
      novasEntregas: prefs.getBool('motorista_novas_entregas') ?? true,
      localizacao: prefs.getBool('motorista_localizacao') ?? true,
      modoEconomia: prefs.getBool('motorista_modo_economia') ?? false,
    );
    final veiculo = VeiculoMotorista.fromJson(
      prefs.getString('motorista_veiculo'),
    );
    if (veiculo != null) veiculoMotorista.value = veiculo;
    _restaurada = true;
  }

  static Future<void> iniciarSessao({
    required String token,
    required String tipoUsuario,
    String? email,
    String? nome,
  }) async {
    _token = token;
    _tipoUsuario = tipoUsuario;
    _email = email ?? _email;
    _nome = nome ?? _nome;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_type', tipoUsuario);
    if (_email.isNotEmpty) await prefs.setString('user_email', _email);
    if (_nome.isNotEmpty) await prefs.setString('user_name', _nome);
    sessaoAtualizada.value++;
  }

  static Future<void> encerrarSessao() async {
    _token = '';
    _email = '';
    _nome = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_type');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    sessaoAtualizada.value++;
  }

  /// Atualiza nome e e-mail salvos localmente após editar o perfil.
  static Future<void> atualizarDadosUsuario({
    required String nome,
    required String email,
  }) async {
    _nome = nome;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nome);
    await prefs.setString('user_email', email);
  }

  static Future<void> salvarVeiculo(VeiculoMotorista veiculo) async {
    veiculoMotorista.value = veiculo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('motorista_veiculo', jsonEncode(veiculo.toJson()));
  }

  static Future<void> salvarConfiguracoes(
    ConfiguracoesMotorista configuracoes,
  ) async {
    configuracoesMotorista.value = configuracoes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'motorista_novas_entregas',
      configuracoes.novasEntregas,
    );
    await prefs.setBool('motorista_localizacao', configuracoes.localizacao);
    await prefs.setBool('motorista_modo_economia', configuracoes.modoEconomia);
  }

  static void salvarDocumentos(DocumentosMotorista documentos) =>
      documentosMotorista.value = documentos;
}

class VeiculoMotorista {
  const VeiculoMotorista({
    required this.modelo,
    required this.placa,
    required this.renavam,
    required this.ano,
    required this.capacidade,
  });

  final String modelo;
  final String placa;
  final String renavam;
  final String ano;
  final String capacidade;

  Map<String, String> toJson() => {
    'modelo': modelo,
    'placa': placa,
    'renavam': renavam,
    'ano': ano,
    'capacidade': capacidade,
  };

  static VeiculoMotorista? fromJson(String? json) {
    if (json == null) return null;
    try {
      final dados = jsonDecode(json);
      if (dados is! Map) return null;
      String campo(String chave) => '${dados[chave] ?? ''}';
      return VeiculoMotorista(
        modelo: campo('modelo'),
        placa: campo('placa'),
        renavam: campo('renavam'),
        ano: campo('ano'),
        capacidade: campo('capacidade'),
      );
    } on FormatException {
      return null;
    }
  }
}

class ConfiguracoesMotorista {
  const ConfiguracoesMotorista({
    this.notificacoes = true,
    this.novasEntregas = true,
    this.localizacao = true,
    this.modoEconomia = false,
  });

  final bool notificacoes;
  final bool novasEntregas;
  final bool localizacao;
  final bool modoEconomia;
}

class DocumentosMotorista {
  const DocumentosMotorista({
    this.cnhEnviada = false,
    this.crlvEnviado = false,
  });

  final bool cnhEnviada;
  final bool crlvEnviado;

  bool get possuiPendencia => cnhEnviada || crlvEnviado;

  DocumentosMotorista copyWith({bool? cnhEnviada, bool? crlvEnviado}) =>
      DocumentosMotorista(
        cnhEnviada: cnhEnviada ?? this.cnhEnviada,
        crlvEnviado: crlvEnviado ?? this.crlvEnviado,
      );
}
