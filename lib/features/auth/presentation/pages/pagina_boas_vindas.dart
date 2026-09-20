import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tema_app.dart';
import '../providers/provedor_autenticacao.dart';

/// Tela inicial de boas-vindas do aplicativo.
class PaginaBoasVindas extends ConsumerWidget {
  const PaginaBoasVindas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(provedorAutenticacao);

    // Se autenticado, redireciona ao Dashboard imediatamente após renderizar
    if (estado is EstadoAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: TemaApp.corFundo),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),

                // Logo e Título com Gradiente
                Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (limites) =>
                          TemaApp.gradienteSaude.createShader(limites),
                      child: const Icon(
                        Icons.fitbit_rounded,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FITNESS APP',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontFamily: 'Outfit', letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu corpo, sua mente. Tudo em um só lugar.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TemaApp.corTextoSecundario,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Ações de Autenticação
                Column(
                  children: [
                    if (estado is EstadoCarregando)
                      const CircularProgressIndicator(
                        color: TemaApp.corPrincipal,
                      )
                    else ...[
                      // Botão Google SSO
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(provedorAutenticacao.notifier)
                              .logarComGoogle();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: TemaApp.corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TemaApp.corCardBorda),
                            boxShadow: TemaApp.sombrasPremium,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Entrar com o Google',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão Email/Senha (Login)
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: TemaApp.gradienteSaude,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: TemaApp.sombrasPremium,
                          ),
                          child: Center(
                            child: Text(
                              'Entrar com E-mail',
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
                      const SizedBox(height: 16),

                      // Botão Cadastrar-se
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Não tem conta? ',
                            style: TextStyle(color: TemaApp.corTextoSecundario),
                            children: [
                              TextSpan(
                                text: 'Cadastre-se',
                                style: TextStyle(
                                  color: TemaApp.corPrincipal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
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
