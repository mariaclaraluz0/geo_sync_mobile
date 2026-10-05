import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final api = ApiService.instance;

  group('Segurança da URL da API', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(() => ApiService.exigirHttps = false);

    test('produção recusa HTTP e aceita HTTPS', () async {
      ApiService.exigirHttps = true;
      await expectLater(
        ApiService.saveBaseUrl('http://192.168.0.10:8000/api'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
      await ApiService.saveBaseUrl('https://api.geosync.com.br');
      expect(ApiService.baseUrl, 'https://api.geosync.com.br/api');
    });

    test('em desenvolvimento HTTP da rede local é aceito', () async {
      ApiService.exigirHttps = false;
      await ApiService.saveBaseUrl('http://192.168.0.10:8000');
      expect(ApiService.baseUrl, 'http://192.168.0.10:8000/api');
    });
  });

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

  group('Retry-After', () {
    test('interpreta segundos e limita o intervalo', () {
      expect(api.parseRetryAfterForTesting('17'), const Duration(seconds: 17));
      expect(api.parseRetryAfterForTesting('999999'), const Duration(days: 1));
    });

    test('interpreta data HTTP', () {
      final data = DateTime.now().toUtc().add(const Duration(seconds: 45));
      final header =
          '${_dias[data.weekday - 1]}, ${data.day.toString().padLeft(2, '0')} '
          '${_meses[data.month - 1]} ${data.year} '
          '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}:${data.second.toString().padLeft(2, '0')} GMT';
      final espera = api.parseRetryAfterForTesting(header);
      expect(espera, isNotNull);
      expect(espera!.inSeconds, inInclusiveRange(0, 45));
    });
  });
}

const _dias = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _meses = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
