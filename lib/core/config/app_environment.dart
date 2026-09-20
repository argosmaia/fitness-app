enum AppEnvironment { development, staging, production }

abstract final class AppConfig {
  static const environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
  static AppEnvironment get environment => AppEnvironment.values.firstWhere(
    (value) => value.name == environmentName,
    orElse: () => AppEnvironment.development,
  );
  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority)
      throw StateError('API_BASE_URL inválida.');
    if (environment == AppEnvironment.production && uri.scheme != 'https') {
      throw StateError('A API deve usar HTTPS em produção.');
    }
  }
}
