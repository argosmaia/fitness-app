import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repositorio_alimentacao.dart';
import '../../domain/entities/refeicao.dart';
import '../../domain/entities/alimento.dart';
import '../../../auth/presentation/providers/provedor_autenticacao.dart';

// Provedor do repositório
final provedorRepositorioAlimentacao = Provider<RepositorioAlimentacao>((ref) {
  final clienteApi = ref.watch(provedorClienteApi);
  return RepositorioAlimentacao(clienteApi);
});

// NOTIFICADOR DO DIÁRIO DE ALIMENTAÇÃO (FECHAMENTO DIÁRIO)
class EstadoDiarioAlimentacao {
  final List<Refeicao> refeicoes;
  final DateTime dataSelecionada;
  final bool carregando;

  EstadoDiarioAlimentacao({
    this.refeicoes = const [],
    required this.dataSelecionada,
    this.carregando = false,
  });

  // Somatórios Globais do Dia
  double get totalCalorias =>
      refeicoes.fold(0.0, (s, m) => s + m.totalCalorias);
  double get totalProteinas =>
      refeicoes.fold(0.0, (s, m) => s + m.totalProteinas);
  double get totalCarboidratos =>
      refeicoes.fold(0.0, (s, m) => s + m.totalCarboidratos);
  double get totalLipidios =>
      refeicoes.fold(0.0, (s, m) => s + m.totalLipidios);
  double get totalFibras => refeicoes.fold(0.0, (s, m) => s + m.totalFibras);

  List<Refeicao> obterPorTipo(String tipo) {
    return refeicoes
        .where((m) => m.tipoRefeicao.toLowerCase() == tipo.toLowerCase())
        .toList();
  }

  EstadoDiarioAlimentacao copiarCom({
    List<Refeicao>? refeicoes,
    DateTime? dataSelecionada,
    bool? carregando,
  }) {
    return EstadoDiarioAlimentacao(
      refeicoes: refeicoes ?? this.refeicoes,
      dataSelecionada: dataSelecionada ?? this.dataSelecionada,
      carregando: carregando ?? this.carregando,
    );
  }
}

class NotificadorDiarioAlimentacao
    extends StateNotifier<EstadoDiarioAlimentacao> {
  final RepositorioAlimentacao _repositorio;

  NotificadorDiarioAlimentacao(this._repositorio)
    : super(EstadoDiarioAlimentacao(dataSelecionada: DateTime.now())) {
    carregarRefeicoes();
  }

  /// Carrega as refeições da data atualmente selecionada.
  Future<void> carregarRefeicoes() async {
    state = state.copiarCom(carregando: true);
    try {
      final refeicoes = await _repositorio.obterRefeicoesPorData(
        state.dataSelecionada,
      );
      state = state.copiarCom(refeicoes: refeicoes, carregando: false);
    } catch (e) {
      state = state.copiarCom(carregando: false);
    }
  }

  /// Muda a data ativa do diário e recarrega os dados.
  void alterarData(DateTime novaData) {
    state = state.copiarCom(dataSelecionada: novaData);
    carregarRefeicoes();
  }

  /// Salva uma refeição localmente e atualiza o diário.
  Future<void> salvarRefeicao(Refeicao refeicao) async {
    state = state.copiarCom(carregando: true);
    await _repositorio.salvarRefeicao(refeicao);
    await carregarRefeicoes();
  }

  /// Deleta uma refeição localmente.
  Future<void> deletarRefeicao(String id) async {
    state = state.copiarCom(carregando: true);
    await _repositorio.deletarRefeicao(id);
    await carregarRefeicoes();
  }
}

final provedorDiarioAlimentacao =
    StateNotifierProvider<
      NotificadorDiarioAlimentacao,
      EstadoDiarioAlimentacao
    >((ref) {
      final repo = ref.watch(provedorRepositorioAlimentacao);
      return NotificadorDiarioAlimentacao(repo);
    });

// NOTIFICADOR DE BUSCA DE ALIMENTOS
class EstadoBuscaAlimentos {
  final List<Alimento> resultados;
  final bool buscando;

  EstadoBuscaAlimentos({this.resultados = const [], this.buscando = false});
}

class NotificadorBuscaAlimentos extends StateNotifier<EstadoBuscaAlimentos> {
  final RepositorioAlimentacao _repositorio;

  NotificadorBuscaAlimentos(this._repositorio) : super(EstadoBuscaAlimentos());

  Future<void> pesquisar(String query) async {
    if (query.trim().isEmpty) {
      state = EstadoBuscaAlimentos();
      return;
    }

    state = EstadoBuscaAlimentos(buscando: true);
    final resultados = await _repositorio.buscarAlimentos(query);
    state = EstadoBuscaAlimentos(resultados: resultados, buscando: false);
  }
}

final provedorBuscaAlimentos =
    StateNotifierProvider<NotificadorBuscaAlimentos, EstadoBuscaAlimentos>((
      ref,
    ) {
      final repo = ref.watch(provedorRepositorioAlimentacao);
      return NotificadorBuscaAlimentos(repo);
    });
