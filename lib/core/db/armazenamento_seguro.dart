import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Classe responsável por gerenciar a persistência segura do token de acesso localmente.
class ArmazenamentoSeguro {
  static final ArmazenamentoSeguro instancia = ArmazenamentoSeguro._interno();
  final _armazenamento = const FlutterSecureStorage();

  ArmazenamentoSeguro._interno();

  /// Grava o token JWT de forma segura no dispositivo.
  Future<void> salvarToken(String token) async {
    await _armazenamento.write(key: 'token_bearer', value: token);
  }

  /// Recupera o token JWT gravado. Retorna nulo se não existir.
  Future<String?> obterToken() async {
    return await _armazenamento.read(key: 'token_bearer');
  }

  /// Remove o token JWT gravado (útil no logout).
  Future<void> limparToken() async {
    await _armazenamento.delete(key: 'token_bearer');
  }
}
