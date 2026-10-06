import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/services/api_exception.dart';

/// Starts native Google authentication and returns a signed ID token.
/// The ID token must be exchanged by the GeoSync API before creating a session.
class GoogleAuthService {
  GoogleAuthService._();

  static final _google = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static const _clientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<String?> signInForIdToken() async {
    if (!isSupportedPlatform) {
      throw const ApiException(
        'O login com Google está disponível no app Android e iOS.',
      );
    }
    if (_serverClientId.trim().isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            _clientId.trim().isEmpty)) {
      throw const ApiException(
        'Configure GOOGLE_SERVER_CLIENT_ID e, no iOS, GOOGLE_IOS_CLIENT_ID para ativar o login com Google.',
      );
    }

    try {
      _initialization ??= _google.initialize(
        clientId: _clientId.trim().isEmpty ? null : _clientId.trim(),
        serverClientId: _serverClientId.trim(),
      );
      await _initialization;
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      try {
        await _google.signOut();
      } on GoogleSignInException {
        // A cleanup failure must not discard an otherwise valid ID token.
      }
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'O Google não retornou um token de identidade. Tente novamente.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException(
        error.description ?? 'Não foi possível entrar com a conta Google.',
      );
    }
  }
}
