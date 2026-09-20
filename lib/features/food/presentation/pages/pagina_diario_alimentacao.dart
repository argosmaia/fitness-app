import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/theme/tema_app.dart';
import '../../../auth/presentation/providers/provedor_autenticacao.dart';
import '../providers/provedor_alimentacao.dart';
import '../../domain/entities/refeicao.dart';

/// Tela principal do diário alimentar do usuário.
class PaginaDiarioAlimentacao extends ConsumerWidget {
  const PaginaDiarioAlimentacao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diario = ref.watch(provedorDiarioAlimentacao);
    final estadoAuth = ref.watch(provedorAutenticacao);

    // Obtém as metas diárias do usuário autenticado (fallback padrão se não logado)
    double metaKcal = 2000;
    double metaPtn = 130;
    double metaCarb = 220;
    double metaFat = 65;
    double metaFib = 25;

    if (estadoAuth is EstadoAutenticado) {
      metaKcal = estadoAuth.usuario.metaCaloriasDiaria.toDouble();
      // Estimativa padrão baseada nas calorias do perfil para fins visuais
      metaPtn = (metaKcal * 0.30) / 4; // 30% proteínas
      metaCarb = (metaKcal * 0.45) / 4; // 45% carboidratos
      metaFat = (metaKcal * 0.25) / 9; // 25% gorduras
      metaFib = 25; // Meta de fibra padrão
    }

    final percKcal = (diario.totalCalorias / metaKcal).clamp(0.0, 1.0);
    final percPtn = (diario.totalProteinas / metaPtn).clamp(0.0, 1.0);
    final percCarb = (diario.totalCarboidratos / metaCarb).clamp(0.0, 1.0);
    final percFat = (diario.totalLipidios / metaFat).clamp(0.0, 1.0);
    final percFib = (diario.totalFibras / metaFib).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Diário Alimentar')),
      body: SafeArea(
        child: Column(
          children: [
            // Resumo de Nutrientes (Header com Circular + Lineares)
            Container(
              padding: const EdgeInsets.all(20.0),
              color: TemaApp.corCard,
              child: Row(
                children: [
                  // Circular Calorias
                  CircularPercentIndicator(
                    radius: 54.0,
                    lineWidth: 10.0,
                    percent: percKcal,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${diario.totalCalorias.round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'kcal / ${metaKcal.round()}',
                          style: TextStyle(
                            color: TemaApp.corTextoSecundario,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: TemaApp.corCardBorda,
                    progressColor: TemaApp.corPrincipal,
                  ),
                  const SizedBox(width: 24),

                  // Progressos Lineares de Macros
                  Expanded(
                    child: Column(
                      children: [
                        _barraProgressoMacro(
                          context,
                          'Proteínas',
                          '${diario.totalProteinas.round()}g / ${metaPtn.round()}g',
                          percPtn,
                          TemaApp.corSecundaria,
                        ),
                        const SizedBox(height: 8),
                        _barraProgressoMacro(
                          context,
                          'Carbos',
                          '${diario.totalCarboidratos.round()}g / ${metaCarb.round()}g',
                          percCarb,
                          TemaApp.corAviso,
                        ),
                        const SizedBox(height: 8),
                        _barraProgressoMacro(
                          context,
                          'Gorduras',
                          '${diario.totalLipidios.round()}g / ${metaFat.round()}g',
                          percFat,
                          TemaApp.corAlerta,
                        ),
                        const SizedBox(height: 8),
                        _barraProgressoMacro(
                          context,
                          'Fibras',
                          '${diario.totalFibras.round()}g / ${metaFib.round()}g',
                          percFib,
                          Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Blocos de Refeições
            Expanded(
              child: diario.carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: TemaApp.corPrincipal,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _cardRefeicao(
                          context,
                          ref,
                          'Café da Manhã',
                          'Breakfast',
                          diario.obterPorTipo('Breakfast'),
                        ),
                        _cardRefeicao(
                          context,
                          ref,
                          'Almoço',
                          'Lunch',
                          diario.obterPorTipo('Lunch'),
                        ),
                        _cardRefeicao(
                          context,
                          ref,
                          'Jantar',
                          'Dinner',
                          diario.obterPorTipo('Dinner'),
                        ),
                        _cardRefeicao(
                          context,
                          ref,
                          'Lanche',
                          'Snack',
                          diario.obterPorTipo('Snack'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraProgressoMacro(
    BuildContext context,
    String nome,
    String legenda,
    double valor,
    Color cor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nome,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              legenda,
              style: TextStyle(fontSize: 10, color: TemaApp.corTextoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearPercentIndicator(
          lineHeight: 6.0,
          percent: valor,
          backgroundColor: TemaApp.corCardBorda,
          progressColor: cor,
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _cardRefeicao(
    BuildContext context,
    WidgetRef ref,
    String tituloExibicao,
    String tipoRefeicao,
    List<Refeicao> refeicoes,
  ) {
    final alimentosList = <ItemAlimentoRefeicao>[];
    String? mealId;
    bool synced = true;

    for (final meal in refeicoes) {
      mealId = meal.id;
      synced = meal.sincronizadoEm != null;
      alimentosList.addAll(meal.alimentos);
    }

    final totalCalorias = alimentosList.fold(
      0.0,
      (s, a) => s + a.caloriasCalculadas,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do bloco de refeição
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloExibicao,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${totalCalorias.round()} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaApp.corPrincipal,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (mealId != null && !synced)
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: TemaApp.corAviso,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: TemaApp.corPrincipal,
                      ),
                      onPressed: () {
                        context.push(
                          '/food/search?meal_type=$tipoRefeicao&meal_id=$mealId',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: TemaApp.corCardBorda, height: 20),

            // Alimentos consumidos
            if (alimentosList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Nenhum alimento cadastrado.',
                  style: TextStyle(
                    color: TemaApp.corTextoSecundario,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alimentosList.length,
                itemBuilder: (context, idx) {
                  final item = alimentosList[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.alimento.nome,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${item.quantidade.round()}g',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TemaApp.corTextoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${item.caloriasCalculadas.round()} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: TemaApp.corAlerta,
                                size: 18,
                              ),
                              onPressed: () {
                                // Cria uma nova lista sem o elemento removido
                                alimentosList.removeAt(idx);
                                if (mealId != null) {
                                  if (alimentosList.isEmpty) {
                                    ref
                                        .read(
                                          provedorDiarioAlimentacao.notifier,
                                        )
                                        .deletarRefeicao(mealId);
                                  } else {
                                    final novaRefeicao = Refeicao(
                                      id: mealId,
                                      tipoRefeicao: tipoRefeicao,
                                      consumidoEm: DateTime.now(),
                                      alimentos: alimentosList,
                                    );
                                    ref
                                        .read(
                                          provedorDiarioAlimentacao.notifier,
                                        )
                                        .salvarRefeicao(novaRefeicao);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
