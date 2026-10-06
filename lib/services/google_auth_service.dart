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
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static String? _tokenWebPendente;

  static bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get webButtonConfigurado =>
      kIsWeb && _webClientId.trim().isNotEmpty;

  static Future<void> inicializar() async {
    if (kIsWeb && _webClientId.trim().isEmpty) {
      throw const ApiException(
        'Configure GOOGLE_WEB_CLIENT_ID e autorize a origem deste site no Google Cloud.',
      );
    }
    if (!kIsWeb && _serverClientId.trim().isEmpty) {
      throw const ApiException(
        'Configure GOOGLE_SERVER_CLIENT_ID para habilitar o login Google.',
      );
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        _clientId.trim().isEmpty) {
      throw const ApiException(
        'Configure GOOGLE_IOS_CLIENT_ID e o URL scheme reverso no Info.plist.',
      );
    }
    try {
      _initialization ??= _google.initialize(
        clientId: kIsWeb
            ? _webClientId.trim()
            : _clientId.trim().isEmpty
            ? null
            : _clientId.trim(),
        serverClientId: kIsWeb ? null : _serverClientId.trim(),
      );
      await _initialization;
    } on GoogleSignInException catch (error) {
      throw ApiException(
        error.description ?? 'Não foi possível inicializar o login Google.',
      );
    }
  }

  static void receberTokenWeb(String? token) {
    _tokenWebPendente = token;
  }

  static Future<String?> signInForIdToken() async {
    if (!isSupportedPlatform) {
      throw const ApiException(
        'O login com Google está disponível no Android, iOS e Web.',
      );
    }
    await inicializar();

    if (kIsWeb) {
      final token = _tokenWebPendente;
      _tokenWebPendente = null;
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Use o botão oficial do Google para selecionar sua conta.',
        );
      }
      return token;
    }

    try {
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
