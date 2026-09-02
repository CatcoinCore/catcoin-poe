import 'package:flutter_test/flutter_test.dart';

import 'package:cat_poe/games/arrow_escape/arrow_escape_engine.dart';
import 'package:cat_poe/games/arrow_escape/arrow_escape_levels.dart';

void main() {
  test('all campaign levels construct valid engines', () {
    for (final level in kArrowEscapeCampaignLevels) {
      expect(
        () => ArrowEscapeEngine.fromLevel(level),
        returnsNormally,
        reason: level.name ?? level.toString(),
      );
    }
  });
}
