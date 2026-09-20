import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(httpClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

final class AuthController extends AsyncNotifier<AuthSession?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  @override
  Future<AuthSession?> build() => _repository.restore();
  Future<void> login(LoginCommand command) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.login(command));
  }

  Future<void> register(RegisterCommand command) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.register(command));
  }

  Future<void> sendEmailVerification() => _repository.sendEmailVerification();

  Future<bool> confirmEmailVerification(String code) async {
    final result = await AsyncValue.guard(
      () => _repository.confirmEmailVerification(code),
    );
    state = result;
    return !result.hasError;
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _repository.logout();
    state = const AsyncData(null);
  }
}
