import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:cat_poe/providers/auth_provider.dart';
import 'package:cat_poe/providers/locale_provider.dart';
import 'package:cat_poe/screens/auth_wrapper.dart';
import 'package:cat_poe/services/link_service.dart';

class _MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late _MockAuthProvider auth;

  setUp(() {
    auth = _MockAuthProvider();
    when(() => auth.checkAuth()).thenAnswer((_) async {});
    when(() => auth.sessionResumeBlocked).thenReturn(true);
    when(() => auth.isAuthenticated).thenReturn(false);
    when(() => auth.user).thenReturn(null);
    when(() => auth.isResumeProfileLoading).thenReturn(false);
    when(() => auth.retryResumeSession()).thenAnswer((_) async {});
    when(() => auth.logout()).thenAnswer((_) async {});
  });

  testWidgets('shows session resume UI when profile check failed but tokens kept',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => LinkService()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          home: const AuthWrapper(
            splashMinDuration: Duration.zero,
            runVersionCheck: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('Could not reach the server'),
      findsOneWidget,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => auth.retryResumeSession()).called(1);
  });
}
