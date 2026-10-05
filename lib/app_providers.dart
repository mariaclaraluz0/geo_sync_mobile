import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app_session.dart';

@immutable
class AppSessionState {
  const AppSessionState({
    required this.autenticada,
    required this.tipoUsuario,
    required this.nome,
    required this.email,
    required this.modoEscuro,
  });

  factory AppSessionState.ler() => AppSessionState(
    autenticada: AppSession.autenticada,
    tipoUsuario: AppSession.tipoUsuario,
    nome: AppSession.nome,
    email: AppSession.email,
    modoEscuro: AppSession.modoEscuro.value,
  );

  final bool autenticada;
  final String tipoUsuario;
  final String nome;
  final String email;
  final bool modoEscuro;
}

final appSessionProvider =
    NotifierProvider<AppSessionController, AppSessionState>(
      AppSessionController.new,
    );

/// Bridge temporária: a inicialização e persistência continuam no AppSession,
/// enquanto as telas migram para observar estado pelo Riverpod.
class AppSessionController extends Notifier<AppSessionState> {
  late final VoidCallback _sessaoListener;
  late final VoidCallback _temaListener;

  @override
  AppSessionState build() {
    _sessaoListener = () => state = AppSessionState.ler();
    _temaListener = () => state = AppSessionState.ler();
    AppSession.sessaoAtualizada.addListener(_sessaoListener);
    AppSession.modoEscuro.addListener(_temaListener);
    ref.onDispose(() {
      AppSession.sessaoAtualizada.removeListener(_sessaoListener);
      AppSession.modoEscuro.removeListener(_temaListener);
    });
    return AppSessionState.ler();
  }

  Future<void> definirModoEscuro(bool valor) =>
      AppSession.definirModoEscuro(valor);
}
