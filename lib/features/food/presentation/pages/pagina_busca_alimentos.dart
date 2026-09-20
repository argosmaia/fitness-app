import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_alimentacao.dart';

/// Tela para busca de alimentos na base TACO (Offline-First cacheada) ou remoto.
class PaginaBuscaAlimentos extends ConsumerStatefulWidget {
  final String tipoRefeicao;
  final String? mealId;

  const PaginaBuscaAlimentos({
    super.key,
    required this.tipoRefeicao,
    this.mealId,
  });

  @override
  ConsumerState<PaginaBuscaAlimentos> createState() =>
      _PaginaBuscaAlimentosState();
}

class _PaginaBuscaAlimentosState extends ConsumerState<PaginaBuscaAlimentos> {
  final _controladorBusca = TextEditingController();
  Timer? _debounce;

  void _onBuscaAlterada(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(provedorBuscaAlimentos.notifier).pesquisar(query);
    });
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoBusca = ref.watch(provedorBuscaAlimentos);

    return Scaffold(
      appBar: AppBar(title: Text('Buscar para ${widget.tipoRefeicao}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Campo de Busca
              TextFormField(
                controller: _controladorBusca,
                style: const TextStyle(color: TemaApp.corTextoPrincipal),
                decoration: InputDecoration(
                  hintText: 'Digite o nome do alimento...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: TemaApp.corTextoSecundario,
                  ),
                  suffixIcon: _controladorBusca.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controladorBusca.clear();
                            ref
                                .read(provedorBuscaAlimentos.notifier)
                                .pesquisar('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: TemaApp.corCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TemaApp.corCardBorda),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TemaApp.corCardBorda),
                  ),
                ),
                onChanged: _onBuscaAlterada,
              ),
              const SizedBox(height: 20),

              // Botão Cadastrar Alimento Customizado
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/food/custom?meal_type=${widget.tipoRefeicao}&meal_id=${widget.mealId}',
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Alimento Personalizado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TemaApp.corPrincipal,
                  side: const BorderSide(color: TemaApp.corCardBorda),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resultados
              Expanded(
                child: estadoBusca.buscando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: TemaApp.corPrincipal,
                        ),
                      )
                    : estadoBusca.resultados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              size: 64,
                              color: TemaApp.corTextoInativo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _controladorBusca.text.isEmpty
                                  ? 'Pesquise acima para encontrar alimentos da tabela TACO.'
                                  : 'Nenhum alimento correspondente encontrado.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: TemaApp.corTextoSecundario,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: estadoBusca.resultados.length,
                        itemBuilder: (context, idx) {
                          final alimento = estadoBusca.resultados[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                alimento.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${alimento.calorias.round()} kcal por ${alimento.tamanhoPorcao}',
                                style: TextStyle(
                                  color: TemaApp.corTextoSecundario,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: TemaApp.corPrincipal,
                              ),
                              onTap: () {
                                context.push(
                                  '/food/detail?id=${alimento.id}&meal_type=${widget.tipoRefeicao}&meal_id=${widget.mealId}',
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
