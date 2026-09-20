import 'alimento.dart';

/// Representa um alimento associado a uma refeição com sua respectiva gramagem consumida.
class ItemAlimentoRefeicao {
  final Alimento alimento;
  final double quantidade; // em gramas

  ItemAlimentoRefeicao({required this.alimento, required this.quantidade});

  /// Calcula as calorias proporcionais consumidas.
  double get caloriasCalculadas => (alimento.calorias * quantidade) / 100.0;
  double get proteinasCalculadas => (alimento.proteinas * quantidade) / 100.0;
  double get carboidratosCalculadas =>
      (alimento.carboidratos * quantidade) / 100.0;
  double get lipidiosCalculadas => (alimento.lipidios * quantidade) / 100.0;
  double get fibrasCalculadas => (alimento.fibras * quantidade) / 100.0;
}

/// Entidade de domínio que representa uma refeição (Café da Manhã, Almoço, etc.).
class Refeicao {
  final String id;
  final String tipoRefeicao; // Breakfast, Lunch, Dinner, Snack
  final DateTime consumidoEm;
  final List<ItemAlimentoRefeicao> alimentos;
  final DateTime? sincronizadoEm;
  final bool deletadoLocalmente;

  Refeicao({
    required this.id,
    required this.tipoRefeicao,
    required this.consumidoEm,
    required this.alimentos,
    this.sincronizadoEm,
    this.deletadoLocalmente = false,
  });

  /// Calcula o total calórico acumulado da refeição.
  double get totalCalorias =>
      alimentos.fold(0.0, (soma, item) => soma + item.caloriasCalculadas);
  double get totalProteinas =>
      alimentos.fold(0.0, (soma, item) => soma + item.proteinasCalculadas);
  double get totalCarboidratos =>
      alimentos.fold(0.0, (soma, item) => soma + item.carboidratosCalculadas);
  double get totalLipidios =>
      alimentos.fold(0.0, (soma, item) => soma + item.lipidiosCalculadas);
  double get totalFibras =>
      alimentos.fold(0.0, (soma, item) => soma + item.fibrasCalculadas);

  factory Refeicao.deJson(
    Map<String, dynamic> json,
    List<ItemAlimentoRefeicao> alimentos,
  ) {
    return Refeicao(
      id: json['id'] as String,
      tipoRefeicao: json['meal_type'] as String,
      consumidoEm: DateTime.parse(json['consumed_at'] as String),
      alimentos: alimentos,
      sincronizadoEm: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      deletadoLocalmente: (json['deleted_locally'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> paraJson() {
    return {
      'id': id,
      'meal_type': tipoRefeicao,
      'consumed_at': consumidoEm.toUtc().toIso8601String(),
      'synced_at': sincronizadoEm?.toUtc().toIso8601String(),
      'deleted_locally': deletadoLocalmente ? 1 : 0,
      'foods': alimentos
          .map(
            (item) => {
              'food_id': item.alimento.id,
              'quantity': item.quantidade,
            },
          )
          .toList(),
    };
  }
}
