import 'package:dio/dio.dart';
import '../db/armazenamento_seguro.dart';
import '../errors/excecoes.dart';

/// Cliente HTTP principal baseado na biblioteca Dio.
class ClienteApi {
  late final Dio dio;
  final String urlBase = 'http://127.0.0.1:8000/api/v1';

  ClienteApi() {
    dio = Dio(
      BaseOptions(
        baseUrl: urlBase,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(InterceptadorAutenticacao());
    dio.interceptors.add(InterceptadorMock());
  }
}

/// Interceptador para adicionar token de autenticação e tratar renovação automática de token.
class InterceptadorAutenticacao extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await ArmazenamentoSeguro.instancia.obterToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Trata erro 401 e tenta fazer o refresh do token
    if (err.response?.statusCode == 401) {
      final tokenNovo = await _executarRefresh();
      if (tokenNovo != null) {
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $tokenNovo';

        // Refaz a requisição original falhada
        final dioNovo = Dio(BaseOptions(baseUrl: options.baseUrl));
        try {
          final resposta = await dioNovo.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: Options(method: options.method, headers: options.headers),
          );
          return handler.resolve(resposta);
        } catch (e) {
          handler.next(err);
          return;
        }
      } else {
        // Se falhou o refresh, limpa token e encaminha erro
        await ArmazenamentoSeguro.instancia.limparToken();
      }
    }

    // Tratamento genérico de erros HTTP
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: ExcecaoSemRede(),
          type: err.type,
        ),
      );
      return;
    }

    final status = err.response?.statusCode;
    if (status == 500) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: ExcecaoServidor(),
          type: err.type,
        ),
      );
    } else if (status == 429) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: ExcecaoLimiteRequisicoes(),
          type: err.type,
        ),
      );
    } else if (status == 404) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: ExcecaoNaoEncontrado(),
          type: err.type,
        ),
      );
    } else if (status == 422) {
      final dados = err.response?.data;
      final mensagem = dados is Map
          ? dados['mensagem'] ?? 'Erro de validação.'
          : 'Erro de validação.';
      final erros = dados is Map ? dados['data'] : null;
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: ExcecaoValidacao(mensagem: mensagem, erros: erros),
          type: err.type,
        ),
      );
    } else {
      handler.next(err);
    }
  }

  Future<String?> _executarRefresh() async {
    final dioRefresh = Dio(
      BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'),
    );
    final tokenAtual = await ArmazenamentoSeguro.instancia.obterToken();
    if (tokenAtual == null) return null;

    try {
      final resposta = await dioRefresh.post(
        '/auth/refresh',
        data: {'device_name': 'dispositivo_local'},
        options: Options(headers: {'Authorization': 'Bearer $tokenAtual'}),
      );
      if (resposta.statusCode == 200) {
        final corpo = resposta.data;
        final tokenNovo = corpo['data']['token'] as String;
        await ArmazenamentoSeguro.instancia.salvarToken(tokenNovo);
        return tokenNovo;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

/// Interceptador Mock para emular respostas do backend caso o servidor esteja offline.
class InterceptadorMock extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Se for ambiente de desenvolvimento, interceptamos caminhos específicos e simulamos sucesso
    // para garantir funcionalidade do app mesmo sem o Laravel rodando.
    final path = options.path;

    if (path.contains('/auth/login')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'mensagem': 'Login realizado com sucesso',
            'data': {
              'user': {
                'id': 'usuario_uuid_123',
                'name': 'Amelia Grace',
                'email': 'amelia@happycode.com',
              },
              'token': 'mock_token_jwt_987654321',
            },
          },
        ),
      );
      return;
    }

    if (path.contains('/auth/register')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'status': 201,
            'mensagem': 'Usuário registrado com sucesso',
            'data': {
              'user': {
                'id': 'usuario_uuid_123',
                'name': options.data['name'],
                'email': options.data['email'],
              },
              'token': 'mock_token_jwt_987654321',
            },
          },
        ),
      );
      return;
    }

    if (path.contains('/user/profile')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'mensagem': 'Perfil carregado',
            'data': {
              'id': 'usuario_uuid_123',
              'name': 'Amelia Grace',
              'email': 'amelia@happycode.com',
              'birth_date': '1998-06-12',
              'gender': 'female',
              'height': 168.0,
              'weight': 58.0,
              'goal_weight': 55.0,
              'daily_water_goal': 2500,
              'daily_kcal_goal': 2200,
              'created_at': '2026-01-01T00:00:00+00:00',
            },
          },
        ),
      );
      return;
    }

    if (path.contains('/sync')) {
      // Retorna sucesso para os UUIDs enviados no sync
      final dadosEnviados = options.data as Map<String, dynamic>;
      final workouts =
          (dadosEnviados['workouts'] as List?)
              ?.map((e) => e['id'] as String)
              .toList() ??
          [];
      final meals =
          (dadosEnviados['meals'] as List?)
              ?.map((e) => e['id'] as String)
              .toList() ??
          [];
      final sleepLogs =
          (dadosEnviados['sleep_logs'] as List?)
              ?.map((e) => e['id'] as String)
              .toList() ??
          [];
      final waterLogs =
          (dadosEnviados['water_logs'] as List?)
              ?.map((e) => e['id'] as String)
              .toList() ??
          [];

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'mensagem': 'Sincronização realizada com sucesso',
            'data': {
              'workouts': workouts,
              'meals': meals,
              'sleep_logs': sleepLogs,
              'water_logs': waterLogs,
            },
          },
        ),
      );
      return;
    }

    if (path.contains('/foods/search')) {
      final query = options.queryParameters['q'] ?? '';
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'mensagem': 'Alimentos encontrados',
            'data': [
              {
                'id': '10',
                'description': 'Arroz, integral, cozido',
                'category': 'Cereais e derivados',
                'macros': {
                  'kcal': 124.0,
                  'protein': 2.6,
                  'carbohydrate': 25.8,
                  'lipids': 1.0,
                  'fiber': 2.7,
                },
                'micros': {
                  'sodium': 1.0,
                  'calcium': 4.0,
                  'iron': 0.3,
                  'vitaminC': 0.0,
                },
              },
              {
                'id': '20',
                'description': 'Frango, peito, sem pele, grelhado',
                'category': 'Carnes e derivados',
                'macros': {
                  'kcal': 159.0,
                  'protein': 32.0,
                  'carbohydrate': 0.0,
                  'lipids': 2.5,
                  'fiber': 0.0,
                },
                'micros': {
                  'sodium': 50.0,
                  'calcium': 12.0,
                  'iron': 1.0,
                  'vitaminC': 0.0,
                },
              },
              {
                'id': '30',
                'description': 'Banana, nanica, crua',
                'category': 'Frutas e derivados',
                'macros': {
                  'kcal': 92.0,
                  'protein': 1.4,
                  'carbohydrate': 23.8,
                  'lipids': 0.1,
                  'fiber': 1.9,
                },
                'micros': {
                  'sodium': 0.0,
                  'calcium': 3.0,
                  'iron': 0.4,
                  'vitaminC': 5.9,
                },
              },
            ],
          },
        ),
      );
      return;
    }

    if (path.contains('/foods/')) {
      final partes = path.split('/');
      final id = partes.last;
      var desc = 'Alimento Genérico';
      var kcal = 100.0;
      var ptn = 5.0;
      var carb = 15.0;
      var fat = 2.0;
      var fib = 1.0;

      if (id == '10') {
        desc = 'Arroz, integral, cozido';
        kcal = 124.0;
        ptn = 2.6;
        carb = 25.8;
        fat = 1.0;
        fib = 2.7;
      } else if (id == '20') {
        desc = 'Peito de Frango Grelhado';
        kcal = 159.0;
        ptn = 32.0;
        carb = 0.0;
        fat = 2.5;
        fib = 0.0;
      } else if (id == '30') {
        desc = 'Banana Nanica';
        kcal = 92.0;
        ptn = 1.4;
        carb = 23.8;
        fat = 0.1;
        fib = 1.9;
      }

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'mensagem': 'Alimento detalhado',
            'data': {
              'id': id,
              'description': desc,
              'category': 'Alimentos TACO',
              'macros': {
                'kcal': kcal,
                'protein': ptn,
                'carbohydrate': carb,
                'lipids': fat,
                'fiber': fib,
              },
              'micros': {
                'sodium': 1.0,
                'calcium': 4.0,
                'iron': 0.3,
                'vitaminC': 0.0,
              },
            },
          },
        ),
      );
      return;
    }

    // Passa adiante para qualquer rota que não queiramos interceptar mockadamente
    handler.next(options);
  }
}
