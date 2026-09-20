# Dieta, Alimentos e Refeições

Este documento especifica a estrutura visual, fluxos de dados e telas relacionadas ao módulo de Alimentação (Diet, Food & Meals) baseado na tabela TACO integrada.

## 1. Telas do Módulo

O fluxo de dieta e alimentação é composto por:
1.  **Diário de Alimentação (`food_journal_page`):** Exibe as refeições divididas por categorias (Café da manhã, Almoço, Jantar, Lanches) e a somatória de macros do dia.
2.  **Busca de Alimentos (`food_search_page`):** Busca instantânea na tabela TACO local ou na API externa.
3.  **Detalhes e Porcionamento (`food_detail_page`):** Onde o usuário digita a gramagem e vê os macros calculados dinamicamente antes de adicionar à refeição.
4.  **Cadastro de Alimento Personalizado (`custom_food_page`):** Caso o alimento não exista na base.

---

## 2. Especificação das Telas e Fluxos

### 2.1 Diário de Alimentação (`food_journal_page`)
*   **Controle de Macros:** Barra de progresso circular no topo para calorias totais e barras lineares para carboidratos, proteínas, lipídios (gorduras) e fibras.
*   **Blocos de Refeição:** Quatro blocos fixos:
    1.  *Breakfast* (Café da Manhã)
    2.  *Lunch* (Almoço)
    3.  *Dinner* (Jantar)
    4.  *Snack* (Lanche)
*   Cada bloco lista os alimentos consumidos, suas quantidades (em gramas) e calorias individuais. Contém um botão "+" para abrir a busca de alimentos diretamente vinculada àquela refeição.

### 2.2 Busca de Alimentos (`food_search_page`)
*   **Campo de Busca:** Input de texto com debounce (aguarda 300ms após o término da digitação para fazer a busca).
*   **Histórico / Recentes:** Caso o campo esteja vazio, exibe os alimentos mais consumidos recentemente pelo usuário (offline-first, lidos do SQLite).
*   **Cache-First Search:**
    1.  O Flutter busca o termo na tabela `foods` local no SQLite.
    2.  Se encontrar resultados, exibe imediatamente.
    3.  Se não encontrar (ou se o usuário desejar buscar na nuvem), faz a requisição para `GET /api/v1/foods/search?q={termo}`. Os resultados novos retornados da API são injetados no banco de dados local para buscas futuras rápidas.

### 2.3 Detalhes e Porcionamento (`food_detail_page`)
*   **Visualização Nutricional:** Exibe os valores de Kcal, Proteínas, Carboidratos, Gorduras e Fibras originais (por 100g padrão).
*   **Calculadora de Quantidade:** Input numérico para o usuário digitar a porção consumida (em gramas). A UI atualiza dinamicamente as métricas na tela multiplicando:
    $$\text{Macro Calculado} = \frac{\text{Macro Original (100g)} \times \text{Gramas Consumidas}}{100}$$
*   **Salvar:** Botão "Adicionar à Refeição" gera o registro local e retorna ao Diário.

---

## 3. Mapeamento da API

### Listar Refeições do Usuário
*   **Endpoint:** `GET /api/v1/refeicoes?per_page=15`

### Registrar Nova Refeição
*   **Endpoint:** `POST /api/v1/refeicoes`
*   **Payload Exemplo:**
```json
{
  "id": "67fc767e-bb21-4f24-be74-8a16db32ddce",
  "meal_type": "Almoço",
  "consumed_at": "2026-06-20T12:30:00-03:00",
  "foods": [
    {
      "food_id": "019ed314-a7e9-71f6-bc82-28c0f89ab71a",
      "quantity": 250
    }
  ]
}
```

### Buscar Alimento na API (Fallback de Cache)
*   **Endpoint:** `GET /api/v1/foods/search?q=Arroz`
*   **Endpoint Nutrientes do Alimento:** `GET /api/v1/foods/{id}`

---

## 4. Estrutura do SQLite Local

### Tabela: `meals`
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária gerada no Flutter |
| `meal_type` | `TEXT` | `Breakfast`, `Lunch`, `Dinner` ou `Snack` |
| `consumed_at` | `TEXT` | ISO 8601 data/hora da refeição |
| `synced_at` | `TEXT` (Nullable) | Data de sincronização |
| `deleted_locally` | `INTEGER` (0 ou 1) | Flag de soft delete offline |

### Tabela: `meal_foods` (Pivot)
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID) | Chave primária |
| `meal_id` | `TEXT` (FK) | Relacionamento com `meals.id` |
| `food_id` | `TEXT` (FK) | Relacionamento com `foods.id` |
| `quantity` | `REAL` | Quantidade consumida em gramas |

### Tabela: `foods` (Tabela TACO Cacheada localmente)
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `TEXT` (UUID / ID) | Chave primária |
| `name` | `TEXT` | Nome/descrição do alimento |
| `brand` | `TEXT` (Nullable) | Marca do produto |
| `calories` | `REAL` | Kcal por 100g |
| `protein` | `REAL` | Proteínas (g) por 100g |
| `carbohydrates` | `REAL` | Carboidratos (g) por 100g |
| `fat` | `REAL` | Gorduras (g) por 100g |
| `fiber` | `REAL` | Fibras (g) por 100g |
| `serving_size` | `TEXT` | Tamanho da porção padrão (ex: *"100g"*) |
