import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app_providers.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/tela_dashboard.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/sync/background_location_service.dart';
import 'package:mobile/sync/local_store.dart';
import 'package:mobile/sync/sync_engine.dart';
import 'package:mobile/widgets/responsive_content.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    AppSession.restaurar(),
    ApiService.restoreBaseUrl(),
    DataRetentionPolicy.restaurar(),
  ]);
  runApp(const ProviderScope(child: MyApp()));
  unawaited(validarSessao());
  // Sincroniza em segundo plano e retoma um rastreamento interrompido.
  SyncEngine.instance.iniciarAutomatico();
  unawaited(BackgroundLocationService.instance.restaurar());
}

/// Confirma com o servidor que o token salvo ainda é válido e atualiza nome
/// e e-mail. Um 401 encerra a sessão (tratado pelo [ApiService]); sem
/// internet a sessão salva continua valendo, para o app funcionar offline.
Future<void> validarSessao() async {
  if (!AppSession.autenticada) return;
  try {
    final usuario = ApiService.instance.authUser(
      await ApiService.instance.me(),
    );
    final email = '${usuario['email'] ?? ''}'.trim();
    final nome = '${usuario['name'] ?? usuario['nome'] ?? ''}'.trim();
    if (email.isNotEmpty && AppSession.autenticada) {
      await AppSession.atualizarDadosUsuario(
        nome: nome.isEmpty ? AppSession.nome : nome,
        email: email,
      );
    }
  } on ApiException {
    // Sem conexão ou servidor indisponível: mantém a sessão offline.
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(appSessionProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: sessao.modoEscuro ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Em telas largas (tablet, desktop, web) evita que o layout do app
      // — pensado para celular — se estique de forma pouco natural.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ResponsiveContent(child: child ?? const SizedBox.shrink()),
      ),
      home: sessao.autenticada
          ? (sessao.tipoUsuario == 'Motorista'
                ? const MotoristaDashboard()
                : const TelaDashboard(tipoUsuario: 'Cliente'))
          : const LoginScreen(),
    );
  }
}
