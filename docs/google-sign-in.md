# Login e cadastro com Google

O app obtém um **ID token** pelo plugin `google_sign_in` e envia esse token ao GeoSync. O token Google não é usado como token da API. O backend precisa validá-lo e devolver a sessão GeoSync, como no login por senha.

## Configuração OAuth

Crie credenciais OAuth no Google Cloud para os identificadores reais das plataformas usadas. Os IDs de cliente são públicos; nunca inclua um segredo OAuth no app.

No Android, o `applicationId` e o SHA-1 dos certificados debug e release devem estar registrados na credencial Android. Para o ID token que será validado pelo Laravel, informe também o ID OAuth de tipo **Web application** como `GOOGLE_SERVER_CLIENT_ID`.

No iOS, informe o ID de tipo **iOS** como `GOOGLE_IOS_CLIENT_ID` e adicione o seu URL scheme reverso real em `ios/Runner/Info.plist` (`CFBundleURLTypes`). O scheme tem o formato `com.googleusercontent.apps.<id-do-cliente-ios-sem-sufixo>`. Sem esse retorno, a janela de autenticação não consegue voltar ao app.

No Flutter Web, use o botão oficial renderizado pelo Google Identity Services e informe um ID OAuth de tipo **Web application** como `GOOGLE_WEB_CLIENT_ID`. Cadastre como **Authorized JavaScript origins** cada origem usada, incluindo host, esquema e porta de desenvolvimento e o domínio de produção. O Web usa `GOOGLE_WEB_CLIENT_ID` como audiência do ID token.

Passe os IDs públicos ao executar/buildar o Flutter. Informe só os valores das plataformas que serão compiladas:

```powershell
flutter run -d android --dart-define=GOOGLE_SERVER_CLIENT_ID=seu-client-id-web.apps.googleusercontent.com
flutter run -d ios --dart-define=GOOGLE_SERVER_CLIENT_ID=seu-client-id-web.apps.googleusercontent.com --dart-define=GOOGLE_IOS_CLIENT_ID=seu-client-id-ios.apps.googleusercontent.com
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=GOOGLE_WEB_CLIENT_ID=seu-client-id-web.apps.googleusercontent.com
```

O identificador Android deve corresponder ao `applicationId` do build (`geoSyncApplicationId`, se definido). Configure os mesmos `--dart-define` no comando de produção (`flutter build apk`, `flutter build ios` ou `flutter build web`); sem eles, a ação informa qual configuração está faltando.

## Contrato necessário no backend

O backend Laravel não está neste checkout. Para uma autenticação de ponta a ponta, ele precisa implementar `POST /api/auth/google` com HTTPS e este contrato:

```json
{
  "id_token": "<ID token emitido pelo Google>",
  "intent": "login",
  "tipo": "cliente"
}
```

Para `intent: "register"`, o app também envia `cpf`, `telefone` e `aceite_termos: true`. O nome e o e-mail devem vir dos *claims* do ID token validado, nunca ser confiados a partir de dados de perfil enviados pelo cliente.

O servidor deve validar assinatura, emissor, expiração e `aud` do token com a biblioteca oficial do Google, usando o ID OAuth Web do aplicativo como audiência. Identifique usuários pelo `sub` imutável do token e aplique uma política segura ao vincular uma conta Google a uma conta existente. `login` deve recusar contas desconhecidas; `register` pode criar a conta após validar CPF, telefone e aceite dos termos.

Em caso de sucesso, retorne o mesmo envelope de `POST auth/login`, com um token GeoSync reconhecido pelas rotas autenticadas e o objeto do usuário (`email`, `name` e `tipo_usuario`). Em erro, retorne uma mensagem de validação que a API do app consiga apresentar.
