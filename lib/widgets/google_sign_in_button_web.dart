import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget renderGoogleButton({required bool cadastro}) => google_web.renderButton(
  configuration: google_web.GSIButtonConfiguration(
    type: google_web.GSIButtonType.standard,
    theme: google_web.GSIButtonTheme.outline,
    size: google_web.GSIButtonSize.large,
    text: cadastro
        ? google_web.GSIButtonText.signupWith
        : google_web.GSIButtonText.continueWith,
    shape: google_web.GSIButtonShape.rectangular,
    locale: 'pt_BR',
    minimumWidth: 280,
  ),
);