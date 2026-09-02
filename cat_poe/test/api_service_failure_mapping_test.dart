import 'package:flutter_test/flutter_test.dart';
import 'package:cat_poe/services/api_service.dart';

void main() {
  group('throwApiFailureForStatusAndBody', () {
    test('409 SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION uses backend message', () {
      expect(
        () => throwApiFailureForStatusAndBody(
          409,
          '{"detail":{"error_code":"SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION",'
              '"platforms":["discord"],"user_message":"Please confirm."}}',
        ),
        throwsA(
          isA<SocialIdChangeRequiresConfirmationException>().having(
            (e) => e.platforms,
            'platforms',
            ['discord'],
          ).having(
            (e) => e.message,
            'message',
            'Please confirm.',
          ),
        ),
      );
    });

    test('409 SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION falls back to default copy',
        () {
      expect(
        () => throwApiFailureForStatusAndBody(
          409,
          '{"detail":{"error_code":"SOCIAL_ID_CHANGE_REQUIRES_CONFIRMATION",'
              '"platforms":[]}}',
        ),
        throwsA(
          isA<SocialIdChangeRequiresConfirmationException>().having(
            (e) => e.message,
            'message',
            contains('new ID is verified'),
          ),
        ),
      );
    });

    test('non-409 with detail string becomes ApiHttpException message', () {
      expect(
        () => throwApiFailureForStatusAndBody(
          400,
          '{"detail":"bad request"}',
        ),
        throwsA(
          isA<ApiHttpException>()
              .having((e) => e.statusCode, 'status', 400)
              .having((e) => e.message, 'message', 'bad request'),
        ),
      );
    });

    test('invalid JSON uses generic message', () {
      expect(
        () => throwApiFailureForStatusAndBody(503, 'not json'),
        throwsA(
          isA<ApiHttpException>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => e.message, 'message', contains('503')),
        ),
      );
    });
  });
}
