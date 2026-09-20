/// Exceção base do sistema para controle de falhas de comunicação e regras de negócio.
abstract class ExcecaoApp implements Exception {
  final String mensagem;
  ExcecaoApp(this.mensagem);

  @override
  String toString() => mensagem;
}

class ExcecaoServidor extends ExcecaoApp {
  ExcecaoServidor([
    super.mensagem = 'Erro interno do servidor. Tente novamente mais tarde.',
  ]);
}

class ExcecaoAutenticacao extends ExcecaoApp {
  ExcecaoAutenticacao([
    super.mensagem = 'Sessão expirada ou inválida. Faça login novamente.',
  ]);
}

class ExcecaoSemRede extends ExcecaoApp {
  ExcecaoSemRede([
    super.mensagem = 'Sem conexão com a internet. Trabalhando no modo offline.',
  ]);
}

class ExcecaoNaoEncontrado extends ExcecaoApp {
  ExcecaoNaoEncontrado([
    super.mensagem = 'Recurso não encontrado no servidor.',
  ]);
}

class ExcecaoLimiteRequisicoes extends ExcecaoApp {
  ExcecaoLimiteRequisicoes([
    super.mensagem =
        'Limite de requisições excedido. Aguarde alguns instantes.',
  ]);
}

class ExcecaoValidacao extends ExcecaoApp {
  final Map<String, dynamic>? erros;
  ExcecaoValidacao({required String mensagem, this.erros}) : super(mensagem);
}
