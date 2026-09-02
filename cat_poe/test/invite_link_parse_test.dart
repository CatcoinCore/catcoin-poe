import 'package:flutter_test/flutter_test.dart';
import 'package:cat_poe/services/link_service.dart';

void main() {
  test('parseInviteReferralCode https path', () {
    expect(
      parseInviteReferralCode(Uri.parse('https://poe.catcoin.in/invite/TREFab12')),
      'TREFab12',
    );
  });

  test('parseInviteReferralCode strips query and trailing slash segment', () {
    expect(
      parseInviteReferralCode(
        Uri.parse('https://poe.catcoin.in/invite/ABC?utm=1'),
      ),
      'ABC',
    );
  });

  test('parseInviteReferralCode hash route fragment', () {
    final u = Uri.parse('https://poe.catcoin.in/');
    expect(
      parseInviteReferralCode(u.replace(fragment: '/invite/XYZ99')),
      'XYZ99',
    );
  });

  test('parseInviteReferralCode custom scheme host invite', () {
    expect(
      parseInviteReferralCode(Uri.parse('catpoe://invite/REF001')),
      'REF001',
    );
  });
}
