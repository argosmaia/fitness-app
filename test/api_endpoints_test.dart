import 'package:fitness_app/core/api/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiEndpoints', () {
    test('usa as rotas reais em português do Laravel', () {
      expect(ApiEndpoints.workouts, '/treinos');
      expect(ApiEndpoints.meals, '/refeicoes');
      expect(ApiEndpoints.sleepLogs, '/registros-sono');
      expect(ApiEndpoints.waterLogs, '/registros-agua');
    });

    test('gera rotas de recurso com id', () {
      expect(ApiEndpoints.workout('abc'), '/treinos/abc');
      expect(ApiEndpoints.food(10), '/foods/10');
    });
  });
}
