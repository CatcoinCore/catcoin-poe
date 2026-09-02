import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cat_poe/services/ad_service.dart';

void main() {
  tearDown(() {
    AdService.debugRewardGateAdOverride = null;
  });

  testWidgets('reward pipeline runs ad step before reward callback', (tester) async {
    final log = <String>[];
    AdService.debugRewardGateAdOverride =
        (BuildContext ctx, {required String gameType}) async {
      log.add('ad:$gameType');
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await AdService()
                    .showRewardGateAd(context, gameType: 'SUDOKU');
                log.add('reward');
              },
              child: const Text('go'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(log, ['ad:SUDOKU', 'reward']);
  });

  testWidgets('ad override failure still allows reward flow', (tester) async {
    final log = <String>[];
    AdService.debugRewardGateAdOverride =
        (BuildContext ctx, {required String gameType}) async {
      throw Exception('simulated ad failure');
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await AdService()
                    .showRewardGateAd(context, gameType: 'COLLAGE');
                log.add('reward');
              },
              child: const Text('go'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(log, ['reward']);
  });
}
