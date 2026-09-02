import 'package:flutter_test/flutter_test.dart';
import 'package:cat_poe/l10n/app_localizations_en.dart';

void main() {
  test('English referrals ping strings are wired', () {
    final l = AppLocalizationsEn();
    expect(l.referralsPingAll, isNotEmpty);
    expect(l.referralsPingConfirmTitle, isNotEmpty);
    expect(l.referralsPingResult(1, 2, 0, 3), contains('Pinged'));
  });
}
