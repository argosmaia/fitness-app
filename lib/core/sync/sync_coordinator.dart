import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../db/gerenciador_banco_dados.dart';

enum SyncStatus { idle, syncing, success, offline, failed }

final class SyncSnapshot {
  const SyncSnapshot(this.status, {this.lastSuccess, this.message});
  final SyncStatus status;
  final DateTime? lastSuccess;
  final String? message;
}

abstract interface class SyncEngine {
  Stream<SyncSnapshot> get changes;
  SyncSnapshot get current;
  Future<void> synchronize();
  void dispose();
}

/// Sincroniza cada instalação local (Android/Linux) através da API Laravel.
/// UUIDs tornam reenvios idempotentes e o lock evita duas sincronizações ao
/// mesmo tempo quando timer, retomada da janela e ação manual coincidirem.
final class ApiSyncCoordinator implements SyncEngine {
  ApiSyncCoordinator(this._client, this._database);

  final HttpClient _client;
  final GerenciadorBancoDados _database;
  final _controller = StreamController<SyncSnapshot>.broadcast();
  SyncSnapshot _current = const SyncSnapshot(SyncStatus.idle);
  Future<void>? _running;

  @override
  Stream<SyncSnapshot> get changes => _controller.stream;
  @override
  SyncSnapshot get current => _current;

  @override
  Future<void> synchronize() =>
      _running ??= _execute().whenComplete(() => _running = null);

  Future<void> _execute() async {
    _emit(SyncSnapshot(SyncStatus.syncing, lastSuccess: _current.lastSuccess));
    try {
      final db = await _database.bancoDados;
      final payload = await _pendingPayload(db);
      if (_hasPending(payload)) {
        final response = await _client.post<Map<String, dynamic>>(
          ApiEndpoints.sync,
          body: payload,
          decode: (value) => value is Map
              ? Map<String, dynamic>.from(value)
              : <String, dynamic>{},
        );
        await _markProcessed(db, response.data);
      }
      await _pullRemote(db);
      final now = DateTime.now();
      await db.insert('sync_metadata', {
        'key': 'last_success',
        'value': now.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _emit(SyncSnapshot(SyncStatus.success, lastSuccess: now));
    } catch (error) {
      _emit(
        SyncSnapshot(
          SyncStatus.failed,
          lastSuccess: _current.lastSuccess,
          message: error.toString(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _pendingPayload(Database db) async {
    final workouts = await db.query('workouts', where: 'synced_at IS NULL');
    final workoutPayload = <Map<String, dynamic>>[];
    for (final workout in workouts) {
      final item = Map<String, dynamic>.from(workout)..remove('synced_at');
      item['exercises'] = await db.query(
        'exercises',
        where: 'workout_id = ?',
        whereArgs: [workout['id']],
      );
      workoutPayload.add(item);
    }
    final meals = await db.query('meals', where: 'synced_at IS NULL');
    final mealPayload = <Map<String, dynamic>>[];
    for (final meal in meals) {
      final item = Map<String, dynamic>.from(meal)..remove('synced_at');
      item['foods'] = await db.query(
        'meal_foods',
        columns: ['food_id', 'quantity'],
        where: 'meal_id = ?',
        whereArgs: [meal['id']],
      );
      mealPayload.add(item);
    }
    return {
      'workouts': workoutPayload,
      'meals': mealPayload,
      'sleep_logs': await db.query('sleep_logs', where: 'synced_at IS NULL'),
      'water_logs': await db.query('water_logs', where: 'synced_at IS NULL'),
    };
  }

  bool _hasPending(Map<String, dynamic> payload) =>
      payload.values.whereType<List>().any((items) => items.isNotEmpty);

  Future<void> _markProcessed(Database db, Map<String, dynamic> result) async {
    const tables = {
      'workouts': 'workouts',
      'meals': 'meals',
      'sleep_logs': 'sleep_logs',
      'water_logs': 'water_logs',
    };
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction((transaction) async {
      for (final entry in tables.entries) {
        final ids = result[entry.key];
        if (ids is! List) continue;
        for (final id in ids) {
          final rows = await transaction.query(
            entry.value,
            columns: ['deleted_locally'],
            where: 'id = ?',
            whereArgs: [id],
          );
          if (rows.isNotEmpty && rows.first['deleted_locally'] == 1) {
            await transaction.delete(
              entry.value,
              where: 'id = ?',
              whereArgs: [id],
            );
          } else {
            await transaction.update(
              entry.value,
              {'synced_at': syncedAt},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }
    });
  }

  Future<void> _pullRemote(Database db) async {
    await _pullCollection(db, ApiEndpoints.workouts, 'workouts', _workoutRow);
    await _pullCollection(db, ApiEndpoints.meals, 'meals', _mealRow);
    await _pullCollection(db, ApiEndpoints.sleepLogs, 'sleep_logs', _sleepRow);
    await _pullCollection(db, ApiEndpoints.waterLogs, 'water_logs', _waterRow);
  }

  Future<void> _pullCollection(
    Database db,
    String endpoint,
    String table,
    Map<String, dynamic> Function(Map<String, dynamic>) mapper,
  ) async {
    final response = await _client.get<Object?>(
      endpoint,
      query: {'per_page': 100},
      decode: (value) => value,
    );
    final raw = response.data;
    final values = raw is List
        ? raw
        : raw is Map
        ? (raw['items'] as List? ?? const [])
        : const [];
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction((transaction) async {
      for (final value in values.whereType<Map>()) {
        final json = Map<String, dynamic>.from(value);
        final row = mapper(json)
          ..['synced_at'] = syncedAt
          ..['deleted_locally'] = 0;
        await transaction.insert(
          table,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (table == 'workouts') await _replaceExercises(transaction, json);
      }
    });
  }

  Future<void> _replaceExercises(
    Transaction transaction,
    Map<String, dynamic> workout,
  ) async {
    final id = workout['id'];
    final exercises = workout['exercises'];
    if (id == null || exercises is! List) return;
    await transaction.delete(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [id],
    );
    for (final value in exercises.whereType<Map>()) {
      final exercise = Map<String, dynamic>.from(value);
      await transaction.insert('exercises', {
        'id': exercise['id'],
        'workout_id': id,
        'name': exercise['name'],
        'sets': exercise['sets'],
        'reps': exercise['reps'],
        'weight': exercise['weight'],
        'rest_seconds': exercise['rest_seconds'],
        'notes': exercise['notes'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Map<String, dynamic> _workoutRow(Map<String, dynamic> j) => {
    'id': j['id'],
    'name': j['name'],
    'description': j['description'],
    'started_at': j['started_at'],
    'finished_at': j['finished_at'],
    'duration_seconds': j['duration_seconds'] ?? 0,
    'calories': j['calories'] ?? 0,
  };
  Map<String, dynamic> _mealRow(Map<String, dynamic> j) => {
    'id': j['id'],
    'meal_type': j['meal_type'],
    'consumed_at': j['consumed_at'],
  };
  Map<String, dynamic> _sleepRow(Map<String, dynamic> j) => {
    'id': j['id'],
    'started_at': j['started_at'],
    'finished_at': j['finished_at'],
    'quality': j['quality'] ?? 1,
    'duration_minutes': j['duration_minutes'] ?? 0,
  };
  Map<String, dynamic> _waterRow(Map<String, dynamic> j) => {
    'id': j['id'],
    'amount_ml': j['amount_ml'],
    'logged_at': j['logged_at'],
  };

  void _emit(SyncSnapshot value) {
    _current = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  @override
  void dispose() => _controller.close();
}
