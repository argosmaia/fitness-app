import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_treinos.dart';

/// Tela que exibe detalhes estáticos de um treino concluído.
class PaginaDetalheTreino extends ConsumerWidget {
  final String idTreino;

  const PaginaDetalheTreino({super.key, required this.idTreino});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLista = ref.watch(provedorListaTreinos);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Treino')),
      body: estadoLista.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TemaApp.corPrincipal),
        ),
        error: (erro, _) =>
            Center(child: Text('Erro ao carregar detalhes: $erro')),
        data: (treinos) {
          // Procura o treino correspondente na lista cacheada do provider
          final treino = treinos.firstWhere(
            (t) => t.id == idTreino,
            orElse: () => null as dynamic,
          );

          if (treino == null) {
            return const Center(child: Text('Treino não encontrado.'));
          }

          final minutos = (treino.duracaoSegundos / 60).round();

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header de Resumo
                Container(
                  padding: const EdgeInsets.all(24.0),
                  color: TemaApp.corCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              treino.nome,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (treino.sincronizadoEm == null)
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: TemaApp.corAviso,
                            )
                          else
                            const Icon(
                              Icons.cloud_done_rounded,
                              color: TemaApp.corPrincipal,
                            ),
                        ],
                      ),
                      if (treino.descricao != null &&
                          treino.descricao!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          treino.descricao!,
                          style: TextStyle(color: TemaApp.corTextoSecundario),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _itemResumo(
                            context,
                            Icons.timer_outlined,
                            '$minutos min',
                            'Duração',
                            TemaApp.corSecundaria,
                          ),
                          _itemResumo(
                            context,
                            Icons.local_fire_department_outlined,
                            '${treino.calorias} kcal',
                            'Queima',
                            TemaApp.corAlerta,
                          ),
                          _itemResumo(
                            context,
                            Icons.calendar_month_outlined,
                            '${treino.iniciadoEm.day}/${treino.iniciadoEm.month}',
                            'Data',
                            TemaApp.corTextoSecundario,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de Exercícios
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: treino.exercicios.length,
                    itemBuilder: (context, indice) {
                      final ex = treino.exercicios[indice];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${ex.series} séries',
                                    style: const TextStyle(
                                      color: TemaApp.corPrincipal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (ex.repeticoes != null)
                                    Text(
                                      '${ex.repeticoes} reps',
                                      style: TextStyle(
                                        color: TemaApp.corTextoSecundario,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  if (ex.peso != null)
                                    Text(
                                      '${ex.peso} kg',
                                      style: TextStyle(
                                        color: TemaApp.corTextoSecundario,
                                      ),
                                    ),
                                ],
                              ),
                              if (ex.observacoes != null &&
                                  ex.observacoes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Obs: ${ex.observacoes}',
                                  style: TextStyle(
                                    color: TemaApp.corTextoSecundario,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Ações do rodapé
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Duplicar
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(provedorListaTreinos.notifier)
                                .duplicarTreino(treino.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Treino duplicado para hoje!'),
                                backgroundColor: TemaApp.corPrincipal,
                              ),
                            );
                            context.pop();
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Duplicar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: TemaApp.corCardBorda),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Excluir
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: TemaApp.corCard,
                                title: const Text('Excluir Treino'),
                                content: const Text(
                                  'Tem certeza que deseja excluir permanentemente este treino?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Excluir',
                                      style: TextStyle(
                                        color: TemaApp.corAlerta,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmar == true) {
                              await ref
                                  .read(provedorListaTreinos.notifier)
                                  .deletarTreino(treino.id);
                              context.pop();
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Excluir',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TemaApp.corAlerta,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _itemResumo(
    BuildContext context,
    IconData icone,
    String valor,
    String rotulo,
    Color corIcone,
  ) {
    return Row(
      children: [
        Icon(icone, color: corIcone, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              rotulo,
              style: TextStyle(color: TemaApp.corTextoSecundario, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
