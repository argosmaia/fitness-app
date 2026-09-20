import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Classe singleton responsável por gerenciar a conexão e ciclo de vida do SQLite local.
class GerenciadorBancoDados {
  static final GerenciadorBancoDados instancia =
      GerenciadorBancoDados._interno();
  static Database? _bancoDados;

  GerenciadorBancoDados._interno();

  /// O Android/iOS usa o driver nativo do sqflite. Linux e demais desktops
  /// usam sqlite3 por FFI, mantendo exatamente o mesmo schema offline-first.
  static void configurarPlataforma() {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get bancoDados async {
    if (_bancoDados != null) return _bancoDados!;
    _bancoDados = await _inicializarBanco();
    return _bancoDados!;
  }

  Future<Database> _inicializarBanco() async {
    final caminhoBanco = await getDatabasesPath();
    final caminhoCompleto = join(caminhoBanco, 'fitness_app_local.db');

    return await openDatabase(
      caminhoCompleto,
      version: 2,
      onCreate: _criarTabelas,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _criarTabelaSincronizacao(db);
      },
      onConfigure: (db) async {
        // Habilita chaves estrangeiras para deleções em cascata
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _criarTabelas(Database db, int versao) async {
    // Tabela de Alimentos (Cache TACO)
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbohydrates REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        serving_size TEXT NOT NULL
      )
    ''');

    // Tabela de Treinos
    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        duration_seconds INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        synced_at TEXT,
        deleted_locally INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de Exercícios
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER,
        weight REAL,
        rest_seconds INTEGER,
        notes TEXT,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Refeições
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        meal_type TEXT NOT NULL,
        consumed_at TEXT NOT NULL,
        synced_at TEXT,
        deleted_locally INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabela Pivot de Alimentos nas Refeições
    await db.execute('''
      CREATE TABLE meal_foods (
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        food_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Sono
    await db.execute('''
      CREATE TABLE sleep_logs (
        id TEXT PRIMARY KEY,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        quality INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        synced_at TEXT,
        deleted_locally INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de Hidratação
    await db.execute('''
      CREATE TABLE water_logs (
        id TEXT PRIMARY KEY,
        amount_ml INTEGER NOT NULL,
        logged_at TEXT NOT NULL,
        synced_at TEXT,
        deleted_locally INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _criarTabelaSincronizacao(db);
  }

  Future<void> _criarTabelaSincronizacao(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS sync_metadata (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

  /// Limpa todas as tabelas do banco de dados (útil para logout do usuário)
  Future<void> limparTudo() async {
    final db = await bancoDados;
    await db.delete('meal_foods');
    await db.delete('meals');
    await db.delete('exercises');
    await db.delete('workouts');
    await db.delete('sleep_logs');
    await db.delete('water_logs');
    await db.delete('foods');
  }
}
