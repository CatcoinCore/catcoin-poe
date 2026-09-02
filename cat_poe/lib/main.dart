import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'app_providers.dart';
import 'providers/locale_provider.dart';
import 'providers/mining_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_wrapper.dart';
import 'services/ad_service.dart';
import 'services/game_sfx_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint(
      '[AppConfig] API=${AppConfig.apiBaseUrl} env=${AppConfig.appEnvLabel}',
    );
  }

  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: catcoinAppProviders(),
      child: const CatcoinApp(),
    ),
  );

  // Firebase, AdMob, and local notifications perform heavy platform-channel work
  // (JSON codec on Android main thread). Doing that before runApp delays the first
  // frame and contributes to "Input dispatching timed out" ANRs on cold start.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredSdks());
    unawaited(GameSfxService.instance.warmup());
  });
}

Future<void> _initializeDeferredSdks() async {
  // Firebase on Android: needs android/app/google-services.json (gitignored;
  // copy from google-services.json.example or inject in CI — see docs/firebase_fork_setup.md)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
    await AdService().initialize();
  }

  await NotificationService().init();
}

class CatcoinApp extends StatefulWidget {
  const CatcoinApp({
    super.key,
    this.authSplashMinDuration = const Duration(seconds: 2),
    this.authRunVersionCheck = true,
  });

  /// Passed to [AuthWrapper] (use [Duration.zero] in widget tests).
  final Duration authSplashMinDuration;

  /// Passed to [AuthWrapper]; set false in tests to avoid HTTP.
  final bool authRunVersionCheck;

  @override
  State<CatcoinApp> createState() => _CatcoinAppState();
}

class _CatcoinAppState extends State<CatcoinApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _scheduleReminders();
    }
  }

  void _scheduleReminders() {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final missionProvider =
        Provider.of<MissionProvider>(context, listen: false);

    final stats = miningProvider.stats;
    if (stats == null) return;

    final isMining = miningProvider.isMining;
    final endTimeUtc = isMining && stats.activeSessions.isNotEmpty
        ? stats.activeSessions.first.endTime
        : null;
    final timeLeft = miningProvider.timeLeft;

    bool canTimeBoost = false;
    if (isMining && endTimeUtc != null) {
      final startTimeUtc = stats.activeSessions.first.startTime;
      if (endTimeUtc.difference(startTimeUtc).inHours < 24) {
        canTimeBoost = true;
      }
    }

    final canBoostRef =
        stats.availableReferrals.any((r) => r.canBoost && r.isActive);
    final pendingMissions =
        missionProvider.missions.where((m) => m.status != 'completed').length;

    NotificationService().scheduleSmartReminders(
      isMining: isMining,
      canTimeBoost: canTimeBoost,
      canBoostRef: canBoostRef,
      pendingMissions: pendingMissions,
      timeLeft: timeLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Catcoin PoE',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthWrapper(
        splashMinDuration: widget.authSplashMinDuration,
        runVersionCheck: widget.authRunVersionCheck,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}


