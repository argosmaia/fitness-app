import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_autenticacao.dart';

/// Tela de cadastro de novas contas e metas biométricas (Onboarding).
class PaginaRegistro extends ConsumerStatefulWidget {
  const PaginaRegistro({super.key});

  @override
  ConsumerState<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends ConsumerState<PaginaRegistro> {
  final _chaveForm = GlobalKey<FormState>();

  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorAltura = TextEditingController(text: '175');
  final _controladorPeso = TextEditingController(text: '80');
  final _controladorPesoMeta = TextEditingController(text: '75');
  final _controladorAgua = TextEditingController(text: '2500');
  final _controladorKcal = TextEditingController(text: '2200');

  DateTime _dataNascimento = DateTime(1995, 4, 20);
  String _genero = 'male';

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorAltura.dispose();
    _controladorPeso.dispose();
    _controladorPesoMeta.dispose();
    _controladorAgua.dispose();
    _controladorKcal.dispose();
    super.dispose();
  }

  void _selecionarData(BuildContext context) async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TemaApp.corPrincipal,
              surface: TemaApp.corCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (dataSelecionada != null) {
      setState(() {
        _dataNascimento = dataSelecionada;
      });
    }
  }

  void _tentarRegistrar() async {
    if (_chaveForm.currentState?.validate() ?? false) {
      final dataStr =
          "${_dataNascimento.year}-${_dataNascimento.month.toString().padLeft(2, '0')}-${_dataNascimento.day.toString().padLeft(2, '0')}";

      await ref
          .read(provedorAutenticacao.notifier)
          .registrar(
            nome: _controladorNome.text.trim(),
            email: _controladorEmail.text.trim(),
            senha: _controladorSenha.text.trim(),
            dataNascimento: dataStr,
            genero: _genero,
            altura: double.tryParse(_controladorAltura.text) ?? 175.0,
            pesoAtual: double.tryParse(_controladorPeso.text) ?? 80.0,
            pesoMeta: double.tryParse(_controladorPesoMeta.text) ?? 75.0,
            metaAgua: int.tryParse(_controladorAgua.text) ?? 2500,
            metaKcal: int.tryParse(_controladorKcal.text) ?? 2200,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(provedorAutenticacao);

    // Redireciona se cadastrado com sucesso
    if (estado is EstadoAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _chaveForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crie sua conta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Precisamos de alguns dados seus para calibrar seus objetivos diários.',
                  style: TextStyle(color: TemaApp.corTextoSecundario),
                ),
                const SizedBox(height: 24),

                // Nome Completo
                TextFormField(
                  controller: _controladorNome,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: _decoracaoCampo(
                    'Nome Completo',
                    Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Insira seu nome' : null,
                ),
                const SizedBox(height: 16),

                // E-mail
                TextFormField(
                  controller: _controladorEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: _decoracaoCampo('E-mail', Icons.email_outlined),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Insira um e-mail válido'
                      : null,
                ),
                const SizedBox(height: 16),

                // Senha
                TextFormField(
                  controller: _controladorSenha,
                  obscureText: true,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: _decoracaoCampo('Senha', Icons.lock_outlined),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 24),

                // Seção Biométrica
                const Text(
                  'Informações Corporais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.corPrincipal,
                  ),
                ),
                const Divider(color: TemaApp.corCardBorda),
                const SizedBox(height: 12),

                // Data de Nascimento & Gênero
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selecionarData(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: TemaApp.corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TemaApp.corCardBorda),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nascimento',
                                style: TextStyle(
                                  color: TemaApp.corTextoSecundario,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dataNascimento.day.toString().padLeft(2, '0')}/${_dataNascimento.month.toString().padLeft(2, '0')}/${_dataNascimento.year}',
                                style: const TextStyle(
                                  color: TemaApp.corTextoPrincipal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TemaApp.corCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TemaApp.corCardBorda),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _genero,
                          dropdownColor: TemaApp.corCard,
                          decoration: const InputDecoration(
                            labelText: 'Gênero',
                            labelStyle: TextStyle(
                              color: TemaApp.corTextoSecundario,
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Feminino'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Outro'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _genero = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Altura & Peso
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controladorAltura,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: TemaApp.corTextoPrincipal,
                        ),
                        decoration: _decoracaoCampo(
                          'Altura (cm)',
                          Icons.height,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obrigatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _controladorPeso,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: TemaApp.corTextoPrincipal,
                        ),
                        decoration: _decoracaoCampo(
                          'Peso (kg)',
                          Icons.monitor_weight_outlined,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obrigatorio' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Peso Meta
                TextFormField(
                  controller: _controladorPesoMeta,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: _decoracaoCampo(
                    'Meta de Peso (kg)',
                    Icons.flag_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Obrigatorio' : null,
                ),
                const SizedBox(height: 24),

                // Metas Diárias
                const Text(
                  'Metas Diárias',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.corPrincipal,
                  ),
                ),
                const Divider(color: TemaApp.corCardBorda),
                const SizedBox(height: 12),

                // Meta Água & Meta Calorias
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controladorAgua,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: TemaApp.corTextoPrincipal,
                        ),
                        decoration: _decoracaoCampo(
                          'Água (ml)',
                          Icons.local_drink,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obrigatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _controladorKcal,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: TemaApp.corTextoPrincipal,
                        ),
                        decoration: _decoracaoCampo(
                          'Calorias (kcal)',
                          Icons.local_fire_department,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obrigatorio' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (estado is EstadoNaoAutenticado && estado.erro != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Erro: ${estado.erro}',
                      style: const TextStyle(
                        color: TemaApp.corAlerta,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (estado is EstadoCarregando)
                  const Center(
                    child: CircularProgressIndicator(
                      color: TemaApp.corPrincipal,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _tentarRegistrar,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: TemaApp.gradienteSaude,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: TemaApp.sombrasPremium,
                      ),
                      child: Center(
                        child: Text(
                          'Concluir Cadastro',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 16,
                                color: TemaApp.corFundo,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: TemaApp.corTextoSecundario),
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
    );
  }
}
