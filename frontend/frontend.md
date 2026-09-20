# Frontend Guide — Fitness App

> Guia técnico completo para o time Flutter consumir a API, estruturar o projeto e aplicar design atômico.
> 
> **Suporte Multiplataforma:** O aplicativo foi projetado para rodar em múltiplas plataformas usando a mesma base de código Flutter, com suporte oficial para:
> - **Mobile:** Android, iOS e outros SOs mobile.
> - **Desktop:** Windows, Linux, macOS e outros sistemas PC.

---

## 1. Base URL & Versionamento

```
https://<seu-dominio>/api/v1
```

Todas as rotas são prefixadas com `/api/v1/`.  
Em desenvolvimento local: `http://127.0.0.1:8000/api/v1`.

---

## 2. Contrato de Resposta (APIResponse)

Toda resposta segue **um único envelope**:

```json
{
  "status": 200,
  "mensagem": "Descrição legível",
  "data": { }
}
```

Respostas paginadas incluem `meta`:

```json
{
  "status": 200,
  "mensagem": "...",
  "data": [ ],
  "meta": {
    "pagina_atual": 1,
    "ultima_pagina": 5,
    "por_pagina": 15,
    "total": 72
  }
}
```

### Códigos HTTP usados

| Código | Situação |
|--------|----------|
| `200` | Sucesso geral / leitura |
| `201` | Recurso criado |
| `400` | Requisição inválida |
| `401` | Não autenticado |
| `403` | Acesso negado |
| `404` | Não encontrado |
| `409` | Conflito de recurso |
| `422` | Erro de validação |
| `429` | Rate limit atingido |
| `500` | Erro interno |

> **Regra Flutter:** verifique sempre o campo `status` do payload, não apenas o HTTP status code.

---

## 3. Autenticação

### 3.1 Fluxo de Token (Sanctum)

O backend usa **Laravel Sanctum** com tokens de Bearer.  
O token é gerado no login/registro e deve ser armazenado localmente com `flutter_secure_storage`.

```
POST /auth/register  → recebe token
POST /auth/login     → recebe token

Todas as outras rotas → Bearer <token>
```

### 3.2 Header obrigatório em todas as rotas protegidas

```http
Authorization: Bearer <token>
Accept: application/json
Content-Type: application/json
```

---

## 4. Rotas de API — Referência Completa

### 🔓 Rotas Públicas (sem token)

---

#### `POST /auth/register`
Cria conta e retorna token.

**Body:**
```json
{
  "name": "João Silva",
  "email": "joao@email.com",
  "password": "senha123",
  "password_confirmation": "senha123",
  "birth_date": "1995-04-20",
  "gender": "male",
  "height": 175.0,
  "weight": 80.0,
  "goal_weight": 75.0,
  "daily_water_goal": 2500,
  "daily_kcal_goal": 2200
}
```

**Resposta `201`:**
```json
{
  "status": 201,
  "mensagem": "Usuário registrado com sucesso",
  "data": {
    "user": { "id": "uuid", "name": "João Silva", "email": "joao@email.com" },
    "token": "1|abc123..."
  }
}
```

---

#### `POST /auth/login`
Autentica e retorna token.

**Body:**
```json
{
  "email": "joao@email.com",
  "password": "senha123",
  "device_name": "pixel_9_pro"
}
```

**Resposta `200`:**
```json
{
  "status": 200,
  "mensagem": "Login realizado com sucesso",
  "data": {
    "user": { "id": "uuid", "name": "João Silva" },
    "token": "2|xyz456..."
  }
}
```

---

#### `POST /auth/password/reset`
Solicita link de recuperação de senha (stub — envia e-mail futuro).

**Body:** `{ "email": "joao@email.com" }`

---

### 🔒 Rotas Protegidas (Bearer token obrigatório)

---

#### `POST /auth/logout`
Invalida o token atual.

**Resposta `200`:** `{ "mensagem": "Logout realizado com sucesso", "data": null }`

---

#### `POST /auth/refresh`
Invalida o token atual e emite um novo.

**Body:** `{ "device_name": "pixel_9_pro" }`  
**Resposta `200`:** `{ "data": { "token": "3|novo..." } }`

---

#### `DELETE /auth/account`
Exclui a conta e todos os dados do usuário (soft delete).

---

### 👤 Perfil

#### `GET /user/profile`
Retorna dados do usuário autenticado.

**Resposta `200` — `data`:**
```json
{
  "id": "uuid",
  "name": "João Silva",
  "email": "joao@email.com",
  "birth_date": "1995-04-20",
  "gender": "male",
  "height": 175.0,
  "weight": 80.0,
  "goal_weight": 75.0,
  "daily_water_goal": 2500,
  "daily_kcal_goal": 2200,
  "created_at": "2026-01-01T00:00:00+00:00"
}
```

---

#### `PUT /user/profile`
Atualiza campos do perfil (todos opcionais via `sometimes`).

**Body:** qualquer subconjunto dos campos acima (exceto `id`, `created_at`).

---

### 🏋️ Treinos

#### `GET /workouts?per_page=15`
Lista treinos do usuário (paginado).

**Resposta `200` — `data.items[]`:**
```json
{
  "id": "uuid",
  "name": "Treino A — Peito",
  "description": "Foco em peitoral",
  "started_at": "2026-06-16T08:00:00+00:00",
  "finished_at": "2026-06-16T09:00:00+00:00",
  "duration_seconds": 3600,
  "calories": 420,
  "exercises": [
    {
      "id": "uuid",
      "name": "Supino Reto",
      "sets": 4,
      "reps": 10,
      "weight": 80.0,
      "rest_seconds": 90,
      "notes": null
    }
  ]
}
```

---

#### `GET /workouts/{id}`
Detalhe de um treino com exercícios.

---

#### `POST /workouts`
Cria treino com exercícios aninhados.

**Body:**
```json
{
  "name": "Treino A",
  "started_at": "2026-06-16T08:00:00Z",
  "finished_at": "2026-06-16T09:00:00Z",
  "duration_seconds": 3600,
  "calories": 420,
  "exercises": [
    { "name": "Supino Reto", "sets": 4, "reps": 10, "weight": 80.0, "rest_seconds": 90 }
  ]
}
```

> Para **sync offline**, inclua `"id": "<uuid-gerado-no-device>"` tanto no workout quanto em cada exercise. O backend faz `updateOrCreate` pelo `id`.

---

#### `PUT /workouts/{id}`
Atualiza treino. Exercícios não enviados são deletados (operação de replace).

---

#### `DELETE /workouts/{id}`
Remove treino e seus exercícios (soft delete).

---

### 🍽️ Refeições

#### `GET /meals?per_page=15`
Lista refeições paginadas.

**`data.items[]`:**
```json
{
  "id": "uuid",
  "meal_type": "Breakfast",
  "consumed_at": "2026-06-16T07:30:00+00:00",
  "foods": [
    {
      "id": "uuid-do-food",
      "name": "Arroz Integral Cozido",
      "calories": 111.0,
      "protein": 2.6,
      "carbohydrates": 23.0,
      "fat": 0.9,
      "fiber": 1.8,
      "serving_size": "100g",
      "quantity": 150.0,
      "meal_food_id": "uuid-pivot"
    }
  ]
}
```

---

#### `POST /meals`
Registra refeição.

**Body:**
```json
{
  "meal_type": "Breakfast",
  "consumed_at": "2026-06-16T07:30:00Z",
  "foods": [
    { "food_id": "uuid-do-food", "quantity": 150.0 }
  ]
}
```

**`meal_type` aceitos:** `Breakfast`, `Lunch`, `Dinner`, `Snack`

---

#### `PUT /meals/{id}` / `DELETE /meals/{id}`
Atualiza ou remove refeição.

---

### 🥗 Alimentos (TACO)

#### `GET /foods`
Lista todos os alimentos da base TACO local.

#### `GET /foods/search?q=arroz`
Busca na base local (cache-first: se não encontrar, vai à API TACO e persiste no banco antes de retornar).

#### `GET /foods/{id}`
Detalhe completo com micronutrientes. **Cache-first** — na primeira chamada busca na API TACO, salva no banco; subsequentes são 100% locais.

**Resposta `data`:**
```json
{
  "id": 10,
  "description": "Arroz, integral, cozido",
  "category": "Cereais e derivados",
  "macros": { "kcal": 124.0, "protein": 2.6, "carbohydrate": 25.8, "lipids": 1.0, "fiber": 2.7 },
  "micros": { "sodium": 1.0, "calcium": 4.0, "iron": 0.3, "vitaminC": 0.0 }
}
```

#### `GET /foods/{id}/calculate?grams=150`
Calcula nutrição proporcional à gramagem informada.

#### `POST /foods/calculate-meal`
Calcula total nutricional de múltiplos alimentos.

**Body:** `{ "foods": [{ "id": 10, "grams": 150 }, { "id": 20, "grams": 80 }] }`

#### `POST /foods`
Cadastra alimento personalizado (não TACO).

#### `GET /foods/categories` / `GET /foods/categories/{id}/foods`
Lista categorias TACO e seus alimentos.

#### `GET /foods/averages` / `GET /foods/random`
Média nutricional global e alimento aleatório.

#### `GET /foods/ranking/protein` / `/ranking/fiber` / `/ranking/low-calorie`
Rankings nutricionais top 10.

#### `GET /foods/search/nutrients?min_protein=15&max_kcal=250`
Filtro por faixa nutricional.

---

### 😴 Sono

#### `GET /sleep-logs?per_page=15`
Lista registros de sono paginados.

**`data.items[]`:**
```json
{
  "id": "uuid",
  "started_at": "2026-06-15T23:00:00+00:00",
  "finished_at": "2026-06-16T07:00:00+00:00",
  "quality": 85,
  "duration_minutes": 480
}
```

#### `POST /sleep-logs`
**Body:** `{ "started_at": "...", "finished_at": "...", "quality": 85, "duration_minutes": 480 }`

#### `PUT /sleep-logs/{id}` / `DELETE /sleep-logs/{id}`

---

### 💧 Hidratação

#### `GET /water-logs?per_page=15`

**`data.items[]`:**
```json
{ "id": "uuid", "amount_ml": 300, "logged_at": "2026-06-16T09:00:00+00:00" }
```

#### `POST /water-logs`
**Body:** `{ "amount_ml": 300, "logged_at": "2026-06-16T09:00:00Z" }`

#### `DELETE /water-logs/{id}`

---

### 🔄 Sync

#### `POST /sync`
Endpoint de sincronização incremental em lote. Envie apenas os registros criados/modificados offline.

**Body:**
```json
{
  "workouts": [
    {
      "id": "uuid-gerado-no-device",
      "name": "Treino Offline",
      "started_at": "...",
      "exercises": [ { "id": "uuid-ex", "name": "Rosca", "sets": 3, "reps": 12 } ]
    }
  ],
  "meals": [
    {
      "id": "uuid-meal",
      "meal_type": "Lunch",
      "consumed_at": "...",
      "foods": [ { "food_id": "uuid-food", "quantity": 200 } ]
    }
  ],
  "sleep_logs": [
    { "id": "uuid-sleep", "started_at": "...", "finished_at": "...", "duration_minutes": 420 }
  ],
  "water_logs": [
    { "id": "uuid-water", "amount_ml": 500, "logged_at": "..." }
  ]
}
```

**Resposta `200` — `data`:**
```json
{
  "workouts": ["uuid1", "uuid2"],
  "meals": ["uuid3"],
  "sleep_logs": ["uuid4"],
  "water_logs": ["uuid5"]
}
```

> O backend faz `updateOrCreate` por `id`, logo reenviar o mesmo UUID é idempotente.

---

## 5. Segurança — O Que o Flutter Deve Fazer

| Prática | Como implementar |
|---------|-----------------|
| Armazenar token com segurança | `flutter_secure_storage` — nunca `SharedPreferences` |
| Renovar token automaticamente | Interceptor Dio: se `401`, chama `POST /auth/refresh` e retry |
| Rate limit `429` | Mostrar mensagem e aguardar antes de retry |
| HTTPS obrigatório | Configurar `dio` apenas para `https://` em produção |
| Não logar token | Remover logs de Authorization em builds de release |
| Logout no `401` persistente | Se refresh também retornar `401`, limpar token e redirecionar ao login |

### Interceptor Dio sugerido

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = SecureStorage.read('token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await AuthRepository.refresh();
      if (refreshed) {
        // Retry original request
        handler.resolve(await _retry(err.requestOptions));
        return;
      }
      AuthRepository.logout(); // limpa storage e navega ao login
    }
    handler.next(err);
  }
}
```

---

## 6. Estratégia Offline-First

```
Usuário faz ação
      ↓
Salva no SQLite local (com UUID gerado no device)
      ↓
Atualiza UI imediatamente (optimistic update)
      ↓
Enfileira item para sync
      ↓
Conectividade disponível?
  ├─ Sim → POST /sync com itens pendentes → marca como sincronizados
  └─ Não → retry em background (WorkManager / connectivity_plus)
```

### Campos obrigatórios no SQLite local

Toda entidade local deve ter:

| Campo | Tipo | Uso |
|-------|------|-----|
| `id` | `TEXT` (UUID) | Gerado no device com `uuid` package |
| `synced_at` | `TEXT?` | `null` = pendente de sync |
| `deleted_locally` | `INTEGER` | Soft delete local para sync |

---

## 7. Arquitetura Flutter — Camadas

```
lib/
 ├── core/
 │    ├── api/          # DioClient, interceptors, ApiEndpoints
 │    ├── db/           # DatabaseHelper, DAOs base
 │    ├── errors/       # Failure, AppException
 │    ├── router/       # GoRouter config
 │    └── theme/        # AppTheme, tokens de cor/tipografia
 │
 ├── shared/
 │    ├── models/       # modelos compartilhados
 │    ├── widgets/      # átomos e moléculas globais
 │    └── providers/    # providers globais (auth, connectivity)
 │
 └── features/
      ├── auth/
      ├── dashboard/
      ├── workout/
      ├── food/
      ├── sleep/
      └── water/
```

### Estrutura por feature

```
feature/
 ├── data/
 │    ├── datasources/
 │    │    ├── remote_datasource.dart   # chama a API
 │    │    └── local_datasource.dart    # chama o SQLite
 │    ├── models/                       # JSON serialization
 │    └── repositories/                # implementação concreta
 │
 ├── domain/
 │    ├── entities/                     # objetos de negócio puros
 │    ├── repositories/                 # interface abstrata
 │    └── usecases/                     # 1 usecase = 1 arquivo
 │
 └── presentation/
      ├── providers/                    # Riverpod StateNotifiers
      ├── pages/
      └── widgets/                      # widgets específicos da feature
```

---

## 8. Design Atômico para Flutter

### Nível 1 — Átomos
Widgets primitivos, sem lógica de negócio.

```dart
// atoms/app_button.dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  // ...
}

// atoms/app_text_field.dart
class AppTextField extends StatelessWidget { ... }

// atoms/nutrient_badge.dart  — ex: "124 kcal" chip
class NutrientBadge extends StatelessWidget { ... }

// atoms/water_drop_icon.dart
// atoms/progress_ring.dart   — anel circular de progresso
// atoms/app_avatar.dart
// atoms/skeleton_box.dart    — loading skeleton
```

---

### Nível 2 — Moléculas
Composições de átomos com responsabilidade única.

```dart
// molecules/food_search_bar.dart
//   → AppTextField + ícone de busca + debounce

// molecules/macro_row.dart
//   → NutrientBadge(kcal) + NutrientBadge(ptn) + NutrientBadge(carb) + NutrientBadge(fat)

// molecules/exercise_set_row.dart
//   → campos de séries / repetições / carga numa linha

// molecules/water_log_chip.dart
//   → ícone + quantidade em ml + horário

// molecules/sleep_quality_slider.dart
//   → Slider + label de qualidade

// molecules/workout_stat_chip.dart
//   → ícone + valor (ex: "42 min", "320 kcal")
```

---

### Nível 3 — Organismos
Seções completas de UI, podem ter acesso a providers.

```dart
// organisms/meal_card.dart
//   → header da refeição + MacroRow + lista de FoodItem

// organisms/workout_card.dart
//   → nome + WorkoutStatChip(duração) + WorkoutStatChip(calorias)
//     + lista de exercícios resumida

// organisms/daily_water_progress.dart
//   → ProgressRing + total consumido + meta + lista WaterLogChip

// organisms/sleep_summary_card.dart
//   → duração + qualidade visual + horários

// organisms/food_search_results.dart
//   → FoodSearchBar + lista FoodTile com cache-first indicator

// organisms/dashboard_header.dart
//   → saudação + data + resumo kcal do dia
```

---

### Nível 4 — Templates
Layout das páginas sem dados reais (estrutura).

```dart
// templates/list_detail_template.dart
//   → AppBar + ListView + FAB

// templates/form_template.dart
//   → AppBar + Column com campos + botão de submit fixo no bottom

// templates/dashboard_template.dart
//   → CustomScrollView com SliverAppBar + seções em cards
```

---

### Nível 5 — Páginas
Instanciam templates com dados reais via providers.

```dart
// pages/dashboard_page.dart
// pages/workout_list_page.dart
// pages/workout_detail_page.dart
// pages/log_meal_page.dart
// pages/food_search_page.dart
// pages/sleep_log_page.dart
// pages/water_log_page.dart
// pages/profile_page.dart
```

---

## 9. Providers Riverpod — Sugestão

```dart
// auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
final tokenProvider = Provider<String?>(...);

// workout
final workoutListProvider = FutureProvider.autoDispose<List<Workout>>(...);
final activeWorkoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>(...);

// food
final foodSearchProvider = StateNotifierProvider.family<FoodSearchNotifier, FoodSearchState, String>(...);
final mealLogProvider = StateNotifierProvider<MealNotifier, MealState>(...);

// dashboard
final dailySummaryProvider = FutureProvider.autoDispose<DailySummary>(...);

// sync
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>(...);
final connectivityProvider = StreamProvider<bool>(...);
```

---

## 10. Mapeamento de Tela → API

| Tela | Chamadas de API |
|------|----------------|
| Login | `POST /auth/login` |
| Registro | `POST /auth/register` |
| Dashboard | `GET /user/profile` + dados do SQLite local |
| Lista de Treinos | `GET /workouts` |
| Detalhe de Treino | `GET /workouts/{id}` |
| Iniciar Treino | Salva no SQLite → `POST /workouts` no sync |
| Buscar Alimento | `GET /foods/search?q=...` |
| Detalhe Alimento | `GET /foods/{id}` (cache-first automático) |
| Registrar Refeição | `POST /meals` |
| Listar Refeições | `GET /meals` |
| Registrar Sono | `POST /sleep-logs` |
| Registrar Água | `POST /water-logs` |
| Perfil | `GET /user/profile` + `PUT /user/profile` |
| Sync Background | `POST /sync` |

---

## 11. Tratamento de Erros no Flutter

```dart
// Utilitário global de parse da resposta
class ApiResult<T> {
  final T? data;
  final String? mensagem;
  final int status;
  final bool success;
}

// Parse padrão
ApiResult<T> parseResponse<T>(Response response, T Function(dynamic) fromJson) {
  final body = response.data as Map<String, dynamic>;
  final status = body['status'] as int;
  return ApiResult(
    status: status,
    success: status >= 200 && status < 300,
    mensagem: body['mensagem'] as String?,
    data: body['data'] != null ? fromJson(body['data']) : null,
  );
}
```

### Mensagens de erro por código

| status | Mensagem ao usuário |
|--------|---------------------|
| `401` | "Sessão expirada. Faça login novamente." |
| `403` | "Você não tem permissão para isso." |
| `404` | "Item não encontrado." |
| `422` | Exibir campos com erros de validação |
| `429` | "Muitas tentativas. Aguarde um momento." |
| `500` | "Erro no servidor. Tente novamente." |
| sem internet | "Sem conexão. Trabalhando offline." |

---

## 12. Boas Práticas Gerais

- **UUID no device:** use o package `uuid` para gerar IDs antes de salvar no SQLite. O backend aceita o mesmo UUID via `updateOrCreate`.
- **Paginação:** sempre usar `per_page` e controlar `pagina_atual` / `ultima_pagina` para infinite scroll.
- **Datas:** o backend retorna e aceita ISO 8601 (`2026-06-16T08:00:00+00:00`). Use `DateTime.parse()` e sempre converta para UTC antes de enviar.
- **Gramagem de alimentos:** a unidade padrão da TACO é `100g`. O campo `quantity` nas refeições é a quantidade em gramas consumida pelo usuário.
- **Qualidade do sono:** campo inteiro `1–100`.
- **Água:** campo `amount_ml` em mililitros.

---

## 13. Tabela Completa de Rotas (Gerada via CLI)

Abaixo está o mapa completo das rotas que a API possui atualmente ativas, incluindo seus métodos HTTP, URIs e os respectivos Controllers que tratam cada requisição. Você pode usar isso como uma "colinha" rápida.

```text
  GET|HEAD  / ................................................................... routes/web.php:5
  GET|HEAD  api/v1/admin/usuarios ......... App\Domains\User\Http\Controllers\UserController@index
  POST      api/v1/admin/usuarios ......... App\Domains\User\Http\Controllers\UserController@store
  GET|HEAD  api/v1/admin/usuarios/{id} ..... App\Domains\User\Http\Controllers\UserController@show
  PUT       api/v1/admin/usuarios/{id} ... App\Domains\User\Http\Controllers\UserController@update
  PATCH     api/v1/admin/usuarios/{id} ... App\Domains\User\Http\Controllers\UserController@update
  DELETE    api/v1/admin/usuarios/{id} .. App\Domains\User\Http\Controllers\UserController@destroy
  DELETE    api/v1/auth/account ... App\Domains\Auth\Http\Controllers\AuthController@deleteAccount
  POST      api/v1/auth/login ............. App\Domains\Auth\Http\Controllers\AuthController@login
  POST      api/v1/auth/logout ........... App\Domains\Auth\Http\Controllers\AuthController@logout
  POST      api/v1/auth/password/reset App\Domains\Auth\Http\Controllers\AuthController@resetPass…
  POST      api/v1/auth/refresh ......... App\Domains\Auth\Http\Controllers\AuthController@refresh
  POST      api/v1/auth/register ....... App\Domains\Auth\Http\Controllers\AuthController@register
  GET|HEAD  api/v1/foods .................. App\Domains\Food\Http\Controllers\FoodController@index
  POST      api/v1/foods .................. App\Domains\Food\Http\Controllers\FoodController@store
  GET|HEAD  api/v1/foods/averages ...... App\Domains\Food\Http\Controllers\FoodController@averages
  POST      api/v1/foods/calculate-meal App\Domains\Food\Http\Controllers\FoodController@calculat…
  GET|HEAD  api/v1/foods/categories .. App\Domains\Food\Http\Controllers\FoodController@categories
  GET|HEAD  api/v1/foods/categories/{id}/foods App\Domains\Food\Http\Controllers\FoodController@c…
  GET|HEAD  api/v1/foods/random .......... App\Domains\Food\Http\Controllers\FoodController@random
  GET|HEAD  api/v1/foods/ranking/fiber App\Domains\Food\Http\Controllers\FoodController@rankingFi…
  GET|HEAD  api/v1/foods/ranking/low-calorie App\Domains\Food\Http\Controllers\FoodController@ran…
  GET|HEAD  api/v1/foods/ranking/protein App\Domains\Food\Http\Controllers\FoodController@ranking…
  GET|HEAD  api/v1/foods/search .......... App\Domains\Food\Http\Controllers\FoodController@search
  GET|HEAD  api/v1/foods/search/nutrients App\Domains\Food\Http\Controllers\FoodController@search…
  GET|HEAD  api/v1/foods/{id} .............. App\Domains\Food\Http\Controllers\FoodController@show
  GET|HEAD  api/v1/foods/{id}/calculate App\Domains\Food\Http\Controllers\FoodController@calculate
  GET|HEAD  api/v1/refeicoes .............. App\Domains\Food\Http\Controllers\MealController@index
  POST      api/v1/refeicoes .............. App\Domains\Food\Http\Controllers\MealController@store
  GET|HEAD  api/v1/refeicoes/{id} .......... App\Domains\Food\Http\Controllers\MealController@show
  PUT       api/v1/refeicoes/{id} ........ App\Domains\Food\Http\Controllers\MealController@update
  PATCH     api/v1/refeicoes/{id} ........ App\Domains\Food\Http\Controllers\MealController@update
  DELETE    api/v1/refeicoes/{id} ....... App\Domains\Food\Http\Controllers\MealController@destroy
  GET|HEAD  api/v1/registros-agua .... App\Domains\Water\Http\Controllers\WaterLogController@index
  POST      api/v1/registros-agua .... App\Domains\Water\Http\Controllers\WaterLogController@store
  GET|HEAD  api/v1/registros-agua/{id} App\Domains\Water\Http\Controllers\WaterLogController@show
  PUT       api/v1/registros-agua/{id} App\Domains\Water\Http\Controllers\WaterLogController@upda…
  PATCH     api/v1/registros-agua/{id} App\Domains\Water\Http\Controllers\WaterLogController@upda…
  DELETE    api/v1/registros-agua/{id} App\Domains\Water\Http\Controllers\WaterLogController@dest…
  GET|HEAD  api/v1/registros-sono .... App\Domains\Sleep\Http\Controllers\SleepLogController@index
  POST      api/v1/registros-sono .... App\Domains\Sleep\Http\Controllers\SleepLogController@store
  GET|HEAD  api/v1/registros-sono/{id} App\Domains\Sleep\Http\Controllers\SleepLogController@show
  PUT       api/v1/registros-sono/{id} App\Domains\Sleep\Http\Controllers\SleepLogController@upda…
  PATCH     api/v1/registros-sono/{id} App\Domains\Sleep\Http\Controllers\SleepLogController@upda…
  DELETE    api/v1/registros-sono/{id} App\Domains\Sleep\Http\Controllers\SleepLogController@dest…
  POST      api/v1/sync .................... App\Domains\Sync\Http\Controllers\SyncController@sync
  GET|HEAD  api/v1/treinos .......... App\Domains\Workout\Http\Controllers\WorkoutController@index
  POST      api/v1/treinos .......... App\Domains\Workout\Http\Controllers\WorkoutController@store
  GET|HEAD  api/v1/treinos/{id} ...... App\Domains\Workout\Http\Controllers\WorkoutController@show
  PUT       api/v1/treinos/{id} .... App\Domains\Workout\Http\Controllers\WorkoutController@update
  PATCH     api/v1/treinos/{id} .... App\Domains\Workout\Http\Controllers\WorkoutController@update
  DELETE    api/v1/treinos/{id} ... App\Domains\Workout\Http\Controllers\WorkoutController@destroy
  GET|HEAD  api/v1/usuarios .............. App\Domains\User\Http\Controllers\UserController@perfil
  PUT       api/v1/usuarios ..... App\Domains\User\Http\Controllers\UserController@atualizarPerfil
  PATCH     api/v1/usuarios ..... App\Domains\User\Http\Controllers\UserController@atualizarPerfil
  GET|HEAD  sanctum/csrf-cookie sanctum.csrf-cookie › Laravel\Sanctum › CsrfCookieController@show
  GET|HEAD  storage/{path} storage.local › vendor/laravel/framework/src/Illuminate/Filesystem/Fil…
  PUT       storage/{path} storage.local.upload › vendor/laravel/framework/src/Illuminate/Filesys…
  GET|HEAD  up vendor/laravel/framework/src/Illuminate/Foundation/Configuration/ApplicationBuilde…
```
