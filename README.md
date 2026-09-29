# GeoSync Mobile

Aplicativo Flutter de logística do GeoSync: clientes acompanham suas remessas e
motoristas executam entregas com rastreamento por GPS, funcionando também sem
internet. O app consome a API Laravel do GeoSync.

## Como executar

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://IP-DO-SERVIDOR:8000/api
```

A URL da API também pode ser configurada dentro do app. Em celular físico, use o
IP do computador que roda o Laravel (não `localhost`).

## Estrutura do projeto

```
lib/
├── main.dart                  # Inicialização, tema, sessão e sincronização automática
├── app_session.dart           # Sessão do usuário e preferências persistidas
├── app_theme.dart             # Tema claro/escuro
├── *_page.dart / *_screen.dart  # Telas do cliente (dashboard, remessas, perfil…)
├── motorista/                 # Telas do motorista (entregas, mapa, configurações…)
│   └── sincronizacao_widgets.dart  # Seção "Dados e sincronização"
├── services/
│   ├── api_service.dart       # Cliente HTTP da API Laravel
│   ├── api_exception.dart     # Erros de API e de conexão
│   └── notification_center.dart
├── sync/                      # Camada offline-first
│   ├── location_point.dart            # Modelo de ponto de GPS
│   ├── local_store.dart               # Persistência local (fila de pontos)
│   ├── background_location_service.dart  # Captura de localização em segundo plano
│   ├── pending_queue.dart             # Fila de ações offline e log de conflitos
│   ├── conflict_resolver.dart         # Regras de resolução de conflitos
│   ├── sync_engine.dart               # Sincronização incremental
│   └── data_exporter.dart             # Exportação CSV / GeoJSON
└── widgets/                   # Componentes visuais compartilhados

test/
├── services/                  # Testes unitários do ApiService
├── sync/                      # Testes unitários da camada de sincronização
└── integration/               # Testes de integração com servidor HTTP local
    ├── fake_api_server.dart   # Imita os endpoints da API Laravel
    ├── sync_integration_test.dart
    └── sync_ui_test.dart      # Fluxo na tela de configurações do motorista

integration_test/              # Mesmo fluxo, rodando no app em um aparelho
```

## Funcionamento offline e sincronização

O app segue o modelo **offline-first**: toda alteração do motorista e todo ponto
de GPS é gravado primeiro no aparelho e enviado quando houver conexão.

```
 GPS ──► BackgroundLocationService ──► LocationStore ─┐
                                                      ├─► SyncEngine ◄──► API Laravel
 Tela ──► ApiService (sem rede) ──► PendingQueue ─────┘        │
                                                               └─► ConflictResolver
```

A sincronização roda:

- ao abrir o app e a cada 2 minutos (motorista autenticado);
- quando o app volta ao primeiro plano;
- ao carregar a lista de remessas;
- manualmente, em **Configurações › Dados e sincronização › Sincronizar agora**.

### Captura de localização em segundo plano

`BackgroundLocationService` continua capturando com o app minimizado:

- **Android**: *foreground service* do `geolocator`, com uma notificação fixa
  ("GeoSync está rastreando sua entrega"). Não exige a permissão "o tempo todo".
- **iOS**: `allowsBackgroundLocationUpdates`, com o indicador azul na barra de
  status (`UIBackgroundModes: location` no `Info.plist`).

Leituras com precisão pior que 100 m são descartadas, e pontos redundantes
(intervalo menor que 15 s, ou 60 s no modo economia, sem deslocamento grande)
são ignorados. O rastreamento é retomado se o app for reiniciado, e para
sozinho ao sair da conta ou desativar "Localização" nas configurações. O
aparelho guarda até 5.000 pontos; os já enviados são apagados após 7 dias.

### Sincronização incremental

Cada rodada chama `GET /remessas/minhas?updated_since=<cursor>` e mescla os
registros recebidos por `id` no cache local. O cursor vem do relógio do
servidor (`meta.server_time`, ou o maior `updated_at` recebido), então o
relógio do aparelho não interfere. A cada 30 minutos é feita uma sincronização
completa, para refletir remessas excluídas.

### Resolução de conflitos

Há conflito quando a remessa mudou no servidor depois que o motorista a alterou
offline. As regras (`ConflictResolver`):

1. Se o servidor já tem o mesmo status, a ação é descartada sem conflito.
2. Status finais do servidor (`Entregue`, `Cancelada`) sempre prevalecem.
3. O status nunca regride: vence o mais avançado em
   `Aguardando coleta → Em rota → Entregue`.
4. Em empate, vence a alteração mais recente.
5. Se o servidor rejeitar o envio (409, 404, 422), o servidor prevalece e as
   ações seguintes da mesma remessa são descartadas.

Cada conflito fica registrado e pode ser consultado em **Conflitos resolvidos**.

### Exportação

Em **Exportar dados** o motorista gera e compartilha:

- **CSV** (RFC 4180, UTF-8 com BOM para o Excel e proteção contra injeção de
  fórmulas) com o histórico de localização ou as remessas;
- **GeoJSON** (RFC 7946) com um `Point` por leitura e uma `LineString` com o
  trajeto de cada remessa, pronto para QGIS, geojson.io ou Google Earth.

## Contrato esperado da API

O app funciona com a API atual. Os itens abaixo são opcionais e melhoram a
sincronização quando o backend os implementa:

| Recurso | Uso no app |
| --- | --- |
| `updated_at` nas remessas | Detecta conflitos e avança o cursor incremental |
| Filtro `updated_since` em `GET /remessas/minhas` | Baixa só o que mudou (sem ele, o app baixa tudo e continua correto) |
| `meta.server_time` na resposta | Cursor exato no relógio do servidor |
| `deleted_at` em remessas excluídas | Remove o registro sem esperar a sincronização completa |
| Deduplicação por `client_id` em `POST /localizacao` | Evita pontos duplicados após reenvio |
| `409 Conflict` ao alterar status desatualizado | O app aceita a versão do servidor e registra o conflito |

## Testes

```bash
flutter test                                  # unitários + integração (sem aparelho)
flutter test integration_test -d <aparelho>   # fluxo no app, em celular ou emulador
```

Os testes de integração sobem um servidor HTTP local que imita a API Laravel.
Eles cobrem a fila offline, os conflitos, a sincronização incremental, a
captura e o envio de localização e a exportação, sem depender de backend nem de
internet. Para rodar `integration_test` no Windows desktop é preciso ativar o
Modo de Desenvolvedor (exigência do Flutter para plugins).
