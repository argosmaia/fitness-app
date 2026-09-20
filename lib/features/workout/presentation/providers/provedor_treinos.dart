import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/repositorio_treinos.dart';
import '../../domain/entities/treino.dart';
import '../../domain/entities/exercicio.dart';

// Provedor para expor a instância do repositório
final provedorRepositorioTreinos = Provider<RepositorioTreinos>(
  (ref) => RepositorioTreinos(),
);

// NOTIFICADOR DA LISTA DE TREINOS
class NotificadorListaTreinos extends StateNotifier<AsyncValue<List<Treino>>> {
  final RepositorioTreinos _repositorio;

  NotificadorListaTreinos(this._repositorio)
    : super(const AsyncValue.loading()) {
    carregarTreinos();
  }

  Future<void> carregarTreinos() async {
    state = const AsyncValue.loading();
    try {
      final treinos = await _repositorio.obterTreinos();
      state = AsyncValue.data(treinos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletarTreino(String id) async {
    try {
      await _repositorio.deletarTreino(id);
      await carregarTreinos();
    } catch (e) {
      print('Erro ao deletar treino: $e');
    }
  }

  Future<void> duplicarTreino(String id) async {
    try {
      await _repositorio.duplicarTreino(id);
      await carregarTreinos();
    } catch (e) {
      print('Erro ao duplicar treino: $e');
    }
  }
}

final provedorListaTreinos =
    StateNotifierProvider<NotificadorListaTreinos, AsyncValue<List<Treino>>>((
      ref,
    ) {
      final repo = ref.watch(provedorRepositorioTreinos);
      return NotificadorListaTreinos(repo);
    });

// NOTIFICADOR DO TREINO ATIVO (EM EXECUÇÃO)
class EstadoTreinoAtivo {
  final Treino? treino;
  final int segundosDecorridos;
  final int caloriasEstimadas;
  final Map<String, List<bool>>
  seriesConcluidas; // Mapeia id do exercício -> lista de booleanos (um para cada série)
  final bool emExecucao;

  EstadoTreinoAtivo({
    this.treino,
    this.segundosDecorridos = 0,
    this.caloriasEstimadas = 0,
    this.seriesConcluidas = const {},
    this.emExecucao = false,
  });

  EstadoTreinoAtivo copiarCom({
    Treino? treino,
    int? segundosDecorridos,
    int? caloriasEstimadas,
    Map<String, List<bool>>? seriesConcluidas,
    bool? emExecucao,
  }) {
    return EstadoTreinoAtivo(
      treino: treino ?? this.treino,
      segundosDecorridos: segundosDecorridos ?? this.segundosDecorridos,
      caloriasEstimadas: caloriasEstimadas ?? this.caloriasEstimadas,
      seriesConcluidas: seriesConcluidas ?? this.seriesConcluidas,
      emExecucao: emExecucao ?? this.emExecucao,
    );
  }
}

class NotificadorTreinoAtivo extends StateNotifier<EstadoTreinoAtivo> {
  final RepositorioTreinos _repositorio;
  Timer? _timer;

  NotificadorTreinoAtivo(this._repositorio) : super(EstadoTreinoAtivo());

  /// Inicia um novo treino em branco ou duplica uma rotina existente.
  void iniciarTreino(String nome, {List<Exercicio>? exerciciosPredefinidos}) {
    _timer?.cancel();
    final uuid = const Uuid();
    final treinoId = uuid.v4();

    final listaExercicios =
        exerciciosPredefinidos ??
        [
          Exercicio(
            id: uuid.v4(),
            nome: 'Supino Reto',
            series: 4,
            repeticoes: 10,
            peso: 60,
            tempoDescanso: 90,
          ),
          Exercicio(
            id: uuid.v4(),
            nome: 'Crucifixo Halter',
            series: 3,
            repeticoes: 12,
            peso: 16,
            tempoDescanso: 60,
          ),
        ];

    final novoTreino = Treino(
      id: treinoId,
      nome: nome,
      iniciadoEm: DateTime.now(),
      duracaoSegundos: 0,
      calorias: 0,
      exercicios: listaExercicios,
    );

    // Inicializa checklist de séries
    final mapaSeries = <String, List<bool>>{};
    for (final ex in listaExercicios) {
      mapaSeries[ex.id] = List.generate(ex.series, (_) => false);
    }

    state = EstadoTreinoAtivo(
      treino: novoTreino,
      segundosDecorridos: 0,
      caloriasEstimadas: 0,
      seriesConcluidas: mapaSeries,
      emExecucao: true,
    );

    // Dispara timer de contagem
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final segundos = state.segundosDecorridos + 1;

      // Cálculo de queima calórica estimado: 0.15 kcal por segundo (9 kcal por minuto) em média
      final calorias = (segundos * 0.12).round();

      state = state.copiarCom(
        segundosDecorridos: segundos,
        caloriasEstimadas: calorias,
      );
    });
  }

  /// Alterna o status (marcado/desmarcado) de uma série específica de um exercício.
  /// Retorna verdadeiro se a série foi marcada (para acionar o timer de descanso).
  bool alternarSerie(String exercicioId, int indiceSerie) {
    if (state.treino == null) return false;

    final mapaAtual = Map<String, List<bool>>.from(state.seriesConcluidas);
    final listaSeries = List<bool>.from(mapaAtual[exercicioId] ?? []);

    if (indiceSerie < listaSeries.length) {
      final novoValor = !listaSeries[indiceSerie];
      listaSeries[indiceSerie] = novoValor;
      mapaAtual[exercicioId] = listaSeries;

      state = state.copiarCom(seriesConcluidas: mapaAtual);
      return novoValor; // retorna true se concluiu a série
    }
    return false;
  }

  /// Modifica a carga ou repetições de um exercício na sessão ativa.
  void atualizarDadosExercicio(String exercicioId, {double? peso, int? reps}) {
    if (state.treino == null) return;

    final exerciciosAtualizados = state.treino!.exercicios.map((ex) {
      if (ex.id == exercicioId) {
        return ex.copiarCom(peso: peso, repeticoes: reps);
      }
      return ex;
    }).toList();

    state = state.copiarCom(
      treino: state.treino!.copiarCom(exercicios: exerciciosAtualizados),
    );
  }

  /// Conclui a sessão de treino salvando os dados no SQLite.
  Future<void> concluirTreino(WidgetRef ref) async {
    _timer?.cancel();
    if (state.treino == null) return;

    final treinoFinalizado = state.treino!.copiarCom(
      finalizadoEm: DateTime.now(),
      duracaoSegundos: state.segundosDecorridos,
      calorias: state.caloriasEstimadas,
    );

    // Salva localmente
    await _repositorio.salvarTreino(treinoFinalizado);

    // Reseta estado
    state = EstadoTreinoAtivo();

    // Recarrega lista
    ref.read(provedorListaTreinos.notifier).carregarTreinos();
  }

  /// Aborta o treino ativo sem salvar.
  void cancelarTreino() {
    _timer?.cancel();
    state = EstadoTreinoAtivo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final provedorTreinoAtivo =
    StateNotifierProvider<NotificadorTreinoAtivo, EstadoTreinoAtivo>((ref) {
      final repo = ref.watch(provedorRepositorioTreinos);
      return NotificadorTreinoAtivo(repo);
    });
