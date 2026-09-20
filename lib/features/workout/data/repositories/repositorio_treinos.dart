import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/gerenciador_banco_dados.dart';
import '../../domain/entities/treino.dart';
import '../../domain/entities/exercicio.dart';

/// Repositório de Treinos responsável pelas operações offline-first no SQLite.
class RepositorioTreinos {
  final _gerenciadorDb = GerenciadorBancoDados.instancia;

  /// Retorna todos os treinos que não foram marcados para deleção local.
  Future<List<Treino>> obterTreinos() async {
    final db = await _gerenciadorDb.bancoDados;

    // Busca os treinos não excluídos localmente
    final resultadoTreinos = await db.query(
      'workouts',
      where: 'deleted_locally = 0',
      orderBy: 'started_at DESC',
    );

    final listaTreinos = <Treino>[];

    for (final linhaTreino in resultadoTreinos) {
      final treinoId = linhaTreino['id'] as String;

      // Busca os exercícios relacionados
      final resultadoExercicios = await db.query(
        'exercises',
        where: 'workout_id = ?',
        whereArgs: [treinoId],
      );

      final exercicios = resultadoExercicios
          .map((e) => Exercicio.deJson(e))
          .toList();

      final treinoJson = Map<String, dynamic>.from(linhaTreino);
      treinoJson['exercises'] = exercicios.map((e) => e.paraJson()).toList();

      listaTreinos.add(Treino.deJson(treinoJson));
    }

    return listaTreinos;
  }

  /// Busca um treino específico pelo ID no SQLite local.
  Future<Treino?> obterTreinoPorId(String id) async {
    final db = await _gerenciadorDb.bancoDados;

    final resultadoTreinos = await db.query(
      'workouts',
      where: 'id = ? AND deleted_locally = 0',
      whereArgs: [id],
    );

    if (resultadoTreinos.isEmpty) return null;

    final resultadoExercicios = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [id],
    );

    final exercicios = resultadoExercicios
        .map((e) => Exercicio.deJson(e))
        .toList();

    final treinoJson = Map<String, dynamic>.from(resultadoTreinos.first);
    treinoJson['exercises'] = exercicios.map((e) => e.paraJson()).toList();

    return Treino.deJson(treinoJson);
  }

  /// Salva ou atualiza um treino e seus exercícios no SQLite local.
  Future<void> salvarTreino(Treino treino) async {
    final db = await _gerenciadorDb.bancoDados;

    await db.transaction((txn) async {
      // 1. Insere ou substitui o treino principal
      await txn.insert('workouts', {
        'id': treino.id,
        'name': treino.nome,
        'description': treino.descricao,
        'started_at': treino.iniciadoEm.toIso8601String(),
        'finished_at': treino.finalizadoEm?.toIso8601String(),
        'duration_seconds': treino.duracaoSegundos,
        'calories': treino.calorias,
        'synced_at': treino.sincronizadoEm?.toIso8601String(),
        'deleted_locally': treino.deletadoLocalmente ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Remove exercícios antigos antes do replace
      await txn.delete(
        'exercises',
        where: 'workout_id = ?',
        whereArgs: [treino.id],
      );

      // 3. Insere todos os exercícios associados
      for (final ex in treino.exercicios) {
        await txn.insert('exercises', {
          'id': ex.id,
          'workout_id': treino.id,
          'name': ex.nome,
          'sets': ex.series,
          'reps': ex.repeticoes,
          'weight': ex.peso,
          'rest_seconds': ex.tempoDescanso,
          'notes': ex.observacoes,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Exclui o treino de forma offline (soft delete local).
  Future<void> deletarTreino(String id) async {
    final db = await _gerenciadorDb.bancoDados;

    final treino = await obterTreinoPorId(id);
    if (treino == null) return;

    if (treino.sincronizadoEm == null) {
      // Se nunca foi sincronizado com o servidor, pode deletar fisicamente logo
      await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
    } else {
      // Se já está na nuvem, faz soft delete para enviar a exclusão no sync
      await db.update(
        'workouts',
        {'deleted_locally': 1, 'synced_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Duplica um treino existente criando um novo com data de início 'agora' e id novo.
  Future<Treino?> duplicarTreino(String id) async {
    final original = await obterTreinoPorId(id);
    if (original == null) return null;

    final uuid = const Uuid();
    final novoTreinoId = uuid.v4();

    final novosExercicios = original.exercicios.map((ex) {
      return Exercicio(
        id: uuid.v4(),
        nome: ex.nome,
        series: ex.series,
        repeticoes: ex.repeticoes,
        peso: ex.peso,
        tempoDescanso: ex.tempoDescanso,
        observacoes: ex.observacoes,
      );
    }).toList();

    final novoTreino = Treino(
      id: novoTreinoId,
      nome: '${original.nome} (Cópia)',
      descricao: original.descricao,
      iniciadoEm: DateTime.now(),
      duracaoSegundos: 0,
      calorias: 0,
      exercicios: novosExercicios,
      sincronizadoEm: null,
      deletadoLocalmente: false,
    );

    await salvarTreino(novoTreino);
    return novoTreino;
  }
}
