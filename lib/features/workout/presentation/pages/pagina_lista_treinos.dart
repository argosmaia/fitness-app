import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_treinos.dart';

/// Tela que exibe o histórico de treinos salvos localmente.
class PaginaListaTreinos extends ConsumerWidget {
  const PaginaListaTreinos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLista = ref.watch(provedorListaTreinos);
    final treinoAtivo = ref.watch(provedorTreinoAtivo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(provedorListaTreinos.notifier).carregarTreinos();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Botão Iniciar Novo Treino
              GestureDetector(
                onTap: () {
                  if (treinoAtivo.emExecucao) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Você já possui uma sessão ativa. Finalize-a primeiro.',
                        ),
                        backgroundColor: TemaApp.corAviso,
                      ),
                    );
                    context.push('/workouts/track');
                  } else {
                    ref
                        .read(provedorTreinoAtivo.notifier)
                        .iniciarTreino('Treino de Hipertrofia');
                    context.push('/workouts/track');
                  }
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: TemaApp.gradienteSaude,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: TemaApp.sombrasPremium,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: TemaApp.corFundo,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciar Novo Treino',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TemaApp.corFundo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Histórico de Treinos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Lista de Cards
              Expanded(
                child: estadoLista.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: TemaApp.corPrincipal,
                    ),
                  ),
                  error: (erro, _) =>
                      Center(child: Text('Erro ao carregar treinos: $erro')),
                  data: (treinos) {
                    if (treinos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 64,
                              color: TemaApp.corTextoInativo,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhum treino registrado ainda.',
                              style: TextStyle(
                                color: TemaApp.corTextoSecundario,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: treinos.length,
                      itemBuilder: (context, indice) {
                        final treino = treinos[indice];
                        final minutos = (treino.duracaoSegundos / 60).round();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => context.push('/workouts/${treino.id}'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          treino.nome,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      // Indicador Offline-First
                                      if (treino.sincronizadoEm == null)
                                        const Icon(
                                          Icons.cloud_off_rounded,
                                          color: TemaApp.corAviso,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.cloud_done_rounded,
                                          color: TemaApp.corPrincipal,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        size: 14,
                                        color: TemaApp.corTextoSecundario,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${treino.iniciadoEm.day}/${treino.iniciadoEm.month} às ${treino.iniciadoEm.hour}:${treino.iniciadoEm.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: TemaApp.corTextoSecundario,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 16,
                                            color: TemaApp.corSecundaria,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$minutos min',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .local_fire_department_outlined,
                                            size: 16,
                                            color: TemaApp.corAlerta,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${treino.calorias} kcal',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${treino.exercicios.length} exercícios',
                                        style: TextStyle(
                                          color: TemaApp.corTextoSecundario,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
