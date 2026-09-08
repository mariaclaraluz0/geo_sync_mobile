import 'package:flutter/material.dart';

class AppSession {
  AppSession._();

  static String _senha = '';
  static final modoEscuro = ValueNotifier<bool>(false);
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

  static void definirModoEscuro(bool ativado) => modoEscuro.value = ativado;

  static void salvarVeiculo(VeiculoMotorista veiculo) =>
      veiculoMotorista.value = veiculo;

  static void salvarConfiguracoes(ConfiguracoesMotorista configuracoes) =>
      configuracoesMotorista.value = configuracoes;

  static void salvarDocumentos(DocumentosMotorista documentos) =>
      documentosMotorista.value = documentos;

  static bool autenticar(String senha) {
    if (_senha.isEmpty) {
      _senha = senha;
      return true;
    }
    return _senha == senha;
  }

  static void definirSenha(String senha) => _senha = senha;

  static bool alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    if (_senha.isNotEmpty && senhaAtual != _senha) return false;
    _senha = novaSenha;
    return true;
  }
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
