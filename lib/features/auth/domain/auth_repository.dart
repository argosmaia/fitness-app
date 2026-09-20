import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login(LoginCommand command);
  Future<AuthSession> register(RegisterCommand command);
  Future<AuthSession?> restore();
  Future<void> logout();
}
