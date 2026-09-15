import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/api_service.dart';

void main() {
  final api = ApiService.instance;

  group('ApiService authentication parsing', () {
    test('reads a direct Sanctum token', () {
      expect(api.authToken({'token': '1|abc'}), equals('1|abc'));
    });

    test('reads a nested token and user from Laravel response', () {
      final response = {
        'token': '1|abc',
        'data': {'name': 'Maria', 'email': 'maria@example.com'},
      };

      expect(api.authToken(response), equals('1|abc'));
      expect(api.authUser(response)['name'], equals('Maria'));
      expect(api.authUser(response)['email'], equals('maria@example.com'));
    });

    test('supports common access token names', () {
      expect(api.authToken({'access_token': 'abc'}), equals('abc'));
      expect(api.authToken({'accessToken': 'def'}), equals('def'));
      expect(
        api.authToken({
          'authorization': {'jwt': 'ghi'},
        }),
        equals('ghi'),
      );
      expect(api.authToken({'message': 'ok'}), isNull);
    });
  });
}
