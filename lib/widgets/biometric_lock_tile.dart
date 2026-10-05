import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile/app_session.dart';
import 'package:mobile/services/biometric_lock_service.dart';
import 'package:mobile/widgets/settings_widgets.dart';

class BiometricLockTile extends StatefulWidget {
  const BiometricLockTile({super.key, BiometricLockService? service})
    : _service = service;

  final BiometricLockService? _service;

  @override
  State<BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends State<BiometricLockTile> {
  late final BiometricLockService _service;
  bool _disponivel = false;
  bool _verificando = true;
  bool _alterando = false;
  String? _erro;

  bool get _plataformaCompativel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? BiometricLockService();
    if (_plataformaCompativel) _verificarDisponibilidade();
  }

  Future<void> _verificarDisponibilidade() async {
    try {
      final disponivel = await _service.disponivel;
      if (mounted) setState(() => _disponivel = disponivel);
    } on LocalAuthException catch (error) {
      debugPrint(
        '[Biometria] não foi possível verificar disponibilidade: $error',
      );
      if (mounted) {
        setState(() => _erro = 'Não foi possível verificar este aparelho.');
      }
    } on PlatformException catch (error) {
      debugPrint('[Biometria] erro ao verificar disponibilidade: $error');
      if (mounted) {
        setState(() => _erro = 'Não foi possível verificar este aparelho.');
      }
    } on MissingPluginException catch (error) {
      debugPrint('[Biometria] plugin indisponível: $error');
      if (mounted) {
        setState(() => _erro = 'Biometria indisponível nesta instalação.');
      }
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _alterar(bool ativar) async {
    if (_alterando) return;
    setState(() => _alterando = true);
    try {
      if (ativar && !await _service.autenticar()) {
        if (mounted) {
          showSettingsMessage(
            context,
            'Autenticação cancelada. O bloqueio não foi ativado.',
            error: true,
          );
        }
        return;
      }
      await AppSession.definirBloqueioBiometrico(ativar);
      if (mounted) {
        showSettingsMessage(
          context,
          ativar
              ? 'Bloqueio biométrico ativado.'
              : 'Bloqueio biométrico desativado.',
        );
      }
    } on LocalAuthException catch (error) {
      debugPrint('[Biometria] falha na autenticação: $error');
      if (mounted) {
        showSettingsMessage(
          context,
          'Não foi possível autenticar. Verifique a biometria ou o bloqueio de tela do aparelho.',
          error: true,
        );
      }
    } on PlatformException catch (error) {
      debugPrint('[Biometria] erro da plataforma: $error');
      if (mounted) {
        showSettingsMessage(
          context,
          'Não foi possível autenticar neste aparelho.',
          error: true,
        );
      }
    } on MissingPluginException catch (error) {
      debugPrint('[Biometria] plugin indisponível: $error');
      if (mounted) {
        showSettingsMessage(
          context,
          'Biometria indisponível nesta instalação.',
          error: true,
        );
      }
    } on StateError catch (error) {
      debugPrint('[Biometria] falha ao salvar preferência: $error');
      if (mounted) {
        showSettingsMessage(
          context,
          'Não foi possível salvar essa preferência. Tente novamente.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _alterando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_plataformaCompativel) return const SizedBox.shrink();
    if (_verificando) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Bloqueio biométrico'),
        subtitle: Text('Verificando suporte do aparelho…'),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.bloqueioBiometricoAtivo,
      builder: (context, ativado, _) => SettingsSwitchTile(
        icon: Icons.fingerprint,
        color: SettingsColors.blue,
        title: 'Bloqueio biométrico',
        subtitle:
            _erro ??
            (_disponivel
                ? ativado
                      ? 'Solicitado ao abrir o app'
                      : 'Use biometria ou o bloqueio de tela do aparelho'
                : 'Configure biometria ou PIN/senha no aparelho'),
        value: ativado,
        enabled: _disponivel && !_alterando,
        onChanged: _alterar,
      ),
    );
  }
}
