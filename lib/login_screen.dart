import 'package:flutter/material.dart';
import 'package:mobile/tela_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _tipoUsuario = 'Cliente';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E3A8A),
      Color(0xFFF8FAFC),
    ],
    stops: [0, 0.35, 1],
  ),
),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // LOGO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 110,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Olá novamente 👋',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Faça login para continuar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 35),

                // CARD LOGIN
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Entre com seus dados para acessar o aplicativo.',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // TIPO DE USUÁRIO
                      const Text(
                        'Entrar como',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tipoUsuario = 'Cliente';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 250,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _tipoUsuario == 'Cliente'
                                            ? const Color(0xFF2D5F9A)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color:
                                            _tipoUsuario == 'Cliente'
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cliente',
                                        style: TextStyle(
                                          color:
                                              _tipoUsuario == 'Cliente'
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tipoUsuario = 'Motorista';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 250,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _tipoUsuario == 'Motorista'
                                            ? const Color(0xFF2D5F9A)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.local_shipping_outlined,
                                        color:
                                            _tipoUsuario == 'Motorista'
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Motorista',
                                        style: TextStyle(
                                          color:
                                              _tipoUsuario == 'Motorista'
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // EMAIL
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'seu@email.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // SENHA
                      const Text(
                        'Senha',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Digite sua senha',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // CONFIRMAR SENHA
                      const Text(
                        'Confirme sua senha',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirme sua senha',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Esqueceu sua senha?',
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // BOTÃO LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print(
                              'Login como: $_tipoUsuario',
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TelaDashboard(),
                              ),
                            );
                          },
                          icon: Icon(
                            _tipoUsuario == 'Cliente'
                                ? Icons.person
                                : Icons.local_shipping,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Entrar como $_tipoUsuario',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF2D5F9A),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Versão 1.0.0',
                  style: TextStyle(
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}