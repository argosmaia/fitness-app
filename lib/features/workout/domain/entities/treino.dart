import 'exercicio.dart';

/// Entidade de domínio que representa uma sessão de treino do usuário.
class Treino {
  final String id;
  final String nome;
  final String? descricao;
  final DateTime iniciadoEm;
  final DateTime? finalizadoEm;
  final int duracaoSegundos;
  final int calorias;
  final List<Exercicio> exercicios;
  final DateTime? sincronizadoEm;
  final bool deletadoLocalmente;

  Treino({
    required this.id,
    required this.nome,
    this.descricao,
    required this.iniciadoEm,
    this.finalizadoEm,
    required this.duracaoSegundos,
    required this.calorias,
    required this.exercicios,
    this.sincronizadoEm,
    this.deletadoLocalmente = false,
  });

  /// Construtor a partir dos dados do banco/API.
  factory Treino.deJson(Map<String, dynamic> json) {
    var listaEx = <Exercicio>[];
    if (json['exercises'] != null) {
      listaEx = (json['exercises'] as List)
          .map((e) => Exercicio.deJson(e as Map<String, dynamic>))
          .toList();
    }
    return Treino(
      id: json['id'] as String,
      nome: json['name'] as String,
      descricao: json['description'] as String?,
      iniciadoEm: DateTime.parse(json['started_at'] as String),
      finalizadoEm: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      duracaoSegundos: json['duration_seconds'] as int? ?? 0,
      calorias: json['calories'] as int? ?? 0,
      exercicios: listaEx,
      sincronizadoEm: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
      deletadoLocalmente: (json['deleted_locally'] as int? ?? 0) == 1,
    );
  }

  /// Converte para Map para salvar no SQLite ou enviar à API.
  Map<String, dynamic> paraJson() {
    return {
      'id': id,
      'name': nome,
      'description': descricao,
      'started_at': iniciadoEm.toUtc().toIso8601String(),
      'finished_at': finalizadoEm?.toUtc().toIso8601String(),
      'duration_seconds': duracaoSegundos,
      'calories': calorias,
      'exercises': exercicios.map((e) => e.paraJson()).toList(),
      'synced_at': sincronizadoEm?.toUtc().toIso8601String(),
      'deleted_locally': deletadoLocalmente ? 1 : 0,
    };
  }

  Treino copiarCom({
    String? nome,
    String? descricao,
    DateTime? finalizadoEm,
    int? duracaoSegundos,
    int? calorias,
    List<Exercicio>? exercicios,
    DateTime? sincronizadoEm,
    bool? deletadoLocalmente,
  }) {
    return Treino(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      iniciadoEm: iniciadoEm,
      finalizadoEm: finalizadoEm ?? this.finalizadoEm,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
      calorias: calorias ?? this.calorias,
      exercicios: exercicios ?? this.exercicios,
      sincronizadoEm: sincronizadoEm ?? this.sincronizadoEm,
      deletadoLocalmente: deletadoLocalmente ?? this.deletadoLocalmente,
    );
  }
}
