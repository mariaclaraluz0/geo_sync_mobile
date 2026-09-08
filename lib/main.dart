import 'package:flutter/material.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/app_session.dart';

void main() {
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
        home: const LoginScreen(),
      ),
    );
  }
}
