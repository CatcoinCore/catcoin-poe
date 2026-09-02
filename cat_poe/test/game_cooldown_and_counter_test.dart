import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cat_poe/services/tictactoe_ad_counter.dart';
import 'package:cat_poe/utils/game_cooldown_format.dart';

void main() {
  group('formatGameCooldownRemaining', () {
    test('returns null for past time', () {
      expect(
        formatGameCooldownRemaining(DateTime.now().subtract(const Duration(minutes: 1))),
        null,
      );
    });

    test('includes hours and minutes when large', () {
      final until = DateTime.now().add(const Duration(hours: 2, minutes: 3));
      final s = formatGameCooldownRemaining(until)!;
      expect(s, contains('2'));
      expect(s, contains('h'));
    });
  });

  group('TicTacToeAdCounterStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('increments and resets across sessions', () async {
      await TicTacToeAdCounterStore.reset();
      expect(await TicTacToeAdCounterStore.read(), 0);
      expect(await TicTacToeAdCounterStore.incrementAndGet(), 1);
      expect(await TicTacToeAdCounterStore.incrementAndGet(), 2);
      expect(await TicTacToeAdCounterStore.incrementAndGet(), 3);
      await TicTacToeAdCounterStore.reset();
      expect(await TicTacToeAdCounterStore.read(), 0);
    });
  });
}
