import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_treinos.dart';

/// Tela de execução e rastreamento de treino ativo com cronômetro e timer de descanso.
class PaginaExecucaoTreino extends ConsumerStatefulWidget {
  const PaginaExecucaoTreino({super.key});

  @override
  ConsumerState<PaginaExecucaoTreino> createState() =>
      _PaginaExecucaoTreinoState();
}

class _PaginaExecucaoTreinoState extends ConsumerState<PaginaExecucaoTreino> {
  Timer? _cronometroDescanso;
  int _tempoDescansoRestante = 0;

  void _iniciarDescanso(int segundos) {
    _cronometroDescanso?.cancel();
    setState(() {
      _tempoDescansoRestante = segundos;
    });

    // Exibe pop-up de descanso
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaApp.corCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final timerLocal = Timer.periodic(const Duration(seconds: 1), (t) {
              if (_tempoDescansoRestante > 0) {
                setModalState(() {
                  _tempoDescansoRestante--;
                });
              } else {
                t.cancel();
                Navigator.pop(context);
              }
            });

            return WillPopScope(
              onWillPop: () async {
                timerLocal.cancel();
                return true;
              },
              child: Container(
                padding: const EdgeInsets.all(32.0),
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: TemaApp.corSecundaria,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hora de Descansar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Próxima série em:',
                      style: TextStyle(color: TemaApp.corTextoSecundario),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_tempoDescansoRestante s',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 48,
                            color: TemaApp.corPrincipal,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _cronometroDescanso?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoAtivo = ref.watch(provedorTreinoAtivo);

    if (estadoAtivo.treino == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treinar')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nenhum treino em andamento.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final minutos = (estadoAtivo.segundosDecorridos ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final segundos = (estadoAtivo.segundosDecorridos % 60).toString().padLeft(
      2,
      '0',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(estadoAtivo.treino!.nome),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final cancelar = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: TemaApp.corCard,
                title: const Text('Cancelar Treino?'),
                content: const Text(
                  'Deseja descartar este treino? Os dados desta sessão ativa serão perdidos.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continuar'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(provedorTreinoAtivo.notifier).cancelarTreino();
                      Navigator.pop(context, true);
                    },
                    child: const Text(
                      'Descartar',
                      style: TextStyle(color: TemaApp.corAlerta),
                    ),
                  ),
                ],
              ),
            );
            if (cancelar == true) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Painel Superior de Status (Timer e Calorias)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: TemaApp.corCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEMPO DECORRIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TemaApp.corTextoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$minutos:$segundos',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'CALORIAS ESTIMADAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: TemaApp.corTextoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${estadoAtivo.caloriasEstimadas} kcal',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: TemaApp.corPrincipal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de Exercícios
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: estadoAtivo.treino!.exercicios.length,
                itemBuilder: (context, indexExercicio) {
                  final ex = estadoAtivo.treino!.exercicios[indexExercicio];
                  final checklists = estadoAtivo.seriesConcluidas[ex.id] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ex.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${ex.tempoDescanso ?? 60}s descanso',
                                style: const TextStyle(
                                  color: TemaApp.corSecundaria,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Ajustes Rápidos (Peso e Repetições)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex.peso?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Carga (kg)',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    final peso = double.tryParse(val);
                                    if (peso != null) {
                                      ref
                                          .read(provedorTreinoAtivo.notifier)
                                          .atualizarDadosExercicio(
                                            ex.id,
                                            peso: peso,
                                          );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ex.repeticoes?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Repetições',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    final reps = int.tryParse(val);
                                    if (reps != null) {
                                      ref
                                          .read(provedorTreinoAtivo.notifier)
                                          .atualizarDadosExercicio(
                                            ex.id,
                                            reps: reps,
                                          );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checklist de séries
                          const Text(
                            'Séries Realizadas:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: TemaApp.corTextoSecundario,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: List.generate(ex.series, (indexSerie) {
                              final concluido = indexSerie < checklists.length
                                  ? checklists[indexSerie]
                                  : false;
                              return GestureDetector(
                                onTap: () {
                                  final foiConcluido = ref
                                      .read(provedorTreinoAtivo.notifier)
                                      .alternarSerie(ex.id, indexSerie);
                                  if (foiConcluido) {
                                    _iniciarDescanso(ex.tempoDescanso ?? 60);
                                  }
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: concluido
                                        ? TemaApp.corPrincipal
                                        : TemaApp.corCardBorda,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${indexSerie + 1}',
                                      style: TextStyle(
                                        color: concluido
                                            ? TemaApp.corFundo
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Botão Concluir Treino
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: () async {
                  await ref
                      .read(provedorTreinoAtivo.notifier)
                      .concluirTreino(ref);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Treino salvo com sucesso no SQLite local!',
                      ),
                      backgroundColor: TemaApp.corPrincipal,
                    ),
                  );
                  context.pop();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: TemaApp.gradienteSaude,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: TemaApp.sombrasPremium,
                  ),
                  child: Center(
                    child: Text(
                      'Concluir Treino',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: TemaApp.corFundo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
