import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;
import 'package:mobile/services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.cadastro = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final bool cadastro;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  Future<void>? _webReady;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webEvents;

  @override
  void initState() {
    super.initState();
    if (GoogleAuthService.webButtonConfigurado) {
      _webReady = GoogleAuthService.inicializar();
      _webReady!.then(
        (_) {
          if (!mounted) return;
          _observarEventosWeb();
          setState(() {});
        },
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant GoogleSignInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onPressed != widget.onPressed && _webEvents != null) {
      unawaited(_webEvents!.cancel());
      _observarEventosWeb();
    }
  }

  void _observarEventosWeb() {
    _webEvents = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
          GoogleAuthService.receberTokenWeb(user.authentication.idToken);
          widget.onPressed?.call();
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível autenticar com o Google.'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    unawaited(_webEvents?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleAuthService.isSupportedPlatform) return const SizedBox.shrink();
    if (kIsWeb && GoogleAuthService.webButtonConfigurado) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FutureBuilder<void>(
          future: _webReady,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                snapshot.hasError ||
                widget.loading) {
              return OutlinedButton(
                onPressed: widget.loading ? null : widget.onPressed,
                child: snapshot.hasError
                    ? Text(widget.label)
                    : const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: google_web.renderButton(
                configuration: google_web.GSIButtonConfiguration(
                  type: google_web.GSIButtonType.standard,
                  theme: google_web.GSIButtonTheme.outline,
                  size: google_web.GSIButtonSize.large,
                  text: widget.cadastro
                      ? google_web.GSIButtonText.signupWith
                      : google_web.GSIButtonText.continueWith,
                  shape: google_web.GSIButtonShape.rectangular,
                  locale: 'pt_BR',
                  minimumWidth: 280,
                ),
              ),
            );
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: widget.loading ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: widget.loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.google,
                    size: 20,
                    color: Color(0xFF4285F4),
                    semanticLabel: 'Google',
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
