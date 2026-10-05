# Integração de notificações push

O cliente não envia nem registra tokens push porque o backend e a configuração
Firebase não estão neste checkout. Não use endpoints presumidos: confirme os
nomes e payloads com o backend antes de ativar o envio.

## Contrato necessário com o backend

- endpoint autenticado para registrar, atualizar e revogar o token do dispositivo;
- associação do token ao usuário e à instalação, com remoção no logout;
- eventos versionados: `remessa.status_alterado`, `remessa.ocorrencia` e
  `remessa.nova_entrega`;
- payload sem endereço, telefone, nome de destinatário ou coordenadas; inclua
  somente `event_id`, `type`, `remessa_id` e uma rota interna;
- deduplicação por `event_id`, expiração e política de retentativa;
- preferências por evento respeitadas no servidor.

## Configuração de plataforma pendente

1. Criar os apps Android/iOS no projeto Firebase da organização e instalar os
   arquivos `google-services.json` e `GoogleService-Info.plist` fora do controle
   de versão quando contiverem credenciais privadas.
2. Configurar APNs no Firebase, capabilities de Push Notifications e Remote
   notifications no Xcode, além da permissão contextual no Android 13+.
3. Implementar o registro/revogação de tokens conforme o contrato aprovado.
4. Tratar toque em notificação e abrir a remessa após autenticação; não colocar
   conteúdo pessoal no texto enviado à tela bloqueada.
5. Testar app em primeiro plano, segundo plano, encerrado, logout, token
   renovado e permissão negada em aparelhos reais.

O app já tem preferências visuais de notificações, mas hoje elas controlam os
avisos locais existentes. Não representam uma inscrição push no servidor.
