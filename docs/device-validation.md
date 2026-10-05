# Validação em aparelhos reais

Os testes automatizados cobrem fluxo e fila contra um servidor HTTP local. Eles
não substituem esta verificação em Android e iOS físicos.

## Matriz antes de publicar

| Cenário | Android | iOS | Resultado a registrar |
|---|---|---|---|
| Permitir localização durante o uso e iniciar rota | ☐ | ☐ | Ponto gravado e indicador de rastreamento visível |
| Permitir localização em segundo plano | ☐ | ☐ | Ponto continua sendo gravado com tela bloqueada |
| Encerrar o app pelo seletor e reabrir | ☐ | ☐ | Serviço retoma sem duplicar pontos |
| Alternar Wi-Fi, dados móveis e modo avião | ☐ | ☐ | A fila preserva ações e GPS e envia uma vez ao reconectar |
| Responder `429` com `Retry-After` | ☐ | ☐ | A fila espera o intervalo solicitado |
| Responder `500` repetidamente | ☐ | ☐ | Ação continua persistida com espera progressiva |
| Colocar aparelho em economia de bateria | ☐ | ☐ | Registrar atrasos, restrições e fabricante/versão |
| Negar permissão e conceder depois nas configurações | ☐ | ☐ | App explica estado e retoma após concessão |
| Reiniciar aparelho com rota ativa | ☐ | ☐ | Estado e dados pendentes são recuperados |
| Apagar dados locais no app | ☐ | ☐ | Confirmação alerta sobre fila não sincronizada |

Para cada execução, anotar modelo, versão do sistema, versão do app, estado da
bateria, permissões concedidas e logs `[Sync]`/`[API]`. Executar primeiro em
ambiente de homologação, com uma conta e remessas de teste.
