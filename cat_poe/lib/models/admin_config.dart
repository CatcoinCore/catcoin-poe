class AdminConfig {
  final int id;
  final bool globalWithdrawalEnabled;
  final bool adRequiredForMiningStart;
  final bool adRequiredForSpeedBoost;
  final bool adRequiredForTimeBoost;
  final int timeBoostDurationSeconds;
  final double speedBoostPerReferral;
  @Deprecated('Use catoshiYieldPercentage instead')
  final double baseHashrate;
  final int baseMiningDurationMinutes;
  final int maxMiningDurationMinutes;
  final String timeExtensionSlots;
  @Deprecated('Use referralBoostPercentage instead')
  final double maxReferralBoostHashrate;
  final String? androidAdUnitId;
  final String? iosAdUnitId;
  final String? appAdsContent;
  final bool gameAdsEnabled;

  // Bot & Social Config
  final String? discordBotToken;
  final String? discordGuildId;
  final String? telegramBotToken;
  final String? telegramChatId;

  // X (Twitter) Config
  final String? xBearerToken;
  final String? xCommunityUsername;
  final String? xConsumerKey;
  final String? xConsumerSecret;
  final String? xAccessToken;
  final String? xAccessTokenSecret;
  final String? xClientId;
  final String? xClientSecret;

  final bool enableVerificationRelease;
  final bool enableVerificationDebug;
  final String verificationBackoffDelays;

  // Wallet & Profile
  final bool enableWalletHoldingDays;
  final bool enableProfilePicture;
  final String? coinExplorerApiKey;
  final bool useManualCatPrice;
  final int manualCatPriceUsdt;
  final String coingeckoCoinId;
  final double catoshiYieldPercentage;
  final double referralBoostPercentage;
  final int maxActiveReferrers;
  /// Referral milestone one-time bonus per invite (catoshi); server default 10_000_000.
  final int referralMilestoneBonusCatoshi;

  // Games Module Configuration
  final bool isRunnerGameVisible;
  final bool isMinerGameVisible;
  final bool isTictactoeGameVisible;
  final bool isSudokuGameVisible;
  final bool isCollageGameVisible;
  final bool isArrowGameVisible;
  final bool isTwenty48GameVisible;
  final bool isTileSwapGameVisible;

  // Global Announcement (admin may load full map from GET /v1/admin/config)
  final String? globalPushMessage;
  final Map<String, String>? globalPushMessages;
  final String latestVersionAndroid;
  final String minVersionAndroid;
  final String updateUrlAndroid;
  final String latestVersionIOS;
  final String minVersionIOS;
  final String updateUrlIOS;
  final String latestVersionWindows;
  final String minVersionWindows;
  final String updateUrlWindows;
  final String leaderboardSortBy;
  final String gameBoostConfig;
  final String gameRewardConfig;

  AdminConfig({
    required this.id,
    required this.globalWithdrawalEnabled,
    required this.adRequiredForMiningStart,
    required this.adRequiredForSpeedBoost,
    required this.adRequiredForTimeBoost,
    required this.timeBoostDurationSeconds,
    required this.speedBoostPerReferral,
    required this.baseHashrate,
    required this.baseMiningDurationMinutes,
    required this.maxMiningDurationMinutes,
    required this.timeExtensionSlots,
    required this.maxReferralBoostHashrate,
    this.androidAdUnitId,
    this.iosAdUnitId,
    this.appAdsContent,
    required this.gameAdsEnabled,
    this.discordBotToken,
    this.discordGuildId,
    this.telegramBotToken,
    this.telegramChatId,
    this.xBearerToken,
    this.xCommunityUsername,
    this.xConsumerKey,
    this.xConsumerSecret,
    this.xAccessToken,
    this.xAccessTokenSecret,
    this.xClientId,
    this.xClientSecret,
    required this.enableVerificationRelease,
    required this.enableVerificationDebug,
    required this.verificationBackoffDelays,
    required this.enableWalletHoldingDays,
    required this.enableProfilePicture,
    this.coinExplorerApiKey,
    required this.useManualCatPrice,
    required this.manualCatPriceUsdt,
    required this.coingeckoCoinId,
    required this.catoshiYieldPercentage,
    required this.referralBoostPercentage,
    required this.maxActiveReferrers,
    this.referralMilestoneBonusCatoshi = 10000000,
    required this.isRunnerGameVisible,
    required this.isMinerGameVisible,
    required this.isTictactoeGameVisible,
    required this.isSudokuGameVisible,
    required this.isCollageGameVisible,
    this.isArrowGameVisible = true,
    this.isTwenty48GameVisible = true,
    this.isTileSwapGameVisible = true,
    this.globalPushMessage,
    this.globalPushMessages,
    required this.latestVersionAndroid,
    required this.minVersionAndroid,
    required this.updateUrlAndroid,
    required this.latestVersionIOS,
    required this.minVersionIOS,
    required this.updateUrlIOS,
    required this.latestVersionWindows,
    required this.minVersionWindows,
    required this.updateUrlWindows,
    required this.leaderboardSortBy,
    required this.gameBoostConfig,
    required this.gameRewardConfig,
  });

  factory AdminConfig.fromJson(Map<String, dynamic> json) {
    return AdminConfig(
      id: json['id'] as int? ?? 1,
      globalWithdrawalEnabled: json['global_withdrawal_enabled'] as bool? ?? true,
      adRequiredForMiningStart:
          json['ad_required_for_mining_start'] as bool? ?? false,
      adRequiredForSpeedBoost:
          json['ad_required_for_speed_boost'] as bool? ?? false,
      adRequiredForTimeBoost:
          json['ad_required_for_time_boost'] as bool? ?? false,
      timeBoostDurationSeconds:
          json['time_boost_duration_seconds'] as int? ?? 14400,
      speedBoostPerReferral:
          (json['speed_boost_per_referral'] as num?)?.toDouble() ?? 10.0,
      baseHashrate: (json['base_hashrate'] as num?)?.toDouble() ?? 100.0,
      baseMiningDurationMinutes:
          json['base_mining_duration_minutes'] as int? ?? 480,
      maxMiningDurationMinutes:
          json['max_mining_duration_minutes'] as int? ?? 1440,
      timeExtensionSlots: json['time_extension_slots'] as String? ??
          "[120, 180, 240, 300, 360]",
      maxReferralBoostHashrate:
          (json['max_referral_boost_hashrate'] as num?)?.toDouble() ?? 100.0,
      androidAdUnitId: json['android_ad_unit_id'] as String?,
      iosAdUnitId: json['ios_ad_unit_id'] as String?,
      appAdsContent: json['app_ads_content'] as String?,
      gameAdsEnabled: json['game_ads_enabled'] as bool? ?? false,
      discordBotToken: json['discord_bot_token'] as String?,
      discordGuildId: json['discord_guild_id'] as String?,
      telegramBotToken: json['telegram_bot_token'] as String?,
      telegramChatId: json['telegram_chat_id'] as String?,
      xBearerToken: json['x_bearer_token'] as String?,
      xCommunityUsername: json['x_community_username'] as String?,
      xConsumerKey: json['x_consumer_key'] as String?,
      xConsumerSecret: json['x_consumer_secret'] as String?,
      xAccessToken: json['x_access_token'] as String?,
      xAccessTokenSecret: json['x_access_token_secret'] as String?,
      xClientId: json['x_client_id'] as String?,
      xClientSecret: json['x_client_secret'] as String?,
      enableVerificationRelease:
          json['enable_verification_release'] as bool? ?? true,
      enableVerificationDebug:
          json['enable_verification_debug'] as bool? ?? true,
      verificationBackoffDelays:
          json['verification_backoff_delays'] as String? ??
              "[120, 180, 300, 420, 600]",
      enableWalletHoldingDays:
          json['enable_wallet_holding_days'] as bool? ?? true,
      enableProfilePicture: json['enable_profile_picture'] as bool? ?? false,
      coinExplorerApiKey: json['coin_explorer_api_key'] as String?,
      useManualCatPrice: json['use_manual_cat_price'] == true ||
          json['use_manual_cat_price'] == 1 ||
          json['use_manual_cat_price'] == 'true' ||
          json['use_manual_cat_price'] == '1',
      manualCatPriceUsdt: json['manual_cat_price_usdt'] as int? ?? 50000,
      coingeckoCoinId: json['coingecko_coin_id'] as String? ?? 'catcoins',
      catoshiYieldPercentage:
          (json['catoshi_yield_percentage'] as num?)?.toDouble() ?? 100.0,
      referralBoostPercentage:
          (json['referral_boost_percentage'] as num?)?.toDouble() ?? 10.0,
      maxActiveReferrers:
          (json['max_active_referrers'] as num?)?.round() ?? 10,
      referralMilestoneBonusCatoshi:
          (json['referral_milestone_bonus_catoshi'] as num?)?.round() ??
              10000000,
      isRunnerGameVisible: json['is_runner_game_visible'] as bool? ?? true,
      isMinerGameVisible: json['is_miner_game_visible'] as bool? ?? true,
      isTictactoeGameVisible: json['is_tictactoe_game_visible'] as bool? ?? true,
      isSudokuGameVisible: json['is_sudoku_game_visible'] as bool? ?? true,
      isCollageGameVisible: json['is_collage_game_visible'] as bool? ?? true,
      isArrowGameVisible: json['is_arrow_game_visible'] as bool? ?? true,
      isTwenty48GameVisible: json['is_twenty48_game_visible'] as bool? ?? true,
      isTileSwapGameVisible: json['is_tile_swap_game_visible'] as bool? ?? true,
      globalPushMessage: json['global_push_message'] as String?,
      globalPushMessages: _globalPushMessagesFromJson(
          json['global_push_messages']),
      latestVersionAndroid:
          json['latest_version_android'] as String? ?? "1.0.0",
      minVersionAndroid: json['min_version_android'] as String? ?? "1.0.0",
      updateUrlAndroid: json['update_url_android'] as String? ??
          "https://play.google.com/store/apps/details?id=org.catcoin.cat",
      latestVersionIOS: json['latest_version_ios'] as String? ?? "1.0.0",
      minVersionIOS: json['min_version_ios'] as String? ?? "1.0.0",
      updateUrlIOS: json['update_url_ios'] as String? ??
          "https://apps.apple.com/app/id123456789",
      latestVersionWindows:
          json['latest_version_windows'] as String? ?? "1.0.0",
      minVersionWindows: json['min_version_windows'] as String? ?? "1.0.0",
      updateUrlWindows: json['update_url_windows'] as String? ??
          "https://catcoin.in/download",
      leaderboardSortBy: json['leaderboard_sort_by'] as String? ?? "BALANCE",
      // Game JSON comes from the API / DB only; use seed_admin_game_config.py for server defaults.
      gameBoostConfig: json['game_boost_config'] as String? ?? '',
      gameRewardConfig: json['game_reward_config'] as String? ?? '',
    );
  }

  static Map<String, String>? _globalPushMessagesFromJson(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (k == null || v == null) return;
      final key = k.toString();
      final text = v is String ? v : v.toString();
      if (text.trim().isEmpty) return;
      out[key.toLowerCase()] = text;
    });
    return out.isEmpty ? null : out;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'global_withdrawal_enabled': globalWithdrawalEnabled,
      'ad_required_for_mining_start': adRequiredForMiningStart,
      'ad_required_for_speed_boost': adRequiredForSpeedBoost,
      'ad_required_for_time_boost': adRequiredForTimeBoost,
      'time_boost_duration_seconds': timeBoostDurationSeconds,
      'speed_boost_per_referral': speedBoostPerReferral,
      'base_hashrate': baseHashrate,
      'base_mining_duration_minutes': baseMiningDurationMinutes,
      'max_mining_duration_minutes': maxMiningDurationMinutes,
      'time_extension_slots': timeExtensionSlots,
      'max_referral_boost_hashrate': maxReferralBoostHashrate,
      'android_ad_unit_id': androidAdUnitId,
      'ios_ad_unit_id': iosAdUnitId,
      'app_ads_content': appAdsContent,
      'game_ads_enabled': gameAdsEnabled,
      'discord_bot_token': discordBotToken,
      'discord_guild_id': discordGuildId,
      'telegram_bot_token': telegramBotToken,
      'telegram_chat_id': telegramChatId,
      'x_bearer_token': xBearerToken,
      'x_community_username': xCommunityUsername,
      'x_consumer_key': xConsumerKey,
      'x_consumer_secret': xConsumerSecret,
      'x_access_token': xAccessToken,
      'x_access_token_secret': xAccessTokenSecret,
      'x_client_id': xClientId,
      'x_client_secret': xClientSecret,
      'enable_verification_release': enableVerificationRelease,
      'enable_verification_debug': enableVerificationDebug,
      'verification_backoff_delays': verificationBackoffDelays,
      'enable_wallet_holding_days': enableWalletHoldingDays,
      'enable_profile_picture': enableProfilePicture,
      'coin_explorer_api_key': coinExplorerApiKey,
      'use_manual_cat_price': useManualCatPrice,
      'manual_cat_price_usdt': manualCatPriceUsdt,
      'coingecko_coin_id': coingeckoCoinId,
      'catoshi_yield_percentage': catoshiYieldPercentage,
      'referral_boost_percentage': referralBoostPercentage,
      'max_active_referrers': maxActiveReferrers,
      'referral_milestone_bonus_catoshi': referralMilestoneBonusCatoshi,
      'is_runner_game_visible': isRunnerGameVisible,
      'is_miner_game_visible': isMinerGameVisible,
      'is_tictactoe_game_visible': isTictactoeGameVisible,
      'is_sudoku_game_visible': isSudokuGameVisible,
      'is_collage_game_visible': isCollageGameVisible,
      'is_arrow_game_visible': isArrowGameVisible,
      'is_twenty48_game_visible': isTwenty48GameVisible,
      'is_tile_swap_game_visible': isTileSwapGameVisible,
      'global_push_message': globalPushMessage,
      if (globalPushMessages != null && globalPushMessages!.isNotEmpty)
        'global_push_messages': globalPushMessages,
      'latest_version_android': latestVersionAndroid,
      'min_version_android': minVersionAndroid,
      'update_url_android': updateUrlAndroid,
      'latest_version_ios': latestVersionIOS,
      'min_version_ios': minVersionIOS,
      'update_url_ios': updateUrlIOS,
      'latest_version_windows': latestVersionWindows,
      'min_version_windows': minVersionWindows,
      'update_url_windows': updateUrlWindows,
      'leaderboard_sort_by': leaderboardSortBy,
      'game_boost_config': gameBoostConfig,
      'game_reward_config': gameRewardConfig,
    };
  }

  AdminConfig copyWith({
    int? id,
    bool? globalWithdrawalEnabled,
    bool? adRequiredForMiningStart,
    bool? adRequiredForSpeedBoost,
    bool? adRequiredForTimeBoost,
    int? timeBoostDurationSeconds,
    double? speedBoostPerReferral,
    double? baseHashrate,
    int? baseMiningDurationMinutes,
    int? maxMiningDurationMinutes,
    String? timeExtensionSlots,
    double? maxReferralBoostHashrate,
    String? androidAdUnitId,
    String? iosAdUnitId,
    String? appAdsContent,
    bool? gameAdsEnabled,
    String? discordBotToken,
    String? discordGuildId,
    String? telegramBotToken,
    String? telegramChatId,
    String? xBearerToken,
    String? xCommunityUsername,
    String? xConsumerKey,
    String? xConsumerSecret,
    String? xAccessToken,
    String? xAccessTokenSecret,
    String? xClientId,
    String? xClientSecret,
    bool? enableVerificationRelease,
    bool? enableVerificationDebug,
    String? verificationBackoffDelays,
    bool? enableWalletHoldingDays,
    bool? enableProfilePicture,
    String? coinExplorerApiKey,
    bool? useManualCatPrice,
    int? manualCatPriceUsdt,
    String? coingeckoCoinId,
    double? catoshiYieldPercentage,
    double? referralBoostPercentage,
    int? maxActiveReferrers,
    int? referralMilestoneBonusCatoshi,
    bool? isRunnerGameVisible,
    bool? isMinerGameVisible,
    bool? isTictactoeGameVisible,
    bool? isSudokuGameVisible,
    bool? isCollageGameVisible,
    bool? isArrowGameVisible,
    bool? isTwenty48GameVisible,
    bool? isTileSwapGameVisible,
    String? globalPushMessage,
    Map<String, String>? globalPushMessages,
    String? latestVersionAndroid,
    String? minVersionAndroid,
    String? updateUrlAndroid,
    String? latestVersionIOS,
    String? minVersionIOS,
    String? updateUrlIOS,
    String? latestVersionWindows,
    String? minVersionWindows,
    String? updateUrlWindows,
    String? leaderboardSortBy,
    String? gameBoostConfig,
    String? gameRewardConfig,
  }) {
    return AdminConfig(
      id: id ?? this.id,
      globalWithdrawalEnabled:
          globalWithdrawalEnabled ?? this.globalWithdrawalEnabled,
      adRequiredForMiningStart:
          adRequiredForMiningStart ?? this.adRequiredForMiningStart,
      adRequiredForSpeedBoost:
          adRequiredForSpeedBoost ?? this.adRequiredForSpeedBoost,
      adRequiredForTimeBoost:
          adRequiredForTimeBoost ?? this.adRequiredForTimeBoost,
      timeBoostDurationSeconds:
          timeBoostDurationSeconds ?? this.timeBoostDurationSeconds,
      speedBoostPerReferral:
          speedBoostPerReferral ?? this.speedBoostPerReferral,
      baseHashrate: baseHashrate ?? this.baseHashrate,
      baseMiningDurationMinutes:
          baseMiningDurationMinutes ?? this.baseMiningDurationMinutes,
      maxMiningDurationMinutes:
          maxMiningDurationMinutes ?? this.maxMiningDurationMinutes,
      timeExtensionSlots: timeExtensionSlots ?? this.timeExtensionSlots,
      maxReferralBoostHashrate:
          maxReferralBoostHashrate ?? this.maxReferralBoostHashrate,
      androidAdUnitId: androidAdUnitId ?? this.androidAdUnitId,
      iosAdUnitId: iosAdUnitId ?? this.iosAdUnitId,
      appAdsContent: appAdsContent ?? this.appAdsContent,
      gameAdsEnabled: gameAdsEnabled ?? this.gameAdsEnabled,
      discordBotToken: discordBotToken ?? this.discordBotToken,
      discordGuildId: discordGuildId ?? this.discordGuildId,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      xBearerToken: xBearerToken ?? this.xBearerToken,
      xCommunityUsername: xCommunityUsername ?? this.xCommunityUsername,
      xConsumerKey: xConsumerKey ?? this.xConsumerKey,
      xConsumerSecret: xConsumerSecret ?? this.xConsumerSecret,
      xAccessToken: xAccessToken ?? this.xAccessToken,
      xAccessTokenSecret: xAccessTokenSecret ?? this.xAccessTokenSecret,
      xClientId: xClientId ?? this.xClientId,
      xClientSecret: xClientSecret ?? this.xClientSecret,
      enableVerificationRelease:
          enableVerificationRelease ?? this.enableVerificationRelease,
      enableVerificationDebug:
          enableVerificationDebug ?? this.enableVerificationDebug,
      verificationBackoffDelays:
          verificationBackoffDelays ?? this.verificationBackoffDelays,
      enableWalletHoldingDays:
          enableWalletHoldingDays ?? this.enableWalletHoldingDays,
      enableProfilePicture: enableProfilePicture ?? this.enableProfilePicture,
      coinExplorerApiKey: coinExplorerApiKey ?? this.coinExplorerApiKey,
      useManualCatPrice: useManualCatPrice ?? this.useManualCatPrice,
      manualCatPriceUsdt: manualCatPriceUsdt ?? this.manualCatPriceUsdt,
      coingeckoCoinId: coingeckoCoinId ?? this.coingeckoCoinId,
      catoshiYieldPercentage:
          catoshiYieldPercentage ?? this.catoshiYieldPercentage,
      referralBoostPercentage:
          referralBoostPercentage ?? this.referralBoostPercentage,
      maxActiveReferrers: maxActiveReferrers ?? this.maxActiveReferrers,
      referralMilestoneBonusCatoshi:
          referralMilestoneBonusCatoshi ?? this.referralMilestoneBonusCatoshi,
      isRunnerGameVisible: isRunnerGameVisible ?? this.isRunnerGameVisible,
      isMinerGameVisible: isMinerGameVisible ?? this.isMinerGameVisible,
      isTictactoeGameVisible: isTictactoeGameVisible ?? this.isTictactoeGameVisible,
      isSudokuGameVisible: isSudokuGameVisible ?? this.isSudokuGameVisible,
      isCollageGameVisible: isCollageGameVisible ?? this.isCollageGameVisible,
      isArrowGameVisible: isArrowGameVisible ?? this.isArrowGameVisible,
      isTwenty48GameVisible:
          isTwenty48GameVisible ?? this.isTwenty48GameVisible,
      isTileSwapGameVisible:
          isTileSwapGameVisible ?? this.isTileSwapGameVisible,
      globalPushMessage: globalPushMessage ?? this.globalPushMessage,
      globalPushMessages: globalPushMessages ?? this.globalPushMessages,
      latestVersionAndroid: latestVersionAndroid ?? this.latestVersionAndroid,
      minVersionAndroid: minVersionAndroid ?? this.minVersionAndroid,
      updateUrlAndroid: updateUrlAndroid ?? this.updateUrlAndroid,
      latestVersionIOS: latestVersionIOS ?? this.latestVersionIOS,
      minVersionIOS: minVersionIOS ?? this.minVersionIOS,
      updateUrlIOS: updateUrlIOS ?? this.updateUrlIOS,
      latestVersionWindows: latestVersionWindows ?? this.latestVersionWindows,
      minVersionWindows: minVersionWindows ?? this.minVersionWindows,
      updateUrlWindows: updateUrlWindows ?? this.updateUrlWindows,
      leaderboardSortBy: leaderboardSortBy ?? this.leaderboardSortBy,
      gameBoostConfig: gameBoostConfig ?? this.gameBoostConfig,
      gameRewardConfig: gameRewardConfig ?? this.gameRewardConfig,
    );
  }
}


