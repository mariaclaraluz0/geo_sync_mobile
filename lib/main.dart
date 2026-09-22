import 'package:flutter/material.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/tela_dashboard.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/responsive_content.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([AppSession.restaurar(), ApiService.restoreBaseUrl()]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.modoEscuro,
      builder: (context, escuro, _) => ValueListenableBuilder<int>(
        valueListenable: AppSession.sessaoAtualizada,
        builder: (context, _, sessionVersion) => MaterialApp(
          key: ValueKey(sessionVersion),
          debugShowCheckedModeBanner: false,
          themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          // Em telas largas (tablet, desktop, web) evita que o layout do app
          // — pensado para celular — se estique de forma pouco natural.
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ResponsiveContent(child: child ?? const SizedBox.shrink()),
          ),
          home: AppSession.autenticada
              ? (AppSession.tipoUsuario == 'Motorista'
                    ? const MotoristaDashboard()
                    : const TelaDashboard(tipoUsuario: 'Cliente'))
              : const LoginScreen(),
        ),
      ),
    );
  }
}
