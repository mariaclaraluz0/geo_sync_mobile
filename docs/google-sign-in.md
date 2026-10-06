# Login com Google

O app obtém um **ID token** pelo plugin `google_sign_in` e envia esse token ao GeoSync. O token Google não é usado como token da API. O backend precisa validá-lo e devolver a sessão GeoSync, como no login por senha.

## Configuração OAuth

Crie credenciais OAuth no Google Cloud para os identificadores reais de Android e iOS do aplicativo. No Android, registre também o SHA-1 de cada certificado de assinatura usado (debug e release). Sem `google-services.json`, o app precisa receber o ID OAuth de tipo **Web application** como `GOOGLE_SERVER_CLIENT_ID`.

Inicie o Flutter com os IDs OAuth:

```powershell
flutter run `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=seu-client-id-web.apps.googleusercontent.com `
  --dart-define=GOOGLE_IOS_CLIENT_ID=seu-client-id-ios.apps.googleusercontent.com
```

`GOOGLE_IOS_CLIENT_ID` só é usado no iOS. No Xcode, configure o URL scheme reverso do cliente iOS em `ios/Runner/Info.plist` (`CFBundleURLTypes`) para que o Google consiga retornar ao app. O identificador Android deve corresponder ao `applicationId` usado no build (`geoSyncApplicationId`, quando definido).

Os IDs OAuth são identificadores públicos do cliente. Nunca coloque segredos de cliente OAuth no app; a validação deve ocorrer no servidor.

## Contrato necessário no backend

O backend Laravel deste projeto não está neste checkout. Implemente `POST /api/auth/google` com HTTPS e este contrato:

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
