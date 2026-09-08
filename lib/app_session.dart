class AppSession {
  AppSession._();

  static String _senha = '';

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
