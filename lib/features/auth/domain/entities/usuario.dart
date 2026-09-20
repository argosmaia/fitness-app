/// Entidade de domínio que representa o perfil do usuário e suas metas biométricas.
class Usuario {
  final String id;
  final String nome;
  final String email;
  final DateTime? dataNascimento;
  final String genero;
  final double altura;
  final double pesoAtual;
  final double pesoMeta;
  final int metaAguaDiaria;
  final int metaCaloriasDiaria;
  final DateTime? criadoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.dataNascimento,
    required this.genero,
    required this.altura,
    required this.pesoAtual,
    required this.pesoMeta,
    required this.metaAguaDiaria,
    required this.metaCaloriasDiaria,
    this.criadoEm,
  });

  /// Construtor a partir de dados da API.
  factory Usuario.deJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nome: json['name'] as String,
      email: json['email'] as String,
      dataNascimento: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      genero: json['gender'] as String? ?? 'male',
      altura: (json['height'] as num?)?.toDouble() ?? 170.0,
      pesoAtual: (json['weight'] as num?)?.toDouble() ?? 70.0,
      pesoMeta: (json['goal_weight'] as num?)?.toDouble() ?? 70.0,
      metaAguaDiaria: json['daily_water_goal'] as int? ?? 2000,
      metaCaloriasDiaria: json['daily_kcal_goal'] as int? ?? 2000,
      criadoEm: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converte para Map para salvar no SQLite ou enviar à API.
  Map<String, dynamic> paraJson() {
    return {
      'id': id,
      'name': nome,
      'email': email,
      'birth_date': dataNascimento?.toIso8601String().split('T').first,
      'gender': genero,
      'height': altura,
      'weight': pesoAtual,
      'goal_weight': pesoMeta,
      'daily_water_goal': metaAguaDiaria,
      'daily_kcal_goal': metaCaloriasDiaria,
      'created_at': criadoEm?.toIso8601String(),
    };
  }

  Usuario copiarCom({
    String? nome,
    double? altura,
    double? pesoAtual,
    double? pesoMeta,
    int? metaAguaDiaria,
    int? metaCaloriasDiaria,
  }) {
    return Usuario(
      id: id,
      nome: nome ?? this.nome,
      email: email,
      dataNascimento: dataNascimento,
      genero: genero,
      altura: altura ?? this.altura,
      pesoAtual: pesoAtual ?? this.pesoAtual,
      pesoMeta: pesoMeta ?? this.pesoMeta,
      metaAguaDiaria: metaAguaDiaria ?? this.metaAguaDiaria,
      metaCaloriasDiaria: metaCaloriasDiaria ?? this.metaCaloriasDiaria,
      criadoEm: criadoEm,
    );
  }
}
