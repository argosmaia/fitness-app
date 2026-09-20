import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_autenticacao.dart';

/// Tela para autenticação manual com e-mail e senha.
class PaginaLogin extends ConsumerStatefulWidget {
  const PaginaLogin({super.key});

  @override
  ConsumerState<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends ConsumerState<PaginaLogin> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  void _tentarLogin() async {
    if (_chaveFormulario.currentState?.validate() ?? false) {
      await ref
          .read(provedorAutenticacao.notifier)
          .logar(_controladorEmail.text.trim(), _controladorSenha.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(provedorAutenticacao);

    // Se autenticado com sucesso, navega para o Dashboard
    if (estado is EstadoAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _chaveFormulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Bem-vindo de volta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Insira suas credenciais abaixo para acessar seus treinos e dieta.',
                  style: TextStyle(color: TemaApp.corTextoSecundario),
                ),
                const SizedBox(height: 32),

                // Campo de E-mail
                TextFormField(
                  controller: _controladorEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: TemaApp.corTextoSecundario,
                    ),
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
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Por favor, insira seu e-mail';
                    }
                    if (!valor.contains('@')) {
                      return 'Insira um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo de Senha
                TextFormField(
                  controller: _controladorSenha,
                  obscureText: true,
                  style: const TextStyle(color: TemaApp.corTextoPrincipal),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: TemaApp.corTextoSecundario,
                    ),
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
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (valor.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Mensagem de Erro, se houver
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
                  const SizedBox(height: 8),
                ],

                const Spacer(),

                // Botão de Login
                if (estado is EstadoCarregando)
                  const Center(
                    child: CircularProgressIndicator(
                      color: TemaApp.corPrincipal,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _tentarLogin,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: TemaApp.gradienteSaude,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: TemaApp.sombrasPremium,
                      ),
                      child: Center(
                        child: Text(
                          'Entrar',
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
}
