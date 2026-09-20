# Sono e Hidratação

Este documento especifica a estrutura visual, fluxos de dados e telas relacionadas aos módulos de Sono (Sleep Logs) e Hidratação (Water Logs).

## 1. Módulo de Sono (Sleep)

O módulo de sono gerencia o registro e monitoramento dos períodos de descanso do usuário, permitindo analisar a qualidade e duração do sono ao longo do tempo.

### 1.1 Telas do Módulo
1.  **Tracker de Sono (`sleep_tracker_page`):** Exibe o resumo do sono recente, histórico de noites e o botão para registrar uma nova noite de sono.
2.  **Registro de Sono (`sleep_log_page`):** Formulário onde o usuário informa o horário de dormir, acordar e avalia a qualidade do sono.

### 1.2 Regras de Negócio e UI
*   **Período de Sono:** O usuário informa o início (`started_at`) e fim do sono (`finished_at`).
*   **Qualidade do Sono:** Escala numérica inteira de **1 a 100** (exibida na UI como um slider visual com emojis de humor ou indicador de cor de vermelho para verde).
*   **Duração Calculada:** A UI deve calcular dinamicamente a duração em minutos e horas com base nos horários selecionados antes do salvamento.
*   **Validação Condicional:** Suporta atualizações parciais (`PATCH`) caso o usuário queira mudar apenas a nota da qualidade após acordar, por exemplo.

### 1.3 Mapeamento de API (Sono)
*   **Criar Registro:** `POST /api/v1/registros-sono`
*   **Atualizar Registro (PATCH):** `PATCH /api/v1/registros-sono/{id}` (com o cabeçalho `sometimes` ativo na API, o payload pode conter apenas `{ "quality": 95 }`).
*   **Deletar Registro:** `DELETE /api/v1/registros-sono/{id}`

---

## 2. Módulo de Hidratação (Water)

O módulo de hidratação controla o consumo diário de água, comparando o volume ingerido em mililitros com a meta do perfil.

### 2.1 Telas do Módulo
1.  **Tracker de Água (`water_tracker_page`):** Exibe um copo/garrafa gigante que enche dinamicamente conforme o usuário registra o consumo, botões de atalhos rápidos (ex: +250ml, +500ml) e o histórico de copos bebidos no dia.

### 2.2 Regras de Negócio e UI
*   **Meta Diária:** Exibe o total acumulado vs. a meta diária configurada nas configurações do perfil (ex: `750ml / 2500ml`).
*   **Atalhos Rápidos:** Botões de preenchimento rápido para adicionar volumes pré-definidos (250ml, 350ml, 500ml). Ao clicar, o registro é imediatamente adicionado ao SQLite com o timestamp atual e a UI atualiza com efeito de água subindo.
*   **Lista Diária:** Permite o usuário ver o horário de cada registro d'água no dia e excluir algum copo que tenha adicionado incorretamente.

### 2.3 Mapeamento de API (Hidratação)
*   **Criar Registro:** `POST /api/v1/registros-agua`
*   **Deletar Registro:** `DELETE /api/v1/registros-agua/{id}`

---

## 3. Estrutura do SQLite Local

### Tabela: `sleep_logs`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária gerada no Flutter |
| `started_at` | `TEXT` | ISO 8601 data/hora de dormir |
| `finished_at` | `TEXT` (Nullable) | ISO 8601 data/hora de acordar |
| `quality` | `INTEGER` | Nota do sono de 1 a 100 |
| `duration_minutes` | `INTEGER` | Duração calculada em minutos |
| `synced_at` | `TEXT` (Nullable) | Data de sincronização |
| `deleted_locally` | `INTEGER` (0 ou 1) | Flag de soft delete offline |

### Tabela: `water_logs`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária gerada no Flutter |
| `amount_ml` | `INTEGER` | Quantidade de água consumida (ex: 250) |
| `logged_at` | `TEXT` | ISO 8601 data/hora do registro |
| `synced_at` | `TEXT` (Nullable) | Data de sincronização |
| `deleted_locally` | `INTEGER` (0 ou 1) | Flag de soft delete offline |
