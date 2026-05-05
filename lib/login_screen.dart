import 'package:flutter/material.dart';
import 'package:mobile/tela_dashboard.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 LOGO
              Center(
                child: Image.asset(
                  'assets/logo.png', // coloque sua logo aqui
                  height: 180,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(
                  top: 1,
                ), // controla o quanto sobe
                child: Center(
                  child: Text(
                    'Bem-vindo novamente!',
                    textAlign: TextAlign.center, // centraliza o texto
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Login',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 20),

              const Text(
                'Entre com o seu email para acessar o nosso app.',
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 20),

              // 📧 EMAIL
              const Text('Email'),
              const SizedBox(height: 5),
              TextField(
                decoration: InputDecoration(
                  hintText: 'seu@email.com',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 🔒 SENHA
              const Text('Senha'),
              const SizedBox(height: 5),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '******',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 🔒 CONFIRMAR SENHA
              const Text('Confirme sua senha'),
              const SizedBox(height: 5),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '******',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 🔵 BOTÃO
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TelaDashboard()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5F9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white, // 👈 cor do texto
                    ),
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
