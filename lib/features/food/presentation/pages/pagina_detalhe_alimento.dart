import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_alimentacao.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/refeicao.dart';

/// Tela de exibição dos detalhes nutricionais do alimento com entrada de gramas dinâmica.
class PaginaDetalheAlimento extends ConsumerStatefulWidget {
  final String idAlimento;
  final String tipoRefeicao;
  final String? mealId;

  const PaginaDetalheAlimento({
    super.key,
    required this.idAlimento,
    required this.tipoRefeicao,
    this.mealId,
  });

  @override
  ConsumerState<PaginaDetalheAlimento> createState() =>
      _PaginaDetalheAlimentoState();
}

class _PaginaDetalheAlimentoState extends ConsumerState<PaginaDetalheAlimento> {
  double _quantidadeGrams = 100.0;
  Alimento? _alimento;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDetalhe();
  }

  void _carregarDetalhe() async {
    final repo = ref.read(provedorRepositorioAlimentacao);
    final resultado = await repo.obterAlimentoPorId(widget.idAlimento);
    setState(() {
      _alimento = resultado;
      _carregando = false;
    });
  }

  void _adicionarAoDiario() async {
    if (_alimento == null) return;

    final diarioNotifier = ref.read(provedorDiarioAlimentacao.notifier);
    final diarioEstado = ref.read(provedorDiarioAlimentacao);

    // Se já existe uma refeição desse tipo hoje, adiciona nela. Senão, cria uma nova.
    Refeicao? refeicaoExistente;
    if (widget.mealId != null && widget.mealId!.isNotEmpty) {
      refeicaoExistente = diarioEstado.refeicoes.firstWhere(
        (m) => m.id == widget.mealId,
        orElse: () => null as dynamic,
      );
    } else {
      // Procura se tem alguma criada na data de hoje
      final correspondentes = diarioEstado.obterPorTipo(widget.tipoRefeicao);
      if (correspondentes.isNotEmpty) {
        refeicaoExistente = correspondentes.first;
      }
    }

    final novoItem = ItemAlimentoRefeicao(
      alimento: _alimento!,
      quantidade: _quantidadeGrams,
    );

    final List<ItemAlimentoRefeicao> alimentosAtualizados;
    final String idRefeicao;

    if (refeicaoExistente != null) {
      idRefeicao = refeicaoExistente.id;
      alimentosAtualizados = List<ItemAlimentoRefeicao>.from(
        refeicaoExistente.alimentos,
      )..add(novoItem);
    } else {
      idRefeicao = const Uuid().v4();
      alimentosAtualizados = [novoItem];
    }

    final novaRefeicao = Refeicao(
      id: idRefeicao,
      tipoRefeicao: widget.tipoRefeicao,
      consumidoEm:
          diarioEstado.dataSelecionada, // associa à data ativa no calendário
      alimentos: alimentosAtualizados,
    );

    await diarioNotifier.salvarRefeicao(novaRefeicao);

    // Retorna ao diário principal fechando a busca
    context.go('/food');
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(
          child: CircularProgressIndicator(color: TemaApp.corPrincipal),
        ),
      );
    }

    if (_alimento == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Alimento não encontrado.')),
      );
    }

    // Cálculos Proporcionais Dinâmicos
    final caloriasCalculadas = (_alimento!.calorias * _quantidadeGrams) / 100.0;
    final proteinasCalculadas =
        (_alimento!.proteinas * _quantidadeGrams) / 100.0;
    final carboidratosCalculadas =
        (_alimento!.carboidratos * _quantidadeGrams) / 100.0;
    final lipidiosCalculadas = (_alimento!.lipidios * _quantidadeGrams) / 100.0;
    final fibrasCalculadas = (_alimento!.fibras * _quantidadeGrams) / 100.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes Nutricionais')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome do alimento
              Text(
                _alimento!.nome,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_alimento!.marca != null) ...[
                const SizedBox(height: 4),
                Text(
                  _alimento!.marca!,
                  style: const TextStyle(
                    color: TemaApp.corSecundaria,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Card de Entrada de Quantidade
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'QUANTIDADE CONSUMIDA (g)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: TemaApp.corTextoSecundario,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 28,
                            ),
                            onPressed: () {
                              if (_quantidadeGrams > 10) {
                                setState(() {
                                  _quantidadeGrams -= 10;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: _quantidadeGrams.round().toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                final valor = double.tryParse(val);
                                if (valor != null && valor > 0) {
                                  setState(() {
                                    _quantidadeGrams = valor;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _quantidadeGrams += 10;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Macronutrientes Dinâmicos
              Text(
                'Tabela de Macronutrientes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _linhaMacro(
                'Calorias',
                '${caloriasCalculadas.round()} kcal',
                TemaApp.corPrincipal,
              ),
              const Divider(color: TemaApp.corCardBorda),
              _linhaMacro(
                'Proteínas',
                '${proteinasCalculadas.toStringAsFixed(1)} g',
                TemaApp.corSecundaria,
              ),
              const Divider(color: TemaApp.corCardBorda),
              _linhaMacro(
                'Carboidratos',
                '${carboidratosCalculadas.toStringAsFixed(1)} g',
                TemaApp.corAviso,
              ),
              const Divider(color: TemaApp.corCardBorda),
              _linhaMacro(
                'Gorduras (Lipídios)',
                '${lipidiosCalculadas.toStringAsFixed(1)} g',
                TemaApp.corAlerta,
              ),
              const Divider(color: TemaApp.corCardBorda),
              _linhaMacro(
                'Fibras',
                '${fibrasCalculadas.toStringAsFixed(1)} g',
                Colors.purpleAccent,
              ),

              const SizedBox(height: 40),

              // Botão Adicionar
              GestureDetector(
                onTap: _adicionarAoDiario,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: TemaApp.gradienteSaude,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: TemaApp.sombrasPremium,
                  ),
                  child: Center(
                    child: Text(
                      'Adicionar à Refeição',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: TemaApp.corFundo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaMacro(String nome, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(nome, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
