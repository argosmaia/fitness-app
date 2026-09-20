/// Entidade de domínio que representa um exercício de um treino.
class Exercicio {
  final String id;
  final String nome;
  final int series;
  final int? repeticoes;
  final double? peso;
  final int? tempoDescanso; // em segundos
  final String? observacoes;

  Exercicio({
    required this.id,
    required this.nome,
    required this.series,
    this.repeticoes,
    this.peso,
    this.tempoDescanso,
    this.observacoes,
  });

  /// Construtor a partir dos dados do banco/API.
  factory Exercicio.deJson(Map<String, dynamic> json) {
    return Exercicio(
      id: json['id'] as String,
      nome: json['name'] as String,
      series: json['sets'] as int,
      repeticoes: json['reps'] as int?,
      peso: (json['weight'] as num?)?.toDouble(),
      tempoDescanso: json['rest_seconds'] as int?,
      observacoes: json['notes'] as String?,
    );
  }

  /// Converte para Map.
  Map<String, dynamic> paraJson() {
    return {
      'id': id,
      'name': nome,
      'sets': series,
      'reps': repeticoes,
      'weight': peso,
      'rest_seconds': tempoDescanso,
      'notes': observacoes,
    };
  }

  Exercicio copiarCom({
    int? series,
    int? repeticoes,
    double? peso,
    String? observacoes,
  }) {
    return Exercicio(
      id: id,
      nome: nome,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      peso: peso ?? this.peso,
      tempoDescanso: tempoDescanso,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}
