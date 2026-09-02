import 'package:flutter_test/flutter_test.dart';
import 'package:cat_poe/models/auth_api_responses.dart';

void main() {
  group('SignupAck', () {
    test('parses message-only signup response', () {
      final ack = SignupAck.fromJson({
        'message':
            'If you can register with this email, you will receive a verification message shortly.',
      });
      expect(ack.message, contains('verification'));
    });

    test('rejects legacy user-shaped JSON', () {
      expect(
        () => SignupAck.fromJson({
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'username': '900000001',
          'email': 'a@b.com',
        }),
        throwsFormatException,
      );
    });

    test('rejects empty message', () {
      expect(
        () => SignupAck.fromJson({'message': ''}),
        throwsFormatException,
      );
    });
  });

  group('AuthTokenPayload', () {
    test('parses login/verify/refresh shape', () {
      final p = AuthTokenPayload.fromJson({
        'access_token': 'a',
        'refresh_token': 'b',
        'token_type': 'bearer',
      });
      expect(p.accessToken, 'a');
      expect(p.refreshToken, 'b');
    });

    test('requires both tokens (rotation contract)', () {
      expect(
        () => AuthTokenPayload.fromJson({
          'access_token': 'only-access',
          'token_type': 'bearer',
        }),
        throwsFormatException,
      );
    });

    test('rejects empty refresh after rotation', () {
      expect(
        () => AuthTokenPayload.fromJson({
          'access_token': 'x',
          'refresh_token': '',
        }),
        throwsFormatException,
      );
    });
  });
}
