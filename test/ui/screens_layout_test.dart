import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/alerta_page.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/cadastro_screen.dart';
import 'package:mobile/configuracoes_page.dart';
import 'package:mobile/editar_perfil_page.dart';
import 'package:mobile/esqueceu_senha_page.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/mapa_page.dart';
import 'package:mobile/motorista/avisos_motorista_page.dart';
import 'package:mobile/motorista/configuracoes_page.dart';
import 'package:mobile/motorista/documentos_page.dart';
import 'package:mobile/motorista/entrega_page.dart' as motorista;
import 'package:mobile/motorista/mapa_motorista_page.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';
import 'package:mobile/motorista/veiculo_motorista_page.dart';
import 'package:mobile/perfil_page.dart';
import 'package:mobile/remessa_page.dart';
import 'package:mobile/suporte_page.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:mobile/tela_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renderiza cada tela em aparelhos de vários tamanhos, com fonte ampliada e
/// nos dois temas, e falha se alguma produzir overflow ou outra exceção de
/// layout. Sem rede (o flutter_test responde 400 a todo HTTP), as telas
/// usam o cache local ou mostram o estado de erro/vazio.
void main() {
  const aparelhos = <String, Size>{
    'celular pequeno': Size(320, 568),
    'celular médio': Size(360, 640),
    'celular grande': Size(412, 915),
    'tablet': Size(800, 1280),
  };
  const escalasDeFonte = [1.0, 1.3];

  final remessasEmCache = [
    {
      'id': 1,
      'codigo': 'GS-1001',
      'status': 'Em trânsito',
      'origem': 'Centro de Distribuição de São Bernardo do Campo',
      'destino': 'Rua Doutor Fulano de Tal com Nome Bem Comprido, 1234',
      'cliente': 'Empresa de Logística com um Nome Realmente Muito Longo',
      'peso': '12,5 kg',
      'updated_at': '2026-09-01T10:00:00Z',
    },
    {
      'id': 2,
      'codigo': 'GS-1002',
      'status': 'Aguardando coleta',
      'origem': 'Campinas',
      'destino': 'São Paulo',
      'updated_at': '2026-09-01T11:00:00Z',
    },
  ];

  final telas = <String, (String tipo, Widget Function())>{
    'Login': ('', () => const LoginScreen()),
    'Cadastro': ('', () => const CadastroScreen()),
    'Esqueceu a senha': ('', () => const EsqueceuSenhaPage()),
    'Dashboard cliente': ('Cliente', () => const TelaDashboard()),
    'Remessas cliente': ('Cliente', () => const RemessasPage()),
    'Alertas cliente': ('Cliente', () => const TelaAlertas()),
    'Mapa cliente': ('Cliente', () => const MapaPage()),
    'Perfil cliente': ('Cliente', () => const PerfilClientePage()),
    'Configurações cliente': ('Cliente', () => const ConfiguracoesPage()),
    'Alterar senha': ('Cliente', () => const AlterarSenhaPage()),
    'Editar perfil': (
      'Cliente',
      () => const EditarPerfilPage(
        nome: 'Maria Clara de Souza Albuquerque Figueiredo',
        email: 'maria.clara.albuquerque@empresa-exemplo.com.br',
        telefone: '(11) 91234-5678',
        endereco: 'Avenida Paulista, 1578 - Bela Vista, São Paulo - SP',
      ),
    ),
    'Suporte': ('Cliente', () => const SuportePage()),
    'Dashboard motorista': ('Motorista', () => const MotoristaDashboard()),
    'Entregas motorista': ('Motorista', () => const motorista.RemessasPage()),
    'Mapa motorista': ('Motorista', () => const MapaMotoristaPage()),
    'Avisos motorista': ('Motorista', () => const AvisosMotoristaPage()),
    'Configurações motorista': (
      'Motorista',
      () => const ConfiguracoesMotoristaPage(),
    ),
    'Documentos motorista': (
      'Motorista',
      () => const DocumentosMotoristaPage(),
    ),
    'Veículo motorista': ('Motorista', () => const VeiculoMotoristaPage()),
  };

  for (final MapEntry(key: nome, value: (tipo, construir)) in telas.entries) {
    testWidgets('$nome não quebra em nenhum tamanho de tela', (tester) async {
      SharedPreferences.setMockInitialValues({
        SyncEngine.cacheRemessasKey: jsonEncode(remessasEmCache),
      });
      if (tipo.isEmpty) {
        await AppSession.encerrarSessao();
      } else {
        await AppSession.iniciarSessao(
          token: 'token-teste',
          tipoUsuario: tipo,
          email: 'usuario.com.email.longo@geosync-exemplo.com.br',
          nome: 'Usuário com um Nome Completo Bem Comprido',
        );
      }

      final falhas = <String>{};
      var contexto = '';
      final original = FlutterError.onError;
      FlutterError.onError = (detalhes) {
        // Imagens de rede (tiles do mapa) sempre falham sem internet.
        if (detalhes.library == 'image resource service') return;
        final msg = detalhes.exceptionAsString().split('\n').first;
        // Aponta o widget do app que causou o erro (arquivo:linha).
        final origem = RegExp(
          r'lib/[\w/]+\.dart:\d+',
        ).firstMatch(detalhes.toString())?.group(0);
        falhas.add('[$contexto] $msg${origem == null ? '' : ' ($origem)'}');
      };

      for (final MapEntry(key: aparelho, value: tamanho) in aparelhos.entries) {
        for (final escala in escalasDeFonte) {
          for (final escuro in [false, true]) {
            tester.view.physicalSize = tamanho;
            tester.view.devicePixelRatio = 1;
            contexto =
                '$aparelho ${tamanho.width.toInt()}x${tamanho.height.toInt()}, '
                'fonte ${escala}x, ${escuro ? 'escuro' : 'claro'}';
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(escala)),
                    child: child!,
                  ),
                  home: construir(),
                ),
              ),
            );
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 300));
            }
            // Desmonta para cancelar timers e animações da tela.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
          }
        }
      }
      tester.view.reset();
      FlutterError.onError = original;
      expect(falhas, isEmpty, reason: falhas.join('\n'));
    });
  }
}
