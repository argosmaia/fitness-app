# Dashboard Principal (Home Page)

Este documento especifica a estrutura visual e os fluxos de dados para a página principal (Dashboard / Home).

## 1. Visão Geral da Tela

A Dashboard consolida o resumo diário de saúde do usuário. Ela serve como ponto de partida (onboarding diário) e é alimentada de forma híbrida: lê primariamente o banco de dados SQLite local (offline-first) e é atualizada sempre que novas sincronizações são realizadas.

### Elementos Visuais e Métricas:
*   **Header:**
    *   Saudação ao usuário (ex: *"Hi, Amelia"*).
    *   Data atual formatada (ex: *"WED 24 MAR"*).
    *   Foto do perfil com indicador de status (online/sincronizado).
*   **Health Score (Pontuação de Saúde):**
    *   Um componente central poligonal mostrando a nota geral do usuário (ex: `72` ou `84`), calculada com base na consistência de treinos, sono, hidratação e alimentação do dia.
*   **Grid de Métricas Rápidas:**
    *   **Calorias:** Gráfico de progresso circular (`CircularPercentIndicator`) indicando o percentual consumido vs. a meta diária (ex: `500 cal` de `2200 cal`), mais o tempo da última atualização.
    *   **Peso:** Gráfico de linha simplificado (`FlutterFlowLineChart`) mostrando a variação recente do peso (ex: `58 kg`), mais o tempo da última atualização.
    *   **Água:** Representação visual (copo d'água) mostrando o consumo acumulado (ex: `750 ml`) vs. meta.
    *   **Passos:** Contador circular de passos acumulados (ex: `9.890 passos`) puxado do Google Health/Health Connect (localmente no device).
*   **Macro Breakdown (Resumo de Nutrientes):**
    *   Consumo acumulado de calorias com progresso linear.
    *   Barras horizontais de progresso linear (`LinearPercentIndicator`) para os macronutrientes:
        *   **Proteínas** (ex: *56%* da meta).
        *   **Carboidratos** (ex: *142%* da meta - indica excesso em vermelho).
        *   **Gorduras (Lipídios)** (ex: *90%* da meta).
        *   **Fibras** (ex: *86%* da meta).
*   **Seção de Eventos / Dicas:**
    *   Um card com imagem destacada promovendo desafios da comunidade ou dicas de saúde (ex: *"National health movement - Challenge your friends"*), com botão para participar ("Join").

---

## 2. Fluxo de Dados e Integração API

### Fontes de Dados Locais (SQLite):
O Dashboard **nunca** faz requisições diretas bloqueantes para a API ao abrir. Ele lê do banco de dados local as seguintes somatórias para a data corrente (`DateTime.now()` local):
1.  **Soma de Água:** `SELECT SUM(amount_ml) FROM water_logs WHERE DATE(logged_at) = DATE('now')`
2.  **Soma de Sono:** `SELECT SUM(duration_minutes) FROM sleep_logs WHERE DATE(started_at) = DATE('now')`
3.  **Soma de Calorias/Macros:** Busca nas refeições do dia e soma os macros dos alimentos associados.
4.  **Treinos:** `SELECT COUNT(*) FROM workouts WHERE DATE(started_at) = DATE('now')`

### Chamadas de API Auxiliares (Sincronização em Background):
Sempre que a Dashboard entra em primeiro plano e há conexão detectada:
1.  O app aciona em background o `syncProvider` para enviar dados pendentes via `POST /sync`.
2.  Após receber a resposta com sucesso, atualiza o banco local e emite um recarregamento reativo via Riverpod, fazendo a UI atualizar os indicadores suavemente (`optimistic updates`).

---

## 3. Componentização (Design Atômico)

### Átomos (Atoms):
*   `AvatarProfile`: Container circular com imagem de rede e borda fina de status.
*   `CircularProgressBar`: Anel de porcentagem customizado para uso em passos e calorias.
*   `LinearProgressBar`: Barra de progresso horizontal colorida para os macros (Laranja para normal, Vermelho para excesso, Verde para meta batida).
*   `MetricLabel`: Texto formatado combinando número principal e unidade (ex: `58` em fonte maior, `kg` em fonte menor e alinhado por baixo).

### Moléculas (Molecules):
*   `DateHeader`: Combinação do ícone do sol, texto da data formatada em caixa alta e fonte estilizada.
*   `HealthScoreCard`: Card cinza claro com o ícone central poligonal (SVG) contendo a nota e o texto explicativo ao lado.
*   `NutritionLinearRow`: O rótulo da porcentagem (ex: "Proteins: 56%") empilhado acima da barra linear de progresso correspondente.

### Organismos (Organisms):
*   `MetricsGrid`: Grid View adaptativo contendo os 4 cards principais de métricas (Calorias, Peso, Água, Passos).
*   `NutrientSummaryCard`: Card unificado de nutrição contendo o progresso calórico total, divisor e as 4 linhas lineares de macronutrientes.
*   `EventBannerCard`: Bloco inferior com imagem, texto descritivo e botão "Join".
