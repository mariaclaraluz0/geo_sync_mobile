import 'package:flutter/material.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/tela_dashboard.dart';
import 'package:mobile/motorista/motorista_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.restaurar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.modoEscuro,
      builder: (context, escuro, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: AppSession.autenticada
            ? (AppSession.tipoUsuario == 'Motorista'
                  ? const MotoristaDashboard()
                  : const TelaDashboard(tipoUsuario: 'Cliente'))
            : const LoginScreen(),
      ),
    );
  }
}
