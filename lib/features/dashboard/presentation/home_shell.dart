import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_providers.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/presentation/resource_page.dart';
import 'overview_page.dart';

final class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.user});
  final UserProfile? user;
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

final class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _synchronize());
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _synchronize(),
    );
  }

  void _synchronize() => ref.read(syncEngineProvider).synchronize();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _synchronize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OverviewPage(user: widget.user),
      const ResourcePage(
        title: 'Treinos',
        endpoint: ApiEndpoints.workouts,
        icon: Icons.fitness_center,
        emptyText: 'Seu próximo treino começa aqui.',
      ),
      const ResourcePage(
        title: 'Alimentação',
        endpoint: ApiEndpoints.meals,
        icon: Icons.restaurant_outlined,
        emptyText: 'Registre sua primeira refeição.',
      ),
      const ResourcePage(
        title: 'Bem-estar',
        endpoint: ApiEndpoints.waterLogs,
        icon: Icons.water_drop_outlined,
        emptyText: 'Registre sua hidratação de hoje.',
        allowWaterEntry: true,
      ),
      _ProfilePage(user: widget.user),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Treinos',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            label: 'Dieta',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            label: 'Bem-estar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

final class _ProfilePage extends ConsumerWidget {
  const _ProfilePage({required this.user});
  final UserProfile? user;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncEngine = ref.watch(syncEngineProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              (user?.name.isNotEmpty == true ? user!.name[0] : 'U')
                  .toUpperCase(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Usuário',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user?.email ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: const Text('Peso atual'),
                  trailing: Text(
                    user?.weight == null ? '—' : '${user!.weight} kg',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('Meta de água'),
                  trailing: Text(
                    user?.dailyWaterGoal == null
                        ? '—'
                        : '${user!.dailyWaterGoal} ml',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: const Text('Meta calórica'),
                  trailing: Text(
                    user?.dailyKcalGoal == null
                        ? '—'
                        : '${user!.dailyKcalGoal} kcal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<SyncSnapshot>(
            stream: syncEngine.changes,
            initialData: syncEngine.current,
            builder: (context, snapshot) {
              final sync = snapshot.data!;
              return Card(
                child: ListTile(
                  leading: Icon(
                    sync.status == SyncStatus.syncing
                        ? Icons.sync
                        : Icons.cloud_done_outlined,
                  ),
                  title: Text(
                    sync.status == SyncStatus.syncing
                        ? 'Sincronizando…'
                        : 'Sincronização entre dispositivos',
                  ),
                  subtitle: Text(
                    sync.lastSuccess == null
                        ? 'Ainda não sincronizado'
                        : 'Última sincronização: ${sync.lastSuccess}',
                  ),
                  trailing: IconButton(
                    onPressed: sync.status == SyncStatus.syncing
                        ? null
                        : syncEngine.synchronize,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
