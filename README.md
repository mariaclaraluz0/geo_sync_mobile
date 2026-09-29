<div align="center">

<img src="https://capsule-render.vercel.app/api?type=rect&color=0:0D47A1,100:1976D2&height=140&section=header&text=Geo%20Sync%20Mobile&fontSize=42&fontColor=ffffff&fontAlignY=45&desc=Rastreamento%20de%20entregas%20com%20sincroniza%C3%A7%C3%A3o%20offline&descAlignY=68&descSize=16" alt="Geo Sync Mobile" width="100%" />

<br/>

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-1976D2?style=flat-square&labelColor=0D47A1)
![Versão](https://img.shields.io/badge/vers%C3%A3o-0.1.0-1976D2?style=flat-square&labelColor=0D47A1)
![Plataforma](https://img.shields.io/badge/plataforma-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Web-1976D2?style=flat-square&labelColor=0D47A1)
![Flutter](https://img.shields.io/badge/Flutter-Dart%20%5E3.10-1976D2?style=flat-square&labelColor=0D47A1&logo=flutter&logoColor=white)
![Testes](https://img.shields.io/badge/testes-92%20passando-2E7D32?style=flat-square&labelColor=0D47A1)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-1976D2?style=flat-square&labelColor=0D47A1)

</div>

---

## Sumário

- [Visão geral](#visão-geral)
- [Novidades desta versão](#novidades-desta-versão)
- [Principais recursos](#principais-recursos)
- [Arquitetura](#arquitetura)
- [Tecnologias](#tecnologias)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [API esperada (backend)](#api-esperada-backend)
- [Permissões](#permissões)
- [Uso](#uso)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Testes](#testes)
- [Solução de problemas](#solução-de-problemas)
- [Segurança e privacidade](#segurança-e-privacidade)
- [Roadmap](#roadmap)
- [Contribuição](#contribuição)
- [Licença](#licença)
- [Contato](#contato)

---

## Visão geral

O **Geo Sync Mobile** é um aplicativo Flutter de logística que conecta **clientes** e **motoristas**. O cliente acompanha suas remessas, alertas e a frota no mapa. O motorista aceita entregas, atualiza o status e tem a localização rastreada, **inclusive com o app em segundo plano e sem internet**.

O app funciona no modelo *offline-first*: as alterações feitas sem conexão ficam em uma fila local e são enviadas à API Laravel quando a internet volta. Se houver conflito com o servidor, ele é resolvido por regras definidas.

Uma única base de código atende Android e iOS. Também roda em Windows e no navegador, o que é útil no desenvolvimento e na exportação de dados.

## Novidades desta versão

| Área | O que mudou |
|---|---|
| **Autenticação** | O token salvo é validado com `auth/me` ao abrir o app. Token expirado ou revogado encerra a sessão, e sem internet a sessão offline é mantida. "Esqueci a senha" agora envia um link real por e-mail (`auth/forgot-password`). |
| **Exportação** | Nova folha "Exportar dados": mostra quantos registros há em cada opção, **salva o arquivo** no computador (*Salvar como…*) ou **baixa** no navegador, e **compartilha** no celular. As remessas são sincronizadas antes de exportar. |
| **Editar perfil** | Tela redesenhada com cartões por seção, máscara de telefone, validação em tempo real, foto com remoção, aviso de alterações não salvas e layout em duas colunas no tablet. |
| **Alterar senha** | Medidor de força, lista de requisitos que é marcada enquanto você digita, confirmação visual e suporte a gerenciadores de senha. Mínimo de 8 caracteres. |
| **Meu veículo** | Cartão com prévia ao vivo e placa no padrão Mercosul. Os dados agora **ficam salvos no aparelho** (antes eram perdidos ao reiniciar). |
| **Área do cliente** | Aba *Carteira* removida. A navegação ficou com Início, Remessas, Mapa e Alertas. |
| **Área do motorista** | Ícones unificados na família *Rounded* do Material. |
| **Responsividade** | Todas as telas foram auditadas de 320 px até tablet, com fonte ampliada e temas claro e escuro, sem nenhum overflow. Botões têm altura mínima de 48 px. |
| **Modo escuro** | Corrigidos textos ilegíveis (texto escuro sobre fundo escuro) no login, no cadastro, nas entregas, nos alertas e no mapa, além do SnackBar do tema claro. |
| **Erros do servidor** | Erros 5xx (ex.: SQL do Laravel) não aparecem mais crus para o usuário. O detalhe técnico vai para o log `[API]`. |

## Principais recursos

| Recurso | Descrição |
|---|---|
| Autenticação | Login e cadastro de cliente ou motorista, validação da sessão, logout e recuperação de senha |
| Remessas | Listagem, filtros, detalhes, histórico e registro de ocorrências |
| Rastreamento em segundo plano | GPS contínuo durante a entrega (*foreground service* no Android e modo *background location* no iOS), com filtro de precisão e modo economia |
| Sincronização incremental | Envia `updated_since` para baixar só o que mudou e faz uma sincronização completa periódica (30 min) para detectar exclusões |
| Fila offline | Ações feitas sem internet (aceitar entrega, mudar status) e pontos de GPS são gravados localmente e enviados depois |
| Resolução de conflitos | Regras por status e data. O histórico de conflitos resolvidos fica visível nas configurações do motorista |
| Mapa | Mapa interativo (`flutter_map`) com a posição e as remessas ativas |
| Exportação | Localizações e remessas em **CSV** (Excel/Planilhas) ou **GeoJSON** (QGIS, geojson.io, Google Earth) |
| Perfil e veículo | Edição de dados pessoais, foto, senha e dados do veículo |
| Tema | Claro e escuro, com layout responsivo para celular, tablet e desktop |

## Arquitetura

```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#E3F2FD','primaryBorderColor':'#1976D2','primaryTextColor':'#0D47A1','lineColor':'#0D47A1','secondaryColor':'#BBDEFB'}}}%%
flowchart LR
    UI[Telas<br/>Cliente e Motorista] --> API[ApiService]
    UI --> SYNC[SyncEngine]
    GPS[BackgroundLocationService] --> STORE[(Armazenamento local<br/>fila, pontos, cache)]
    API -- sem internet --> STORE
    SYNC <--> STORE
    SYNC --> CR[ConflictResolver]
    SYNC <--> API
    API <--> BE[API Laravel]
    STORE --> EXP[ExportService<br/>CSV / GeoJSON]
```

**Fluxo resumido:**

1. As telas chamam o `ApiService`. Sem conexão, as ações do motorista vão para a fila local (`PendingQueue`).
2. O `BackgroundLocationService` grava cada leitura de GPS no aparelho **antes** de qualquer envio, então nada se perde offline.
3. O `SyncEngine` roda a cada 2 minutos e sempre que o app volta ao primeiro plano. Ele baixa as alterações, aplica o `ConflictResolver`, envia a fila e os pontos de GPS em lotes.
4. O `ExportService` gera os arquivos a partir dos dados locais.

## Tecnologias

| Finalidade | Tecnologia |
|---|---|
| Aplicativo | Flutter / Dart (`^3.10.8`) |
| Mapas | `flutter_map`, `latlong2` |
| Localização | `geolocator` (inclusive em segundo plano) |
| Câmera e galeria | `image_picker` |
| Comunicação | `http` (REST API Laravel com token Bearer/Sanctum) |
| Armazenamento local | `shared_preferences`, `path_provider`, `flutter_secure_storage` (token) |
| Exportação | `share_plus` (compartilhar) e `file_selector` (*Salvar como…*) |
| Qualidade | `flutter_lints`, `flutter_test`, `integration_test` |
| Controle de versão | Git e GitHub |

## Pré-requisitos

- [Git](https://git-scm.com/) 2.30 ou superior
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal estável, compatível com Dart `^3.10.8`)
- Para celular: Android Studio ou Xcode, com emulador ou dispositivo físico
- Para Windows: Visual Studio com *Desktop development with C++* e o **Modo de desenvolvedor** ativado (*Configurações → Sistema → Para desenvolvedores*), exigido pelos plugins
- O backend Laravel do GeoSync em execução (veja [API esperada](#api-esperada-backend))

Confira o ambiente com `flutter doctor`.

## Instalação

```bash
# Clonar o repositório
git clone https://github.com/mariaclaraluz0/geo_sync_mobile.git

# Acessar o diretório do projeto
cd geo_sync_mobile

# Instalar as dependências
flutter pub get
```

## Configuração

A URL da API (incluindo o sufixo `/api`) pode ser definida de duas formas.

**1. Na execução**, com `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000/api
```

**2. Dentro do app**, na tela de login, em **Configurar servidor da API**. O valor fica salvo no aparelho e é usado nas próximas execuções.

> **Dica:** em emulador Android, `localhost` aponta para o próprio emulador. Use o IP da máquina na rede (ex.: `192.168.0.10`) ou `10.0.2.2`.

> **Importante:** nunca versione chaves, tokens ou URLs de produção no repositório.

## API esperada (backend)

Principais rotas usadas pelo app (prefixo `/api`, autenticação por `Authorization: Bearer <token>`):

| Grupo | Rotas |
|---|---|
| Autenticação | `POST auth/login`, `POST auth/register`, `GET auth/me`, `POST auth/logout`, `POST auth/forgot-password`, `PUT perfil` |
| Remessas | `GET remessas/minhas?updated_since=<ISO-8601>`, `GET remessas/disponiveis`, `POST remessas/{id}/aceitar`, `PATCH remessas/{id}/status`, `GET remessas/{id}/historico` |
| Localização | `POST localizacao`, `GET localizacao`, `GET localizacao/remessa/{id}`, `GET localizacao/remessa/{id}/ultima` |
| Motorista | `GET motorista/avisos`, `PATCH motorista/avisos/{id}/lido`, `PATCH motorista/avisos/lidos`, `GET motorista/documentos` |
| Outros | `alertas`, `avaliacoes`, `contatos` |

Para a sincronização funcionar bem, recomenda-se que o backend:

- devolva `updated_at` em cada remessa e, se possível, `meta.server_time`, que o app usa como cursor da sincronização incremental;
- trate `POST localizacao` como idempotente pelo campo `client_id`, pois o mesmo ponto pode ser reenviado depois de uma falha de rede;
- responda `409` quando uma alteração de status for recusada por conflito.

## Permissões

| Plataforma | Arquivo | Permissões |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`, `POST_NOTIFICATIONS` |
| iOS | `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes: location` |

No Android, o rastreamento em segundo plano roda como *foreground service*, com a notificação fixa "GeoSync está rastreando sua entrega". Por isso ele não exige a permissão de localização "o tempo todo".

## Uso

```bash
# Executar em modo de desenvolvimento
flutter run --dart-define=API_BASE_URL=<url-da-api>

# Executar no Windows ou no navegador
flutter run -d windows
flutter run -d chrome

# Gerar build de produção (Android)
flutter build apk --release

# Gerar bundle para a Play Store
flutter build appbundle --release

# Gerar build iOS
flutter build ipa --release
```

**Exportar dados (motorista):** *Perfil → Configurações → Exportar dados*. Escolha **Localizações** ou **Remessas** e o formato **CSV** ou **GeoJSON**:

- no computador, use **Salvar arquivo**;
- no navegador, use **Baixar arquivo**;
- no celular, use **Exportar e compartilhar**.

## Estrutura do projeto

```
geo_sync_mobile/
├── lib/
│   ├── main.dart                 # Inicialização, validação da sessão e sync automático
│   ├── app_session.dart          # Sessão, preferências e dados do motorista
│   ├── app_theme.dart            # Temas claro/escuro e estilo dos botões
│   ├── login_screen.dart, cadastro_screen.dart, esqueceu_senha_page.dart
│   ├── tela_dashboard.dart       # Área do cliente (Início, Remessas, Mapa, Alertas)
│   ├── editar_perfil_page.dart, alterar_senha_page.dart, perfil_page.dart
│   ├── motorista/                # Área do motorista (dashboard, entregas, mapa,
│   │                             # veículo, documentos, avisos, configurações)
│   ├── services/                 # ApiService, exceções e central de notificações
│   ├── sync/                     # SyncEngine, fila offline, GPS em segundo plano,
│   │                             # conflitos, armazenamento local e exportação
│   └── widgets/                  # Componentes reutilizáveis (cabeçalho, formulários,
│                                 # grade adaptativa, configurações)
├── test/
│   ├── integration/              # App + HTTP real contra um servidor fake local
│   ├── services/, sync/          # Testes unitários
│   └── ui/                       # Telas: layout responsivo, perfil, senha, veículo, exportação
├── integration_test/             # Fluxo completo em dispositivo/emulador
├── android/, ios/, windows/, web/
└── pubspec.yaml
```

## Testes

```bash
# Análise estática
flutter analyze

# Testes unitários, de widget e de integração com servidor HTTP local (92 testes)
flutter test

# Testes em dispositivo ou emulador
flutter test integration_test
```

| Suíte | O que cobre |
|---|---|
| `test/integration/sync_integration_test.dart` | Fila offline, sincronização incremental, conflitos, GPS em segundo plano e exportação, contra um servidor HTTP real (`FakeApiServer`) |
| `test/integration/auth_integration_test.dart` | Login, token expirado, validação da sessão ao abrir, logout, recuperação de senha e troca de conta |
| `test/ui/screens_layout_test.dart` | Cada tela em 4 tamanhos (320 px até tablet), fonte 1,0x e 1,3x, temas claro e escuro: falha se houver overflow |
| `test/ui/perfil_senha_test.dart`, `veiculo_test.dart`, `exportar_test.dart` | Comportamento das telas redesenhadas e gravação real dos arquivos exportados |

## Solução de problemas

| Sintoma | Causa e solução |
|---|---|
| Mapa mostra *"O servidor encontrou um erro"* e o log exibe `Unknown column 'localizacoes.fonte'` | O backend usa a coluna `fonte`, que não existe no banco. No servidor Laravel, rode `php artisan migrate` ou crie uma migration que adicione `fonte` (`string`, `nullable`) à tabela `localizacoes`. |
| *"Não foi possível acessar …"* | O Laravel não está rodando ou a URL está errada. Confira IP, porta e o sufixo `/api` em **Configurar servidor da API**. |
| O app volta para o login sozinho | O servidor respondeu `401`: o token expirou ou foi revogado. Basta entrar novamente. |
| Build do Windows falha com erro de *symlink* | Ative o Modo de desenvolvedor do Windows e rode `flutter pub get`. |
| Exportação avisa que não há localizações | Os pontos só são gravados enquanto o rastreamento de uma entrega está ativo. |

## Segurança e privacidade

- Localização é dado pessoal. O tratamento deve observar a LGPD (Lei nº 13.709/2018).
- **HTTPS obrigatório em produção:** no Android, `usesCleartextTraffic="false"` no manifest principal; HTTP só é liberado no build de debug (`android/app/src/debug/AndroidManifest.xml`). No iOS, `NSAllowsLocalNetworking` permite HTTP apenas na rede local. O build release também recusa URLs `http://` ao configurar o servidor.
- Erros internos do servidor não são exibidos ao usuário, para não expor a estrutura do banco.
- A recuperação de senha responde da mesma forma para e-mails cadastrados ou não, para não revelar quais contas existem.
- Os dados locais de um usuário são apagados quando outra conta entra no mesmo aparelho.
- **Token no cofre do sistema** (`flutter_secure_storage`): Keystore no Android, Keychain no iOS e Credential Locker no Windows. Tokens de versões antigas são migrados automaticamente do `shared_preferences`, e o backup automático do Android está desativado para o cofre.

## Roadmap

- [x] Estrutura inicial do projeto
- [x] Captura de fotos e localização
- [x] Visualização em mapa
- [x] Captura de localização em segundo plano
- [x] Sincronização incremental
- [x] Resolução de conflitos de dados
- [x] Exportação de dados (CSV/GeoJSON)
- [x] Autenticação de usuários
- [x] Testes de integração abrangentes
- [x] Layout responsivo e modo escuro revisados
- [x] Armazenamento seguro do token (`flutter_secure_storage`)
- [x] Desativar `usesCleartextTraffic` no build de produção

## Contribuição

Contribuições são bem-vindas. Para colaborar:

1. Faça um fork do repositório.
2. Crie uma branch a partir da `main`: `git checkout -b feature/nome-da-feature`
3. Realize os commits seguindo o padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/): `git commit -m "feat: descrição da alteração"`
4. Rode `flutter analyze` e `flutter test` antes de enviar.
5. Envie a branch: `git push origin feature/nome-da-feature`
6. Abra um Pull Request descrevendo as mudanças realizadas.

## Licença

Distribuído sob a licença MIT.

## Contato

**Maria Clara Luz**

[![GitHub](https://img.shields.io/badge/GitHub-mariaclaraluz0-0D47A1?style=flat-square&logo=github&logoColor=white)](https://github.com/mariaclaraluz0)

Link do projeto: [github.com/mariaclaraluz0/geo_sync_mobile](https://github.com/mariaclaraluz0/geo_sync_mobile)

---

<div align="center">
<sub>Desenvolvido por Maria Clara Luz</sub>
</div>
