import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cat_poe/app_providers.dart';
import 'package:cat_poe/main.dart';
import 'package:cat_poe/screens/auth_wrapper.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CatcoinApp builds with the same provider tree as main',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: catcoinAppProviders(),
        child: const CatcoinApp(
          authSplashMinDuration: Duration.zero,
          authRunVersionCheck: false,
        ),
      ),
    );
    await tester.pump(); // first frame + post-frame callback starts auth flow
    // Advance past zero-duration splash delay and async auth work without pumpAndSettle
    // (LoginScreen may run non-idling animations that would timeout settle).
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthWrapper), findsOneWidget);
  });
}
