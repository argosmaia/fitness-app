# Módulo de Treinos (Workouts)

Este documento especifica a estrutura visual, fluxos de dados e telas relacionadas ao módulo de Treinos.

## 1. Telas do Módulo

O módulo é composto por três fluxos de telas principais:
1.  **Lista de Treinos (`workout_list_page`):** Exibe o histórico de treinos do usuário.
2.  **Detalhes do Treino (`workout_detail_page`):** Visualização estática dos exercícios, séries, pesos e notas de um treino já finalizado.
3.  **Execução de Treino / Registro (`workout_tracker_page`):** Tela interativa com cronômetro ativo, onde o usuário marca as séries realizadas em tempo real.

---

## 2. Especificação das Telas

### 2.1 Lista de Treinos (`workout_list_page`)
*   **Cabeçalho:** Filtro por período (Semanal / Mensal) e botão proeminente "Iniciar Novo Treino".
*   **Histórico (Cards):** Cada item da lista exibe:
    *   Nome do treino (ex: *"Treino de Peito"*).
    *   Data e horário de início.
    *   Duração em minutos (convertida de `duration_seconds`).
    *   Calorias estimadas gastas.
    *   Contador rápido de exercícios (ex: *"5 exercícios"*).
*   **Comportamento Offline:** Caso o treino não tenha sido sincronizado ainda, o card mostra um ícone de "nuvem com traço" ou "pendente" (`synced_at == null`).

### 2.2 Detalhes do Treino (`workout_detail_page`)
*   **Cabeçalho:** Nome do treino, data de execução, calorias totais e duração total.
*   **Lista de Exercícios:** Cada exercício cadastrado é exibido com:
    *   Nome do exercício.
    *   Contagem de séries (sets).
    *   Detalhes de cada série: peso (kg) e repetições (ex: *10 repetições x 80 kg*).
    *   Notas adicionais do exercício (ex: *"Aumentar peso na próxima semana"*).
*   **Ações:** Botão para "Duplicar Treino" (cria uma nova rotina baseada nesta para o usuário executar hoje) e botão de "Excluir".

### 2.3 Registro/Execução de Treino (`workout_tracker_page`)
*   **Status Ativo:**
    *   Cronômetro rodando em tempo real.
    *   Cálculo dinâmico de calorias com base no tempo decorrido e perfil do usuário.
*   **Lista de Exercícios Ativos:**
    *   Cada exercício exibe suas séries com checkboxes para o usuário marcar à medida que completa.
    *   Campos numéricos interativos para ajustar peso e repetições na hora.
    *   **Timer de Descanso:** Dispara um pop-up ou contagem regressiva visual de acordo com o `rest_seconds` do exercício sempre que uma série for marcada como concluída.
*   **Finalização:** Botão "Concluir Treino". Ao clicar, preenche o `finished_at` com o timestamp atual, calcula o `duration_seconds` total e salva localmente no SQLite.

---

## 3. Mapeamento da API

### Criar/Salvar Treino
*   **Endpoint:** `POST /api/v1/treinos`
*   **Payload Exemplo:**
```json
{
  "id": "e81d11ed-1df2-4ab8-910e-0d0fcaab038c",
  "name": "Treino de Peito",
  "description": "Focado em hipertrofia",
  "started_at": "2026-06-20T10:00:00-03:00",
  "finished_at": "2026-06-20T11:00:00-03:00",
  "duration_seconds": 3600,
  "calories": 450,
  "exercises": [
    {
      "id": "780b62d3-3563-46fb-9730-84a144e5ccb3",
      "name": "Supino Reto com Barra",
      "sets": 4,
      "reps": 10,
      "weight": 60.5,
      "rest_seconds": 90,
      "notes": "Aumentar peso na próxima semana"
    }
  ]
}
```

### Atualizar Treino (PUT ou PATCH)
*   **PUT** `api/v1/treinos/{id}` - Substitui o treino e seus exercícios completamente.
*   **PATCH** `api/v1/treinos/{id}` - Permite atualização parcial (ex: atualizar apenas o nome do treino ou notas).

### Excluir Treino
*   **DELETE** `api/v1/treinos/{id}` - Remove o treino do banco de dados (Soft Delete). No SQLite local, marca a coluna `deleted_locally = 1` para propagar a exclusão no próximo sync.

---

## 4. Estrutura do SQLite Local

### Tabela: `workouts`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária gerada no Flutter |
| `name` | `TEXT` | Nome do treino |
| `description` | `TEXT` (Nullable) | Descrição ou observação geral |
| `started_at` | `TEXT` | ISO 8601 data/hora inicial |
| `finished_at` | `TEXT` (Nullable) | ISO 8601 data/hora de término |
| `duration_seconds` | `INTEGER` | Duração em segundos |
| `calories` | `INTEGER` | Estimativa de calorias gastas |
| `synced_at` | `TEXT` (Nullable) | Data do último sync com a API |
| `deleted_locally` | `INTEGER` (0 ou 1) | Flag de soft delete offline |

### Tabela: `exercises`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária gerada no Flutter |
| `workout_id` | `TEXT` (FK) | Relacionamento com `workouts.id` |
| `name` | `TEXT` | Nome do exercício |
| `sets` | `INTEGER` | Quantidade de séries |
| `reps` | `INTEGER` (Nullable) | Repetições padrão |
| `weight` | `REAL` (Nullable) | Carga em kg |
| `rest_seconds` | `INTEGER` (Nullable) | Tempo de descanso em segundos |
| `notes` | `TEXT` (Nullable) | Observações |
