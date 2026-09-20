import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/gerenciador_banco_dados.dart';
import '../providers/core_providers.dart';
import 'sync_coordinator.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = ApiSyncCoordinator(
    ref.watch(httpClientProvider),
    GerenciadorBancoDados.instancia,
  );
  ref.onDispose(engine.dispose);
  return engine;
});
