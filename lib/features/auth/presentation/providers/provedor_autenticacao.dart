import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/cliente_api.dart';
import '../../data/repositories/repositorio_autenticacao.dart';
import '../../domain/entities/usuario.dart';
import '../../../../core/db/armazenamento_seguro.dart';

/// Representação dos estados possíveis de autenticação.
abstract class EstadoAutenticacao {
  const EstadoAutenticacao();
}

class EstadoInicial extends EstadoAutenticacao {
  const EstadoInicial();
}

class EstadoCarregando extends EstadoAutenticacao {
  const EstadoCarregando();
}

class EstadoAutenticado extends EstadoAutenticacao {
  final Usuario usuario;
  const EstadoAutenticado(this.usuario);
}

class EstadoNaoAutenticado extends EstadoAutenticacao {
  final String? erro;
  const EstadoNaoAutenticado({this.erro});
}

/// Notificador que controla o fluxo de login, cadastro, logout e SSO.
class NotificadorAutenticacao extends StateNotifier<EstadoAutenticacao> {
  final RepositorioAutenticacao _repositorio;

  NotificadorAutenticacao(this._repositorio) : super(const EstadoInicial()) {
    verificarSessao();
  }

  /// Verifica se o usuário já possui um token salvo localmente ao abrir o app.
  Future<void> verificarSessao() async {
    final token = await ArmazenamentoSeguro.instancia.obterToken();
    if (token == null) {
      state = const EstadoNaoAutenticado();
      return;
    }

    state = const EstadoCarregando();
    try {
      final perfil = await _repositorio.obterPerfil();
      state = EstadoAutenticado(perfil);
    } catch (e) {
      state = const EstadoNaoAutenticado();
    }
  }

  /// Efetua login por e-mail e senha.
  Future<void> logar(String email, String senha) async {
    state = const EstadoCarregando();
    try {
      final usuario = await _repositorio.login(email, senha);
      state = EstadoAutenticado(usuario);
    } catch (e) {
      state = EstadoNaoAutenticado(erro: e.toString());
    }
  }

  /// Efetua cadastro de nova conta.
  Future<void> registrar({
    required String nome,
    required String email,
    required String senha,
    required String dataNascimento,
    required String genero,
    required double altura,
    required double pesoAtual,
    required double pesoMeta,
    required int metaAgua,
    required int metaKcal,
  }) async {
    state = const EstadoCarregando();
    try {
      final usuario = await _repositorio.registrar(
        nome: nome,
        email: email,
        senha: senha,
        dataNascimento: dataNascimento,
        genero: genero,
        altura: altura,
        pesoCurrent: pesoAtual,
        pesoMeta: pesoMeta,
        metaAgua: metaAgua,
        metaKcal: metaKcal,
      );
      state = EstadoAutenticado(usuario);
    } catch (e) {
      state = EstadoNaoAutenticado(erro: e.toString());
    }
  }

  /// Efetua login com o Google.
  Future<void> logarComGoogle() async {
    state = const EstadoCarregando();
    try {
      final usuario = await _repositorio.logarComGoogle();
      state = EstadoAutenticado(usuario);
    } catch (e) {
      state = EstadoNaoAutenticado(erro: e.toString());
    }
  }

  /// Efetua logout limpando os dados seguros.
  Future<void> deslogar() async {
    state = const EstadoCarregando();
    await _repositorio.logout();
    state = const EstadoNaoAutenticado();
  }

  /// Atualiza os dados de perfil em memória e propaga ao servidor.
  Future<void> atualizarDadosUsuario(Usuario usuarioAtualizado) async {
    if (state is EstadoAutenticado) {
      try {
        final perfilSalvo = await _repositorio.atualizarPerfil(
          usuarioAtualizado,
        );
        state = EstadoAutenticado(perfilSalvo);
      } catch (e) {
        // Se falhar no servidor, mantém o estado anterior mas printa erro
        print('Erro ao atualizar perfil no servidor: $e');
      }
    }
  }
}

// Provedores Riverpod expostos para o resto do app
final provedorClienteApi = Provider<ClienteApi>((ref) => ClienteApi());

final provedorRepositorioAuth = Provider<RepositorioAutenticacao>((ref) {
  final clienteApi = ref.watch(provedorClienteApi);
  return RepositorioAutenticacao(clienteApi);
});

final provedorAutenticacao =
    StateNotifierProvider<NotificadorAutenticacao, EstadoAutenticacao>((ref) {
      final repositorio = ref.watch(provedorRepositorioAuth);
      return NotificadorAutenticacao(repositorio);
    });
