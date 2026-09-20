import 'package:sqflite/sqflite.dart';
import '../../../../core/api/cliente_api.dart';
import '../../../../core/db/gerenciador_banco_dados.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/refeicao.dart';

/// Repositório de Alimentação encarregado de sincronia local-remota da base de dados TACO e Refeições.
class RepositorioAlimentacao {
  final ClienteApi _clienteApi;
  final _gerenciadorDb = GerenciadorBancoDados.instancia;

  RepositorioAlimentacao(this._clienteApi);

  /// Retorna as refeições registradas localmente para uma data específica.
  Future<List<Refeicao>> obterRefeicoesPorData(DateTime data) async {
    final db = await _gerenciadorDb.bancoDados;
    final dataStr =
        "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";

    // Seleciona refeições da data corrente não deletadas
    final resultadoRefeicoes = await db.query(
      'meals',
      where:
          "DATE(consumed_at) = DATE(?) AND deleted_locally = 0", // Melhorar esse SQL pois se houver muita requisição, pode ser lento. Talvez criar um índice na coluna consumed_at.
      whereArgs: [dataStr],
    );

    final listaRefeicoes = <Refeicao>[];

    for (final linhaMeal in resultadoRefeicoes) {
      final mealId = linhaMeal['id'] as String;

      // Busca os alimentos associados através da tabela pivot
      final queryPivot = '''
        SELECT mf.quantity, f.* 
        FROM meal_foods mf
        JOIN foods f ON mf.food_id = f.id
        WHERE mf.meal_id = ?
      '''; // Melhorar esse SQL pois se houver muita requisição, pode ser lento devido a N+1 query. Talvez criar uma view ou índice na tabela meal_foods.

      final resultadoPivot = await db.rawQuery(queryPivot, [mealId]);

      final alimentosRefeicao = resultadoPivot.map((linha) {
        final alimento = Alimento.deJson(linha);
        final quantidade = (linha['quantity'] as num).toDouble();
        return ItemAlimentoRefeicao(alimento: alimento, quantidade: quantidade);
      }).toList();

      listaRefeicoes.add(Refeicao.deJson(linhaMeal, alimentosRefeicao));
    }

    return listaRefeicoes;
  }

  /// Salva uma refeição e seu pivot de alimentos no SQLite local.
  Future<void> salvarRefeicao(Refeicao refeicao) async {
    final db = await _gerenciadorDb.bancoDados;

    await db.transaction((txn) async {
      // 1. Insere ou substitui a refeição principal
      await txn.insert('meals', {
        'id': refeicao.id,
        'meal_type': refeicao.tipoRefeicao,
        'consumed_at': refeicao.consumidoEm.toIso8601String(),
        'synced_at': refeicao.sincronizadoEm?.toIso8601String(),
        'deleted_locally': refeicao.deletadoLocalmente ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Remove itens pivot antigos
      await txn.delete(
        'meal_foods',
        where: 'meal_id = ?',
        whereArgs: [refeicao.id],
      );

      // 3. Insere os novos itens pivot
      for (final item in refeicao.alimentos) {
        // Garante que o alimento consumido está salvo na tabela de cache local 'foods'
        await txn.insert(
          'foods',
          item.alimento.paraJson(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        await txn.insert('meal_foods', {
          'id': '${refeicao.id}_${item.alimento.id}',
          'meal_id': refeicao.id,
          'food_id': item.alimento.id,
          'quantity': item.quantidade,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Remove uma refeição localmente (soft delete se sincronizada, físico se não).
  Future<void> deletarRefeicao(String id) async {
    final db = await _gerenciadorDb.bancoDados;

    final resultado = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    if (resultado.isEmpty) return;

    final meal = resultado.first;
    final sincronizado = meal['synced_at'] != null;

    if (sincronizado) {
      await db.update(
        'meals',
        {'deleted_locally': 1, 'synced_at': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Busca de alimentos seguindo estratégia Cache-First.
  Future<List<Alimento>> buscarAlimentos(String termo) async {
    if (termo.isEmpty) return [];

    // 1. Busca no SQLite local
    final db = await _gerenciadorDb.bancoDados;
    final resultadoLocal = await db.query(
      'foods',
      where: "name LIKE ?",
      whereArgs: ['%$termo%'],
      limit: 15,
    );

    if (resultadoLocal.isNotEmpty) {
      return resultadoLocal.map((e) => Alimento.deJson(e)).toList();
    }

    // 2. Se não encontrar nada localmente, busca na API
    try {
      final resposta = await _clienteApi.dio.get(
        '/foods/search',
        queryParameters: {'q': termo},
      );
      final listaDados = resposta.data['data'] as List;
      final alimentosApi = listaDados
          .map((e) => Alimento.deJson(e as Map<String, dynamic>))
          .toList();

      // Salva os resultados no banco de dados local para buscas futuras rápidas (Cache-First)
      await db.transaction((txn) async {
        for (final al in alimentosApi) {
          await txn.insert(
            'foods',
            al.paraJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return alimentosApi;
    } catch (e) {
      // Se der erro de rede, retorna vazio
      return [];
    }
  }

  /// Obtém o detalhe completo de um alimento por ID (Cache-First).
  Future<Alimento?> obterAlimentoPorId(String id) async {
    final db = await _gerenciadorDb.bancoDados;
    final resultado = await db.query('foods', where: 'id = ?', whereArgs: [id]);

    if (resultado.isNotEmpty) {
      return Alimento.deJson(resultado.first);
    }

    // Busca remota e persiste
    try {
      final resposta = await _clienteApi.dio.get('/foods/$id');
      final alimento = Alimento.deJson(resposta.data['data']);
      await db.insert(
        'foods',
        alimento.paraJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return alimento;
    } catch (e) {
      return null;
    }
  }

  /// Salva um alimento personalizado diretamente na tabela local de cache.
  Future<void> cadastrarAlimentoPersonalizado(Alimento alimento) async {
    final db = await _gerenciadorDb.bancoDados;
    await db.insert(
      'foods',
      alimento.paraJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
