import 'package:cat_poe/services/diagnostic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientErrorReport.toJson', () {
    test('serialises all populated fields with snake_case keys', () {
      final report = ClientErrorReport(
        fingerprint: 'auth_resume_blocked',
        userId: '5f2c8c6c-8e6a-4e6a-9d4c-2c0c8a1c9b3a',
        appVersion: '1.10.7+105',
        platform: 'android',
        osVersion: 'Android 13',
        locale: 'en-IN',
        screen: 'auth_wrapper',
        errorClass: 'ApiTransientBackendException',
        errorMessage: 'Service unavailable. Please try again later.',
        httpStatus: 503,
        occurredAt: DateTime.utc(2026, 5, 25, 16, 6),
        breadcrumbs: const ['boot', 'checkAuth', 'fetchUserProfile'],
      );

      final json = report.toJson();
      expect(json['fingerprint'], 'auth_resume_blocked');
      expect(json['user_id'], '5f2c8c6c-8e6a-4e6a-9d4c-2c0c8a1c9b3a');
      expect(json['app_version'], '1.10.7+105');
      expect(json['platform'], 'android');
      expect(json['os_version'], 'Android 13');
      expect(json['locale'], 'en-IN');
      expect(json['screen'], 'auth_wrapper');
      expect(json['error_class'], 'ApiTransientBackendException');
      expect(json['error_message'], 'Service unavailable. Please try again later.');
      expect(json['http_status'], 503);
      expect(json['occurred_at'], '2026-05-25T16:06:00.000Z');
      expect(json['breadcrumbs'], ['boot', 'checkAuth', 'fetchUserProfile']);
    });

    test('omits null fields entirely', () {
      final report = ClientErrorReport(
        fingerprint: 'auth_resume_blocked',
        appVersion: '1.10.7+105',
        platform: 'android',
      );
      final json = report.toJson();
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('os_version'), isFalse);
      expect(json.containsKey('error_class'), isFalse);
      expect(json.containsKey('breadcrumbs'), isFalse);
    });

    test('clips strings to the server-side caps', () {
      final huge = 'x' * 3000; // > error_message cap of 2048
      final hugeBreadcrumb = 'b' * 300; // > 256
      final report = ClientErrorReport(
        fingerprint: 'a' * 200, // > 128
        appVersion: 'v' * 100, // > 64
        platform: 'p' * 50, // > 32
        errorMessage: huge,
        breadcrumbs: List<String>.generate(25, (_) => hugeBreadcrumb),
      );
      final json = report.toJson();
      expect((json['fingerprint'] as String).length, 128);
      expect((json['app_version'] as String).length, 64);
      expect((json['platform'] as String).length, 32);
      expect((json['error_message'] as String).length, 2048);
      final crumbs = json['breadcrumbs'] as List;
      // Cap is 20 — even though we passed 25.
      expect(crumbs.length, 20);
      for (final c in crumbs) {
        expect((c as String).length, 256);
      }
    });
  });

  group('ClientErrorReport.fromJson', () {
    test('round-trips a populated report', () {
      final original = ClientErrorReport(
        fingerprint: 'fp',
        userId: 'uid',
        appVersion: 'v1',
        platform: 'android',
        osVersion: 'Android 13',
        locale: 'en',
        screen: 's',
        errorClass: 'E',
        errorMessage: 'm',
        httpStatus: 503,
        occurredAt: DateTime.utc(2026, 1, 1),
        breadcrumbs: const ['a', 'b'],
      );
      final round = ClientErrorReport.fromJson(original.toJson());
      expect(round.fingerprint, original.fingerprint);
      expect(round.userId, original.userId);
      expect(round.appVersion, original.appVersion);
      expect(round.platform, original.platform);
      expect(round.osVersion, original.osVersion);
      expect(round.locale, original.locale);
      expect(round.screen, original.screen);
      expect(round.errorClass, original.errorClass);
      expect(round.errorMessage, original.errorMessage);
      expect(round.httpStatus, original.httpStatus);
      expect(round.occurredAt, original.occurredAt);
      expect(round.breadcrumbs, original.breadcrumbs);
    });

    test('tolerates missing optional keys', () {
      final report = ClientErrorReport.fromJson(<String, dynamic>{
        'fingerprint': 'fp',
        'app_version': 'v',
        'platform': 'android',
      });
      expect(report.userId, isNull);
      expect(report.httpStatus, isNull);
      expect(report.breadcrumbs, isEmpty);
    });
  });
}
