import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

final class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._tokens);
  final HttpClient _client;
  final TokenStore _tokens;
  @override
  Future<AuthSession> login(LoginCommand command) =>
      _authenticate(ApiEndpoints.login, command.toJson());
  @override
  Future<AuthSession> register(RegisterCommand command) =>
      _authenticate(ApiEndpoints.register, command.toJson());
  Future<AuthSession> _authenticate(String path, JsonMap body) async {
    final response = await _client.post<JsonMap>(
      path,
      body: body,
      decode: _map,
    );
    final token = response.data['token']?.toString();
    if (token == null || token.isEmpty)
      throw StateError('A API não retornou um token.');
    await _tokens.write(token);
    final user = response.data['user'];
    return AuthSession(
      user is Map
          ? UserProfile.fromJson(Map<String, dynamic>.from(user))
          : null,
    );
  }

  @override
  Future<AuthSession?> restore() async {
    if (await _tokens.read() == null) return null;
    try {
      final response = await _client.get<JsonMap>(
        ApiEndpoints.profile,
        decode: _map,
      );
      return AuthSession(UserProfile.fromJson(response.data));
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post<Object?>(
        ApiEndpoints.logout,
        decode: (value) => value,
      );
    } finally {
      await _tokens.clear();
    }
  }

  static JsonMap _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
