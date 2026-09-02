import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/admin_config.dart';
import '../providers/admin_provider.dart';
import 'logger_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// Tests: if set, [showRewardGateAd] delegates here instead of loading ads.
  static Future<void> Function(BuildContext context, {required String gameType})?
      debugRewardGateAdOverride;

  bool _rewardGateInFlight = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Shared by [initialize] and ad load paths so preloads never race ahead of SDK init.
  Future<void>? _mobileAdsInitialization;

  Future<void> ensureMobileAdsInitialized() async {
    _mobileAdsInitialization ??= MobileAds.instance.initialize();
    await _mobileAdsInitialization!;
  }

  Future<void> initialize() => ensureMobileAdsInitialized();

  AdminConfig? _tryAdminConfig(BuildContext context) {
    try {
      return Provider.of<AdminProvider>(context, listen: false).config;
    } catch (_) {
      return null;
    }
  }

  /// Release/profile: server → dart-define → optional test fallback. Debug: always Google test IDs.
  String _getRewardedAdUnitId(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Unsupported platform');
    }
    if (kDebugMode) {
      LoggerService.info('Debug: test rewarded ad unit');
      return Platform.isAndroid
          ? AppConfig.admobTestAndroidRewarded
          : AppConfig.admobTestIosRewarded;
    }

    final admin = _tryAdminConfig(context);

    if (Platform.isAndroid) {
      final server = admin?.androidAdUnitId?.trim();
      if (server != null && server.isNotEmpty) return server;
      final fromDefine = AppConfig.admobAndroidRewarded.trim();
      if (fromDefine.isNotEmpty) return fromDefine;
      if (AppConfig.allowAdmobTestFallback) {
        LoggerService.error(
          'Android rewarded: ALLOW_ADMOB_TEST_FALLBACK → Google test unit',
        );
        return AppConfig.admobTestAndroidRewarded;
      }
      LoggerService.error(
        'Android rewarded ad unit missing (backend config or ADMOB_ANDROID_REWARDED_UNIT_ID)',
      );
      return '';
    }

    final serverIos = admin?.iosAdUnitId?.trim();
    if (serverIos != null && serverIos.isNotEmpty) return serverIos;
    final fromDefineIos = AppConfig.admobIosRewarded.trim();
    if (fromDefineIos.isNotEmpty) return fromDefineIos;
    if (AppConfig.allowAdmobTestFallback) {
      LoggerService.error(
        'iOS rewarded: ALLOW_ADMOB_TEST_FALLBACK → Google test unit',
      );
      return AppConfig.admobTestIosRewarded;
    }
    LoggerService.error(
      'iOS rewarded ad unit missing (backend config or ADMOB_IOS_REWARDED_UNIT_ID)',
    );
    return '';
  }

  String _getInterstitialAdUnitId(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Unsupported platform');
    }
    if (kDebugMode) {
      LoggerService.info('Debug: test interstitial ad unit');
      return Platform.isAndroid
          ? AppConfig.admobTestAndroidInterstitial
          : AppConfig.admobTestIosInterstitial;
    }

    final admin = _tryAdminConfig(context);

    if (Platform.isAndroid) {
      final fromDefine = AppConfig.admobAndroidInterstitial.trim();
      if (fromDefine.isNotEmpty) return fromDefine;
      final server = admin?.androidAdUnitId?.trim();
      if (server != null && server.isNotEmpty) return server;
      if (AppConfig.allowAdmobTestFallback) {
        LoggerService.error(
          'Android interstitial: ALLOW_ADMOB_TEST_FALLBACK → Google test unit',
        );
        return AppConfig.admobTestAndroidInterstitial;
      }
      LoggerService.error(
        'Android interstitial missing (ADMOB_ANDROID_INTERSTITIAL_UNIT_ID or server androidAdUnitId)',
      );
      return '';
    }

    final fromDefineIos = AppConfig.admobIosInterstitial.trim();
    if (fromDefineIos.isNotEmpty) return fromDefineIos;
    final serverIos = admin?.iosAdUnitId?.trim();
    if (serverIos != null && serverIos.isNotEmpty) return serverIos;
    if (AppConfig.allowAdmobTestFallback) {
      LoggerService.error(
        'iOS interstitial: ALLOW_ADMOB_TEST_FALLBACK → Google test unit',
      );
      return AppConfig.admobTestIosInterstitial;
    }
    LoggerService.error(
      'iOS interstitial missing (ADMOB_IOS_INTERSTITIAL_UNIT_ID or server iosAdUnitId)',
    );
    return '';
  }

  /// Load a rewarded ad to be shown later
  void loadRewardedAd(BuildContext context) {
    if (_rewardedAd != null || _isAdLoading) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _isAdLoading = true;
    unawaited(_loadRewardedAdAfterSdkReady(context));
  }

  Future<void> _loadRewardedAdAfterSdkReady(BuildContext context) async {
    try {
      await ensureMobileAdsInitialized();
      if (!context.mounted) {
        _isAdLoading = false;
        return;
      }
      if (_rewardedAd != null) {
        _isAdLoading = false;
        return;
      }
      final adUnitId = _getRewardedAdUnitId(context);
      if (adUnitId.isEmpty) {
        _isAdLoading = false;
        return;
      }

      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            LoggerService.info('Rewarded Ad loaded: $adUnitId');
            _rewardedAd = ad;
            _isAdLoading = false;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) =>
                  LoggerService.info('Rewarded Ad showed fullscreen'),
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
                loadRewardedAd(context);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _rewardedAd = null;
                LoggerService.error('Rewarded Ad failed to show', error);
                loadRewardedAd(context);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            LoggerService.error('Rewarded Ad failed to load (pre-load)', error);
            _isAdLoading = false;
          },
        ),
      );
    } catch (e, st) {
      LoggerService.error('Rewarded preload failed: $e\n$st');
      _isAdLoading = false;
    }
  }

  void showRewardedAd(BuildContext context,
      {required String userId,
      required Function onReward,
      Function(String)? onFailure}) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      onReward();
      return;
    }

    if (_rewardedAd == null) {
      LoggerService.info('Rewarded Ad not ready, loading one now...');
      unawaited(
          _loadAndShowRewarded(context, userId, onReward, onFailure));
      return;
    }

    _rewardedAd!.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: userId,
        customData: userId,
      ),
    );

    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      LoggerService.info('User earned reward: ${reward.amount} ${reward.type}');
      onReward();
    });

    _rewardedAd = null;
  }

  Future<void> _loadAndShowRewarded(BuildContext context, String userId,
      Function onReward, Function(String)? onFailure) async {
    await ensureMobileAdsInitialized();
    if (!context.mounted) return;

    final adUnitId = _getRewardedAdUnitId(context);
    if (adUnitId.isEmpty) {
      onFailure?.call('Ad unit not configured');
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          LoggerService.info('Rewarded Ad loaded (on-demand): $adUnitId');

          ad.setServerSideOptions(
            ServerSideVerificationOptions(
              userId: userId,
              customData: userId,
            ),
          );

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) =>
                LoggerService.info('Rewarded Ad showed fullscreen'),
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedAd(context);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              LoggerService.error('Rewarded Ad failed to show (on-demand)', error);
              // Do NOT grant reward if it fails to show (could be blocked or skipped by system)
              if (onFailure != null) onFailure(error.message);
              loadRewardedAd(context);
            },
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            LoggerService.info(
                'User earned reward: ${reward.amount} ${reward.type}');
            onReward();
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          LoggerService.error('Rewarded Ad failed to load (on-demand)', error);
          // Reward ONLY if the error is specifically 'No Fill' (Code 3)
          if (error.code == 3) {
            LoggerService.info('No Fill error (Code 3): granting automatic reward.');
            onReward();
          } else {
            if (onFailure != null) {
              onFailure(
                  'Failed to load ad: ${error.message} (Code: ${error.code})');
            }
          }
        },
      ),
    );
  }

  /// Load an interstitial ad to be shown later
  void loadInterstitialAd(BuildContext context) {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _isInterstitialLoading = true;
    unawaited(_loadInterstitialAdAfterSdkReady(context));
  }

  Future<void> _loadInterstitialAdAfterSdkReady(BuildContext context) async {
    try {
      await ensureMobileAdsInitialized();
      if (!context.mounted) {
        _isInterstitialLoading = false;
        return;
      }
      if (_interstitialAd != null) {
        _isInterstitialLoading = false;
        return;
      }
      final adUnitId = _getInterstitialAdUnitId(context);
      if (adUnitId.isEmpty) {
        _isInterstitialLoading = false;
        return;
      }

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            LoggerService.info('Interstitial Ad loaded: $adUnitId');
            _interstitialAd = ad;
            _isInterstitialLoading = false;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                loadInterstitialAd(context);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _interstitialAd = null;
                LoggerService.error('Interstitial Ad failed to show', error);
                loadInterstitialAd(context);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            LoggerService.error('Interstitial Ad failed to load', error);
            _isInterstitialLoading = false;
          },
        ),
      );
    } catch (e, st) {
      LoggerService.error('Interstitial preload failed: $e\n$st');
      _isInterstitialLoading = false;
    }
  }

  void showInterstitialAd(BuildContext context) {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null && !config.gameAdsEnabled) {
      LoggerService.info('Game ads disabled in config');
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) return;

    if (_interstitialAd == null) {
      LoggerService.info('Interstitial Ad not ready');
      loadInterstitialAd(context);
      return;
    }

    _interstitialAd!.show();
    _interstitialAd = null; // Important: Clear after show
  }

  /// Shows an interstitial before granting a game reward. Always completes
  /// (success, failure, load timeout, or ads disabled); never throws to callers.
  /// [gameType] is for logging / test hooks only.
  Future<void> showRewardGateAd(
    BuildContext context, {
    required String gameType,
  }) async {
    final override = debugRewardGateAdOverride;
    if (override != null) {
      try {
        await override(context, gameType: gameType);
      } catch (_) {}
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) return;

    await ensureMobileAdsInitialized();
    if (!context.mounted) return;

    try {
      final config = Provider.of<AdminProvider>(context, listen: false).config;
      if (config != null && !config.gameAdsEnabled) {
        LoggerService.info('Reward gate skipped: game ads disabled');
        return;
      }
    } catch (_) {
      // No Provider scope (e.g. some tests): still attempt ads on mobile.
    }

    if (_rewardGateInFlight) return;
    _rewardGateInFlight = true;

    final completer = Completer<void>();
    void complete() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      final adUnitId = _getInterstitialAdUnitId(context);
      if (adUnitId.isEmpty) {
        LoggerService.error('Reward gate: interstitial ad unit not configured');
        complete();
        return;
      }

      if (!context.mounted) {
        complete();
        return;
      }

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            var finished = false;
            void done() {
              if (finished) return;
              finished = true;
              complete();
            }

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) {
                a.dispose();
                loadInterstitialAd(context);
                done();
              },
              onAdFailedToShowFullScreenContent: (a, error) {
                a.dispose();
                LoggerService.error(
                    'Reward gate interstitial failed to show', error);
                loadInterstitialAd(context);
                done();
              },
            );

            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            LoggerService.error('Reward gate interstitial failed to load', error);
            complete();
          },
        ),
      );

      await completer.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          complete();
        },
      );
    } catch (e, st) {
      LoggerService.error('showRewardGateAd $st', e);
      complete();
    } finally {
      _rewardGateInFlight = false;
    }
  }
}
