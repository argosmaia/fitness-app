# Perfil, Configurações e Sincronização (Sync)

Este documento especifica a estrutura visual, fluxos de dados e lógica interna para o Perfil do Usuário e o Motor de Sincronização Offline-First.

## 1. Módulo de Perfil e Configurações

O perfil centraliza as informações corporais do usuário e suas metas diárias, fundamentais para que as outras telas do aplicativo façam o cálculo nutricional e de atividade física.

### 1.1 Telas do Módulo
1.  **Perfil do Usuário (`profile_page`):** Exibe as informações atuais e permite a edição de metas e dados biométricos.
2.  **Configurações de Sincronização (`sync_settings_page`):** Exibe informações de conexão, data/hora da última sincronização bem-sucedida e botão para forçar sincronização manual.

### 1.2 Campos do Perfil (Biometria e Metas)
*   **Dados Pessoais:** Nome, E-mail, Data de Nascimento, Gênero.
*   **Dados Corporais (Medidas):** Altura (cm), Peso Atual (kg), Meta de Peso (kg).
*   **Metas Diárias:**
    *   Meta de Hidratação (ex: 2500 ml).
    *   Meta de Calorias (ex: 2200 kcal).

### 1.3 Mapeamento de API (Perfil)
*   **Obter Perfil:** `GET /api/v1/usuarios`
*   **Atualizar Perfil (PUT/PATCH):** `PUT /api/v1/usuarios` ou `PATCH /api/v1/usuarios`
    *   O endpoint suporta atualização de dados parciais. Ao alterar o peso na UI, por exemplo, o aplicativo dispara apenas o campo de peso modificado.

---

## 2. Motor de Sincronização Offline-First (Sync Engine)

A sincronização de dados segue o conceito **Device-First** (o banco de dados local SQLite é a verdade imediata para a interface do usuário). O app não espera respostas de rede para atualizar a UI.

### 2.1 Fluxo de Trabalho do Sync
Sempre que o dispositivo estiver online e o aplicativo for ativado, ou por meio de um processo agendado em segundo plano (`WorkManager` no Android / `BackgroundFetch` no iOS):

```
       [Mudança na UI]
              ↓
    [Salva no SQLite Local]
  (synced_at = null / id = UUID)
              ↓
  [Verifica se Conectado à Net]
       /             \
 [Sem Conexão]      [Com Conexão]
     /                 \
Mantém pendente.    Dispara Sync
                     (POST /sync)
                           ↓
                  [API responde 200]
                  (Retorna UUIDs salvos)
                           ↓
                  [Atualiza SQLite]
                 (synced_at = AGORA)
```

### 2.2 Endpoint de Sincronização Lote (`/sync`)
O aplicativo busca todos os registros locais onde `synced_at` seja nulo ou onde `deleted_locally` seja igual a 1 (para exclusão). Reúne tudo em um único JSON estruturado.

*   **Endpoint:** `POST /api/v1/sync`
*   **Payload de Envio (Request Body):**
```json
{
  "workouts": [
    {
      "id": "e81d11ed-1df2-4ab8-910e-0d0fcaab038c",
      "name": "Treino de Peito",
      "started_at": "2026-06-20T10:00:00-03:00",
      "finished_at": "2026-06-20T11:00:00-03:00",
      "duration_seconds": 3600,
      "calories": 450,
      "exercises": [...]
    }
  ],
  "meals": [...],
  "sleep_logs": [...],
  "water_logs": [...]
}
```

*   **Resposta com Sucesso (`200 OK`):**
    Retorna arrays contendo os UUIDs que foram salvos e processados com sucesso no banco de dados principal.
```json
{
  "status": 200,
  "mensagem": "Sincronização realizada com sucesso",
  "data": {
    "workouts": ["e81d11ed-1df2-4ab8-910e-0d0fcaab038c"],
    "meals": [],
    "sleep_logs": [],
    "water_logs": []
  }
}
```

### 2.3 Regras de Reconciliação no Flutter
Após a resposta da API:
1.  Para cada UUID retornado na lista de sucesso, o Flutter executa:
    `UPDATE {tabela} SET synced_at = DateTime.now() WHERE id = {uuid}`
2.  Para os itens que estavam marcados como `deleted_locally = 1` e foram sincronizados para exclusão, executa-se a limpeza física definitiva no banco local:
    `DELETE FROM {tabela} WHERE id = {uuid} AND deleted_locally = 1`
3.  O `syncProvider` do Riverpod emite uma notificação de sucesso e qualquer tela ativa recarrega seus dados do SQLite para refletir o status atual de sincronizado.
