# Validacao em aparelhos reais

Os testes automatizados cobrem os fluxos do app contra um servidor HTTP local.
A integracao com o modulo IoT precisa ser validada com um equipamento de teste e
uma API acessivel.

## Matriz antes de publicar

| Cenario | Android | iOS | Resultado a registrar |
|---|---|---|---|
| Modulo IoT publica coordenadas vinculadas a uma remessa | ☐ | ☐ | API aceita o ponto e retorna no historico daquela remessa |
| Entrar como motorista | ☐ | ☐ | Lista mostra apenas remessas autorizadas ao motorista |
| Entrar como cliente | ☐ | ☐ | Lista mostra apenas remessas autorizadas ao cliente |
| Selecionar outra remessa | ☐ | ☐ | Mapa troca para somente os pontos da remessa selecionada |
| Remessa sem pontos enviados pelo IoT | ☐ | ☐ | Mapa mostra estado vazio, sem usar GPS do aparelho |
| Atualizar localizacao IoT | ☐ | ☐ | Historico e marcador refletem os pontos mais recentes |
| Alternar Wi-Fi, dados moveis e modo aviao | ☐ | ☐ | Mapa informa falha de rede e volta a carregar ao reconectar |
| Responder `429` com `Retry-After` | ☐ | ☐ | A fila de acoes espera o intervalo solicitado |
| Responder `500` repetidamente | ☐ | ☐ | Acao continua persistida com espera progressiva |
| Apagar dados locais no app | ☐ | ☐ | Confirmacao alerta sobre a fila offline |