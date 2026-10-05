import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/biometric_lock_service.dart';

class BiometricLockGate extends StatefulWidget {
  const BiometricLockGate({
    super.key,
    required this.child,
    BiometricLockService? service,
  }) : _service = service;

  final Widget child;
  final BiometricLockService? _service;

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate> {
  late final BiometricLockService _service;
  late final bool _bloqueadoAoIniciar;
  bool _autenticando = false;
  bool _encerrandoSessao = false;
  bool _autorizado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? BiometricLockService();
    _bloqueadoAoIniciar =
        AppSession.autenticada && AppSession.bloqueioBiometricoAtivo.value;
    if (_bloqueadoAoIniciar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_autenticar());
      });
    }
  }

  Future<void> _autenticar() async {
    if (_autenticando || _autorizado) return;
    setState(() {
      _autenticando = true;
      _erro = null;
    });
    try {
      final autorizado = await _service.autenticar();
      if (mounted) {
        setState(() {
          _autorizado = autorizado;
          _erro = autorizado
              ? null
              : 'Autenticação não concluída. Tente novamente.';
        });
      }
    } on LocalAuthException catch (error) {
      debugPrint('[Biometria] falha ao desbloquear: $error');
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível autenticar. Use a biometria ou o PIN/senha do aparelho.',
        );
      }
    } on PlatformException catch (error) {
      debugPrint('[Biometria] erro ao desbloquear: $error');
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível autenticar. Use a biometria ou o PIN/senha do aparelho.',
        );
      }
    } on MissingPluginException catch (error) {
      debugPrint('[Biometria] plugin indisponível ao desbloquear: $error');
      if (mounted) {
        setState(
          () => _erro =
              'Biometria indisponível nesta instalação. Tente atualizar o app.',
        );
      }
    } finally {
      if (mounted) setState(() => _autenticando = false);
    }
  }

  Future<void> _voltarAoLogin() async {
    if (_encerrandoSessao) return;
    setState(() => _encerrandoSessao = true);
    try {
      await AppSession.definirBloqueioBiometrico(false);
      await AppSession.encerrarSessao();
    } on PlatformException catch (error) {
      debugPrint('[Biometria] falha ao voltar ao login: $error');
      if (mounted) {
        setState(
          () => _erro = 'Não foi possível encerrar a sessão. Tente novamente.',
        );
      }
    } on StateError catch (error) {
      debugPrint('[Biometria] falha ao desativar bloqueio: $error');
      if (mounted) {
        setState(
          () =>
              _erro = 'Não foi possível desativar o bloqueio. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _encerrandoSessao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_bloqueadoAoIniciar || !AppSession.autenticada || _autorizado) {
      return widget.child;
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint, size: 72, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Desbloquear GeoSync',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confirme sua identidade com biometria ou PIN/senha do aparelho para continuar.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _erro!,
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _autenticando || _encerrandoSessao
                        ? null
                        : _autenticar,
                    icon: _autenticando || _encerrandoSessao
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: Text(
                      _autenticando
                          ? 'Verificando…'
                          : _encerrandoSessao
                          ? 'Encerrando sessão…'
                          : 'Tentar novamente',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _autenticando || _encerrandoSessao
                        ? null
                        : _voltarAoLogin,
                    child: const Text('Sair e usar senha da conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
