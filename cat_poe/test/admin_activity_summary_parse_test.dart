import 'package:flutter_test/flutter_test.dart';

/// Mirrors [AdminProvider.fetchUsers] parsing of `activity_summary`.
Map<String, int> parseActivitySummary(Map<String, dynamic> data) {
  final summary = data['activity_summary'];
  if (summary is! Map<String, dynamic>) {
    return const {'total': 0, 'active': 0, 'inactive': 0};
  }
  return {
    'total': (summary['total_users'] as num?)?.toInt() ?? 0,
    'active': (summary['active_users'] as num?)?.toInt() ?? 0,
    'inactive': (summary['inactive_users'] as num?)?.toInt() ?? 0,
  };
}

void main() {
  test('parses admin users activity_summary', () {
    final parsed = parseActivitySummary({
      'users': [],
      'total_count': 2,
      'has_more': false,
      'activity_summary': {
        'total_users': 100,
        'active_users': 40,
        'inactive_users': 60,
      },
    });
    expect(parsed['total'], 100);
    expect(parsed['active'], 40);
    expect(parsed['inactive'], 60);
  });
}
