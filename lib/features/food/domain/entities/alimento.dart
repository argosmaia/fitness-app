/// Entidade de domínio que representa um alimento (tabela TACO ou personalizado).
class Alimento {
  final String id;
  final String nome;
  final String? marca;
  final double calorias;
  final double proteinas;
  final double carboidratos;
  final double lipidios;
  final double fibras;
  final String tamanhoPorcao;

  Alimento({
    required this.id,
    required this.nome,
    this.marca,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.lipidios,
    required this.fibras,
    required this.tamanhoPorcao,
  });

  /// Construtor a partir de dados da API ou Banco Local.
  factory Alimento.deJson(Map<String, dynamic> json) {
    // Trata tanto a estrutura da tabela foods quanto subestruturas de macros da API
    final macros = json['macros'] as Map<String, dynamic>?;

    return Alimento(
      id: json['id']?.toString() ?? '',
      nome: json['name'] as String? ?? json['description'] as String? ?? '',
      marca: json['brand'] as String?,
      calorias: macros != null
          ? (macros['kcal'] as num).toDouble()
          : (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinas: macros != null
          ? (macros['protein'] as num).toDouble()
          : (json['protein'] as num?)?.toDouble() ?? 0.0,
      carboidratos: macros != null
          ? (macros['carbohydrate'] as num).toDouble()
          : (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      lipidios: macros != null
          ? (macros['lipids'] as num).toDouble()
          : (json['fat'] as num?)?.toDouble() ?? 0.0,
      fibras: macros != null
          ? (macros['fiber'] as num).toDouble()
          : (json['fiber'] as num?)?.toDouble() ?? 0.0,
      tamanhoPorcao: json['serving_size'] as String? ?? '100g',
    );
  }

  /// Converte para Map para salvar no SQLite.
  Map<String, dynamic> paraJson() {
    return {
      'id': id,
      'name': nome,
      'brand': marca,
      'calories': calorias,
      'protein': proteinas,
      'carbohydrates': carboidratos,
      'fat': lipidios,
      'fiber': fibras,
      'serving_size': tamanhoPorcao,
    };
  }
}
