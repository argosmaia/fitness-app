import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/db/gerenciador_banco_dados.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/sync/sync_providers.dart';

final class ResourcePage extends ConsumerStatefulWidget {
  const ResourcePage({
    super.key,
    required this.title,
    required this.endpoint,
    required this.icon,
    required this.emptyText,
    this.allowWaterEntry = false,
  });
  final String title, endpoint, emptyText;
  final IconData icon;
  final bool allowWaterEntry;
  @override
  ConsumerState<ResourcePage> createState() => _ResourcePageState();
}

final class _ResourcePageState extends ConsumerState<ResourcePage> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await ref
        .read(httpClientProvider)
        .get<Object?>(
          widget.endpoint,
          query: {'per_page': 30},
          decode: (v) => v,
        );
    final data = response.data;
    final raw = data is List
        ? data
        : data is Map
        ? (data['items'] as List? ?? const [])
        : const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _addWater(int amount) async {
    final db = await GerenciadorBancoDados.instancia.bancoDados;
    await db.insert('water_logs', {
      'id': const Uuid().v4(),
      'amount_ml': amount,
      'logged_at': DateTime.now().toUtc().toIso8601String(),
      'synced_at': null,
      'deleted_locally': 0,
    });
    await ref.read(syncEngineProvider).synchronize();
    if (!mounted) return;
    setState(() => _items = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: () => setState(() => _items = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _Message(
            icon: Icons.cloud_off_outlined,
            text: 'Não foi possível carregar.\n${snapshot.error}',
            action: () => setState(() => _items = _load()),
          );
        final items = snapshot.data ?? const [];
        return Column(
          children: [
            if (widget.allowWaterEntry)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    for (final amount in [250, 350, 500])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilledButton.tonal(
                            onPressed: () => _addWater(amount),
                            child: Text('+$amount ml'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? _Message(icon: widget.icon, text: widget.emptyText)
                  : RefreshIndicator(
                      onRefresh: () async => setState(() => _items = _load()),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Icon(widget.icon)),
                              title: Text(_title(item)),
                              subtitle: Text(_subtitle(item)),
                              trailing: item['synced_at'] == null
                                  ? const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 18,
                                    )
                                  : const Icon(
                                      Icons.cloud_done_outlined,
                                      size: 18,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
  String _title(Map<String, dynamic> item) =>
      (item['name'] ??
              item['meal_type'] ??
              (item['amount_ml'] == null
                  ? 'Registro'
                  : '${item['amount_ml']} ml'))
          .toString();
  String _subtitle(Map<String, dynamic> item) =>
      (item['started_at'] ?? item['consumed_at'] ?? item['logged_at'] ?? '')
          .toString();
}

final class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center),
          if (action != null)
            TextButton(
              onPressed: action,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    ),
  );
}
