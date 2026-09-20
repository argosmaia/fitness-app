import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
final httpClientProvider = Provider<HttpClient>(
  (ref) => DioApiClient(ref.watch(tokenStoreProvider)),
);
