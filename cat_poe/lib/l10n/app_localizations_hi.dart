// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'होम';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'खेल';

  @override
  String get navLeaders => 'लीडर्स';

  @override
  String get navWallet => 'वॉलेट';

  @override
  String get navRewards => 'इनाम';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonError => 'त्रुटि';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'लोड हो रहा है...';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonNone => 'कोई नहीं';

  @override
  String get commonGallery => 'गैलरी';

  @override
  String get commonCamera => 'कैमरा';

  @override
  String get commonRemovePhoto => 'फ़ोटो हटाएं';

  @override
  String get commonRequired => 'आवश्यक है';

  @override
  String get commonUnlockEdit => 'अनलॉक करें और संपादित करें';

  @override
  String get loginTitle => 'लॉग इन';

  @override
  String get loginEmailOrUsername => 'ईमेल या उपयोगकर्ता नाम';

  @override
  String get loginEmailHint => 'your.email@example.com या 900123456';

  @override
  String get loginPassword => 'पासवर्ड';

  @override
  String get loginButton => 'लॉग इन';

  @override
  String get loginCreateAccount => 'खाता बनाएं';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginUseEmailForVerification =>
      'सत्यापन पूर्ण करने के लिए कृपया ईमेल से लॉग इन करें।';

  @override
  String get signupTitle => 'साइन अप करें';

  @override
  String get signupEmail => 'ईमेल';

  @override
  String get signupEmailHint => 'your.email@example.com';

  @override
  String get signupPassword => 'पासवर्ड';

  @override
  String get signupConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get signupReferralCode => 'रेफरल कोड (वैकल्पिक)';

  @override
  String get signupReferralCodeHint => 'यदि आपके पास रेफरल कोड है तो दर्ज करें';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'साइन अप करें';

  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए';

  @override
  String get forgotPasswordEmail => 'ईमेल';

  @override
  String get forgotPasswordSendCode => 'रीसेट कोड भेजें';

  @override
  String get forgotPasswordBackToLogin => 'लॉग इन पर वापस जाएं';

  @override
  String get emailVerificationTitle => 'ईमेल सत्यापन';

  @override
  String get emailVerificationInstruction =>
      'यहां भेजा गया सत्यापन कोड दर्ज करें';

  @override
  String get emailVerificationCode => 'सत्यापन कोड';

  @override
  String get emailVerificationVerify => 'सत्यापित करें';

  @override
  String get emailVerificationResend => 'कोड पुनः भेजें';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get resetPasswordNewPassword => 'नया पासवर्ड';

  @override
  String get resetPasswordConfirm => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get resetPasswordButton => 'पासवर्ड रीसेट करें';

  @override
  String get profileSetupTitle => 'प्रोफ़ाइल सेटअप';

  @override
  String get splashLoading => 'लोड हो रहा है...';

  @override
  String get dashboardTotalBalance => 'कुल बैलेंस';

  @override
  String get dashboardCatoshi => 'catoshi';

  @override
  String get dashboardCatoshiLabel => 'कातोशी';

  @override
  String get dashboardNotMining => 'माइनिंग नहीं';

  @override
  String get dashboardStartMining => 'माइनिंग शुरू करें';

  @override
  String dashboardRewardRate(Object rate) {
    return 'पुरस्कार दर: $rate कैटोशी/सेकंड';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'वर्तमान अवधि: ${hours}h / अधिकतम ${maxHours}h';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'बूस्टर्स';

  @override
  String get boostersCardTitle => 'बूस्टर';

  @override
  String get boostersCardDescription =>
      'अपनी माइनिंग गति बढ़ाएं और सत्र का समय बढ़ाएं!';

  @override
  String get boostersOpenScreen => 'बूस्टर देखें';

  @override
  String get leaderboardTitle => 'लीडरबोर्ड';

  @override
  String get leaderboardTopMiners => 'शीर्ष माइनर';

  @override
  String get leaderboardRank => 'रैंक';

  @override
  String get leaderboardUser => 'उपयोगकर्ता';

  @override
  String get leaderboardBalance => 'शेष';

  @override
  String get leaderboardYou => 'आप';

  @override
  String get leaderboardGlobal => 'वैश्विक';

  @override
  String get leaderboardRegional => 'क्षेत्रीय';

  @override
  String get leaderboardGames => 'खेल';

  @override
  String get leaderboardAwards => 'पुरस्कार';

  @override
  String get leaderboardGlobalMonthly => 'Global (Monthly)';

  @override
  String get leaderboardRegionalMonthly => 'Regional (Monthly)';

  @override
  String get awardsLifetimeAchievements => 'Lifetime Achievements';

  @override
  String get awardsMonthlyChampions => 'Previous Month Champions';

  @override
  String get awardsPreviousMonthWinners => 'Previous Month Leaders';

  @override
  String get leaderboardChallengers => 'चुनौती देने वाले';

  @override
  String get leaderboardNoGlobal => 'कोई वैश्विक माइनर नहीं मिला।';

  @override
  String get leaderboardNoRegional => 'कोई क्षेत्रीय माइनर नहीं मिला।';

  @override
  String get leaderboardComingSoon =>
      'जल्द ही आ रहा है — मिनी-गेम्स में प्रतिस्पर्धा करें!';

  @override
  String get leaderboardNoAwards => 'अभी तक कोई पुरस्कार नहीं';

  @override
  String get leaderboardKeepMining =>
      'पोडियम पर दावा करने के लिए माइनिंग जारी रखें!';

  @override
  String get walletTitle => 'वॉलेट';

  @override
  String get walletAddress => 'वॉलेट पता';

  @override
  String get walletBalance => 'शेष';

  @override
  String get walletCopy => 'कॉपी करें';

  @override
  String get walletCopied => 'कॉपी हो गया!';

  @override
  String get walletSend => 'भेजें';

  @override
  String get walletReceive => 'प्राप्त करें';

  @override
  String get walletTransactions => 'लेनदेन';

  @override
  String get walletNoTransactions => 'अभी तक कोई लेनदेन नहीं';

  @override
  String get walletConnectWallet => 'वॉलेट कनेक्ट करें';

  @override
  String get walletDisconnect => 'डिसकनेक्ट';

  @override
  String get walletSolanaAddress => 'सोलाना पता';

  @override
  String get walletEnterAddress => 'सोलाना पता दर्ज करें';

  @override
  String get walletSaveAddress => 'पता सहेजें';

  @override
  String get walletAddressSaved => 'पता सहेजा गया!';

  @override
  String get walletInvalidAddress => 'अमान्य सोलाना पता';

  @override
  String get walletMyWallets => 'मेरे वॉलेट';

  @override
  String get walletAddExisting => 'मौजूदा पता जोड़ें';

  @override
  String get walletCatcoinAddress => 'कैटकॉइन पता';

  @override
  String get walletPasteHint => 'यहाँ पता पेस्ट करें';

  @override
  String get walletSetPrimary => 'प्राथमिक के रूप में सेट करें';

  @override
  String get walletInvalidAddressComplex =>
      'अमान्य पता। एक मान्य BEP20 (0x...), सोलाना, या कैटकॉइन (9 से शुरू होने वाला) पता होना चाहिए।';

  @override
  String get walletRecoverTitle => 'वॉलेट पुनर्प्राप्त करें';

  @override
  String get walletRecoverInstruction =>
      'अपना वॉलेट पुनर्प्राप्त करने के लिए अपना 24-शब्दों का गुप्त वाक्यांश दर्ज करें।';

  @override
  String get walletSecretPhrase => 'गुप्त वाक्यांश';

  @override
  String get walletSecretPhraseHint => 'शब्द1 शब्द2 ... शब्द24';

  @override
  String get walletInvalidPhrase =>
      'अमान्य वाक्यांश। बिल्कुल 24 शब्द होने चाहिए।';

  @override
  String get walletDeleteTitle => 'वॉलेट हटाएं';

  @override
  String walletDeleteConfirmMessage(String address) {
    return 'क्या आप वाकई वॉलेट $address को हटाना चाहते हैं? यदि आपके पास निजी कुंजी/वाक्यांश नहीं है तो इस क्रिया को पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get walletDeletedSuccess => 'वॉलेट सफलतापूर्वक हटा दिया गया';

  @override
  String get walletAddedSuccess => 'वॉलेट सफलतापूर्वक जोड़ दिया गया';

  @override
  String get walletGenerateTitle => 'नया वॉलेट जनरेट करें';

  @override
  String get walletBackupTitle => 'सफलता! अपने वॉलेट का बैकअप लें';

  @override
  String get walletBackupWarning =>
      'महत्वपूर्ण: इन 24 शब्दों को क्रम में लिख लें और उन्हें सुरक्षित रखें। आप इनके बिना अपना फंड पुनर्प्राप्त नहीं कर सकते!';

  @override
  String get walletGenerateInstruction =>
      'यह आपके लिए एक नया कैटकॉइन वॉलेट बनाएगा। बनाने के तुरंत बाद अपने गुप्त वाक्यांश का बैकअप लेना सुनिश्चित करें!';

  @override
  String get walletGenerating => 'कुंजियाँ जनरेट हो रही हैं...';

  @override
  String get walletBackedUp => 'मैंने इसका बैकअप ले लिया है';

  @override
  String get walletRecoverFromPhrase => 'वाक्यांश से पुनर्प्राप्त करें';

  @override
  String get walletSetDefault => 'डिफ़ॉल्ट सेट करें';

  @override
  String get walletSettingPrimary =>
      'वॉलेट को प्राथमिक के रूप में सेट किया जा रहा है...';

  @override
  String get walletPrimary => 'प्राथमिक';

  @override
  String get walletSourceGenerated => 'जनरेट किया गया';

  @override
  String get walletSourceRecovered => 'पुनर्प्राप्त';

  @override
  String get walletSourceManual => 'मैनुअल पता';

  @override
  String walletDaysHeld(String days) {
    return 'होल्ड किए गए दिन: $days';
  }

  @override
  String get walletCalculating => 'गणना हो रही है...';

  @override
  String get rewardsTitle => 'पुरस्कार';

  @override
  String get rewardsClaim => 'दावा करें';

  @override
  String get rewardsClaimed => 'दावा हो गया';

  @override
  String get rewardsAvailable => 'उपलब्ध';

  @override
  String get rewardsNoRewards => 'कोई पुरस्कार उपलब्ध नहीं';

  @override
  String get rewardsSocialTasks => 'सामाजिक कार्य';

  @override
  String get rewardsXTasks => 'X कार्य';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'सभी मिशन';

  @override
  String get rewardsNoMissions => 'कोई सक्रिय मिशन उपलब्ध नहीं है।';

  @override
  String rewardsError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get gamesTitle => 'गेम्स';

  @override
  String get gamesPlay => 'खेलें';

  @override
  String get gamesRunner => 'कैट रनर';

  @override
  String get gamesRunnerDescription => 'दौड़ें, कूदें और सिक्के इकट्ठा करें!';

  @override
  String get gamesNoGames => 'कोई गेम उपलब्ध नहीं';

  @override
  String get referralTitle => 'मेरे रेफरल';

  @override
  String get referralCode => 'आपका रेफरल कोड';

  @override
  String get referralCopyCode => 'कोड कॉपी करें';

  @override
  String get referralShareLink => 'लिंक शेयर करें';

  @override
  String get referralActiveReferrals => 'सक्रिय रेफरल';

  @override
  String get referralNoReferrals => 'अभी तक कोई रेफरल नहीं';

  @override
  String get referralBoost => 'बूस्ट';

  @override
  String get referralBoosted => 'बूस्ट हो गया';

  @override
  String get referralInviteFriends => 'मित्रों को आमंत्रित करें';

  @override
  String get balanceDetailTitle => 'शेष विवरण';

  @override
  String get payoutHistoryTitle => 'भुगतान इतिहास';

  @override
  String get payoutHistoryNone => 'कोई भुगतान इतिहास नहीं';

  @override
  String get awardsTitle => 'पुरस्कार';

  @override
  String get socialMissionsTitle => 'सामाजिक मिशन';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileAccountDetails => 'खाता विवरण';

  @override
  String get profileReferredBy => 'रेफर किया गया';

  @override
  String get profileMyReferrals => 'मेरे रेफरल';

  @override
  String get profileSocialProfiles => 'सत्यापन के लिए सोशल प्रोफ़ाइल';

  @override
  String get profileDiscord => 'Discord उपयोगकर्ता नाम';

  @override
  String get profileTelegram => 'Telegram उपयोगकर्ता ID (संख्यात्मक)';

  @override
  String get profileTelegramHint => 'जैसे: 123456789';

  @override
  String get profileX => 'X (Twitter) हैंडल';

  @override
  String get profileFacebook => 'Facebook प्रोफ़ाइल लिंक/ID';

  @override
  String get profileWhatsapp => 'WhatsApp नंबर';

  @override
  String get profileSaveSocialIds => 'सोशल ID सहेजें';

  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई!';

  @override
  String get profileSettings => 'सेटिंग';

  @override
  String get profileAppearance => 'दिखावट';

  @override
  String get profileThemeSystem => 'सिस्टम';

  @override
  String get profileThemeLight => 'हल्का';

  @override
  String get profileThemeDark => 'गहरा';

  @override
  String get profilePayoutHistory => 'भुगतान इतिहास';

  @override
  String get profileChangePassword => 'पासवर्ड बदलें';

  @override
  String get profileLanguage => 'भाषा';

  @override
  String get profileLogout => 'लॉग आउट';

  @override
  String get profileDeleteAccount => 'खाता हटाएं';

  @override
  String get profileDiscordHint => 'अपना Discord उपयोगकर्ता नाम दर्ज करें';

  @override
  String get profileVerified =>
      'सत्यापित। संपादन के लिए 🔒 टैप करें (पुरस्कार रद्द होगा)।';

  @override
  String get profileVerifiedLockedHint =>
      'Verified and reward locked. Edit the ID and tap Save; you will be asked to confirm reward removal until the new ID is verified.';

  @override
  String get profileSocialChangeTitle => 'Change verified social ID?';

  @override
  String get profileSocialChangeBody =>
      'Changing this social ID will remove your current reward until the new ID is verified. Do you want to continue?';

  @override
  String get profileSocialChangeConfirm => 'Continue';

  @override
  String get changePasswordTitle => 'पासवर्ड बदलें';

  @override
  String get changePasswordCurrent => 'वर्तमान पासवर्ड';

  @override
  String get changePasswordNew => 'नया पासवर्ड';

  @override
  String get changePasswordConfirm => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get changePasswordMin6 => 'न्यूनतम 6 अक्षर';

  @override
  String get changePasswordMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get changePasswordSuccess => 'पासवर्ड सफलतापूर्वक बदला गया!';

  @override
  String get deleteAccountTitle => 'खाता हटाएं?';

  @override
  String get deleteAccountMessage =>
      'यह क्रिया स्थायी है और इसे पूर्ववत नहीं किया जा सकता।\n\nआपकी सभी माइनिंग प्रगति, शेष और रेफरल हमेशा के लिए खो जाएंगे।';

  @override
  String get deleteAccountConfirm => 'स्थायी रूप से हटाएं';

  @override
  String deleteAccountFailed(String error) {
    return 'हटाने में विफल: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return '$platform ID संपादित करें?';
  }

  @override
  String get resetSocialMessage =>
      'सत्यापित सोशल ID बदलने से नई ID सत्यापित होने तक 1,00,000 कातोशी मिशन पुरस्कार रद्द हो जाएगा।\n\nक्या आप जारी रखना चाहते हैं?';

  @override
  String get resetSocialUnlocked => 'ID संपादन के लिए अनलॉक कर दिया गया।';

  @override
  String resetSocialFailed(String error) {
    return 'अनलॉक विफल: $error';
  }

  @override
  String get languageSelectTitle => 'भाषा चुनें';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageChinese => '中文';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get languageOdia => 'ଓଡ଼િଆ';

  @override
  String get telegramHelpTitle => 'अपना Telegram ID कैसे खोजें';

  @override
  String get telegramHelpStep1 => 'Telegram खोलें और @userinfobot खोजें';

  @override
  String get telegramHelpStep2 => 'बॉट के साथ चैट शुरू करें';

  @override
  String get telegramHelpStep3 => 'बॉट आपका संख्यात्मक उपयोगकर्ता ID भेजेगा';

  @override
  String get missionComplete => 'पूरा करें';

  @override
  String get missionCompleted => 'पूर्ण';

  @override
  String get missionClaim => 'दावा करें';

  @override
  String get missionClaimed => 'दावा हो गया';

  @override
  String get missionGo => 'जाएं';

  @override
  String failedPickImage(String error) {
    return 'फ़ोटो चुनने में विफल: $error';
  }

  @override
  String get awardsNoAwards => 'आपने अभी तक कोई पुरस्कार नहीं जीता है।';

  @override
  String get awardsKeepMining => 'माइनिंग जारी रखें और लीडरबोर्ड पर आगे बढ़ें!';

  @override
  String get balanceSummary => 'सारांश';

  @override
  String get balanceEarnings => 'कमाई';

  @override
  String get balancePayouts => 'भुगतान';

  @override
  String get balanceLoadError => 'शेष विवरण लोड करने में विफल।';

  @override
  String get balanceWithdrawSoon => 'जुड़े रहें — निकासी जल्द ही सक्रिय होगी!';

  @override
  String get balanceTotal => 'कुल शेष';

  @override
  String get balanceNotWithdrawable => 'निकासी योग्य नहीं';

  @override
  String get balanceBreakdown => 'कमाई का विवरण';

  @override
  String get balanceMining => 'माइनिंग कमाई';

  @override
  String get balanceReferral => 'रेफरल कमाई';

  @override
  String get balanceMission => 'मिशन कमाई';

  @override
  String get balanceGame => 'गेम कमाई';

  @override
  String get balanceWithdraw => 'निकासी';

  @override
  String get balanceWithdrawSubmitted => 'निकासी अनुरोध सबमिट हो गया!';

  @override
  String get balanceNoHistory => 'कमाई का कोई इतिहास नहीं।';

  @override
  String get balanceNoPayouts => 'भुगतान का कोई इतिहास नहीं।';

  @override
  String get boostersActiveModifiers => 'सक्रिय संशोधक';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'वर्तमान रेफरल बोनस: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'उपलब्ध संशोधक';

  @override
  String get boostersApplyExtensions =>
      'अपने वर्तमान माइनिंग सत्र के लिए समय विस्तार और रेफरल बोनस लागू करें।';

  @override
  String get boostersStartMiningPrompt =>
      'संशोधकों को अनलॉक करने के लिए डैशबोर्ड पर माइनिंग शुरू करें!';

  @override
  String get boostersNoBoosters => 'अभी कोई बूस्टर उपलब्ध नहीं है।';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return '$hours घंटे समय बूस्ट';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'कूलडाउन: $duration';
  }

  @override
  String get boostersSessionMaxed => 'सत्र 24 घंटे की अधिकतम सीमा पर है।';

  @override
  String boostersExtendBy(Object hours) {
    return 'सत्र $hours घंटे बढ़ाएं (अधिकतम क्षमता)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return 'सत्र $hours घंटे बढ़ाएं';
  }

  @override
  String get boostersApply => 'लागू करें';

  @override
  String boostersReferralBoosting(Object boost) {
    return 'आपकी गति बढ़ा रहा है! (सक्रिय) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'रेफरल क्षमता पूर्ण है।';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return 'सक्रिय माइनर! +$boost% बोनस प्राप्त करें।';
  }

  @override
  String get boostersActive => 'सक्रिय';

  @override
  String get boostersErrorMustMine => 'आपको पहले माइनिंग शुरू करनी होगी!';

  @override
  String get boostersEnergyPotionConsumed =>
      'एनर्जी पोटशन सफलतापूर्वक उपयोग किया गया!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'सत्र विस्तार विफल: $error';
  }

  @override
  String get boostersReferralActivated => 'रेफरल बूस्ट सफलतापूर्वक सक्रिय हुआ!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => 'दौड़ें, कूदें और कातोशी कमाएं!';

  @override
  String get gamesTictactoeTitle => 'Tic Tac Toe';

  @override
  String get gamesTictactoeDesc => 'Get three in a row to win!';

  @override
  String get gamesSudokuTitle => 'Sudoku';

  @override
  String get gamesSudokuDesc => 'Fill the grid with numbers 1-9.';

  @override
  String gameSudokuScore(Object score) {
    return 'Score: $score';
  }

  @override
  String gameSudokuMistakes(Object mistakes) {
    return 'Mistakes: $mistakes/3';
  }

  @override
  String gameSudokuStreak(Object streak) {
    return 'Streak $streak';
  }

  @override
  String get gameSudokuLevelEasy => 'Easy';

  @override
  String get gameSudokuLevelMedium => 'Medium';

  @override
  String get gameSudokuLevelHard => 'Hard';

  @override
  String get gameSudokuLevelExpert => 'Expert';

  @override
  String get gameSudokuUndo => 'Undo';

  @override
  String get gameSudokuErase => 'Erase';

  @override
  String get gameSudokuPencil => 'Pencil';

  @override
  String get gameSudokuFastPencil => 'Fast Pencil';

  @override
  String get gameSudokuHint => 'Hint';

  @override
  String get gamesCollageTitle => 'Image Collage';

  @override
  String get gamesCollageDesc => 'Arrange the cat pieces to solve the puzzle.';

  @override
  String get gamesArrowTitle => 'Arrow Reaction';

  @override
  String get gamesArrowDesc =>
      'Tap or swipe the matching direction before time runs out!';

  @override
  String gameArrowScore(Object current, Object target) {
    return 'Score $current/$target';
  }

  @override
  String gameArrowLives(Object lives) {
    return 'Lives $lives';
  }

  @override
  String get gameArrowGameOver => 'Game Over';

  @override
  String gameArrowFinalScore(Object score) {
    return 'Final score: $score';
  }

  @override
  String gameArrowSuccess(Object amount) {
    return 'Sharp reflexes! You earned $amount Catoshi!';
  }

  @override
  String get gamesTwenty48Title => '2048';

  @override
  String get gamesTwenty48Desc =>
      'Combine tiles, hit 2048 — keep going for higher scores!';

  @override
  String get gamesTileSwapTitle => 'Tile Swap';

  @override
  String get gamesTileSwapDesc =>
      'Drag a tile onto an adjacent one to swap. Match three or more to clear. Invalid swaps bounce back. Reach the goal before moves run out.';

  @override
  String gameTileSwapHudScore(Object score) {
    return 'Score $score';
  }

  @override
  String gameTileSwapHudMoves(Object moves) {
    return 'Moves $moves';
  }

  @override
  String gameTileSwapHudTarget(Object target) {
    return 'Goal $target';
  }

  @override
  String gameTileSwapSuccess(Object amount) {
    return 'Goal reached! You earned $amount Catoshi!';
  }

  @override
  String gameTileSwapLossBody(Object score, Object target) {
    return 'Score $score — goal was $target. Try again!';
  }

  @override
  String get gameTwenty48Score => 'SCORE';

  @override
  String get gameTwenty48Best => 'BEST TILE';

  @override
  String get gameTwenty48Reached2048 =>
      '2048 reached â€” keep merging for a bigger payout at game over!';

  @override
  String get gameTwenty48GameOver => 'No more moves!';

  @override
  String get gameTwenty48Restart => 'RESTART';

  @override
  String get gameTwenty48SwipeHint =>
      'Swipe up, down, left or right to slide tiles.';

  @override
  String get gameTwenty48ExitTitle => 'Leave 2048?';

  @override
  String get gameTwenty48ExitBody =>
      'Your progress is saved automatically. You can continue this game later from the games menu.';

  @override
  String get gameTwenty48Stay => 'Keep playing';

  @override
  String get gameTwenty48Leave => 'Exit';

  @override
  String get gameSudokuExitTitle => 'Leave Sudoku?';

  @override
  String get gameSudokuExitBody =>
      'Your progress is saved automatically. You can continue this game later from the games menu.';

  @override
  String get gameCollageExitTitle => 'Leave the collage puzzle?';

  @override
  String get gameCollageExitBody =>
      'Your progress is saved automatically. You can continue this puzzle later from the games menu.';

  @override
  String gameTwenty48Success(Object amount) {
    return 'You earned $amount Catoshi!';
  }

  @override
  String get gameTwenty48KeepGoing =>
      'Keep playing for an even higher score before the board fills up.';

  @override
  String get gamesComingSoon => 'जल्द आ रहा है...';

  @override
  String get referralsTitle => 'रेफरल';

  @override
  String get referralsInvitedBy => 'इनके द्वारा आमंत्रित';

  @override
  String get referralsNoOneYet => 'अभी तक कोई नहीं';

  @override
  String get referralsYourCode => 'आपका रेफरल कोड';

  @override
  String get referralsCopied => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String referralsShareMessage(Object code) {
    return 'कैटकॉइन PoE पर मेरे साथ जुड़ें! बोनस पाने के लिए मेरा कोड $code उपयोग करें।\n\nलिंक: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'कुल';

  @override
  String get referralsActiveCount => 'सक्रिय';

  @override
  String get referralsBoostPercentage => 'बूस्ट %';

  @override
  String get referralsYourReferrals => 'आपके रेफरल';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'सक्रिय (पिछले 24 घंटे)';

  @override
  String get referralsInactive => 'निष्क्रिय';

  @override
  String get referralsEnterInviterCode => 'आमंत्रित करने वाले का कोड दर्ज करें';

  @override
  String get referralsInviterCodeInstruction =>
      'यदि आपको किसी ने आमंत्रित किया है, तो अपना खाता उनके साथ जोड़ने के लिए उनका रेफरल कोड यहाँ दर्ज करें।';

  @override
  String get referralsInviterCodeLabel => 'रेफरल कोड';

  @override
  String get referralsInviterCodeUpdated =>
      'आमंत्रण कोड सफलतापूर्वक अपडेट हुआ!';

  @override
  String get referralsPingAll => 'Ping inactive referrals';

  @override
  String get referralsPingConfirmTitle => 'Ping inactive referrals?';

  @override
  String get referralsPingConfirmMessage =>
      'Creates in-app reminder records only for referrals who have not opened the app recently (same inactive rule as admin tools). Not a device push. You can do this about once per hour.';

  @override
  String referralsPingResult(
      Object pinged, Object skipped, Object failed, Object total) {
    return 'Pinged: $pinged, skipped: $skipped, failed: $failed (of $total)';
  }

  @override
  String get referralMilestoneBonusTitle => 'रेफरल माइलस्टोन बोनस';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'प्रति आमंत्रण $amount कैटोशी का एक बार का पुरस्कार';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'यह राशि सर्वर पर कॉन्फ़िगर की जाती है और प्रशासक इसे अपडेट कर सकते हैं।';

  @override
  String get referralBonusDetailAppTitle => 'रेफरल बोनस';

  @override
  String get referralBonusStatusHeading => 'रेफरल बोनस की स्थिति';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'आपके लिए (रेफ़रर): $amount कैटोशी';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'रिवॉर्ड पहले ही जोड़ दिया गया ($amount कैटोशी)।';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '3 में से $met शर्तें पूरी';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'रेफरल बोनस: $amount कैटोशी';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'जुड़े $joined · रेफ़र किए गए $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'माइनिंग के दिन';

  @override
  String get referralBonusConditionMiningReward => 'माइनिंग रिवॉर्ड (बेस)';

  @override
  String get referralBonusConditionGameReward => 'गेम रिवॉर्ड';

  @override
  String get referralBonusStatePending => 'शर्तें लंबित';

  @override
  String get referralBonusStateEligible => 'रिवॉर्ड के लिए योग्य';

  @override
  String get referralBonusStateRewarded => 'रिवॉर्ड जमा हो गया';

  @override
  String get referralBonusStateUnderReview => 'एडमिन समीक्षा में';

  @override
  String get referralBonusStateRejected => 'अस्वीकृत';

  @override
  String get profileSetupSkip => 'छोड़ें';

  @override
  String get profileSetupGallery => 'गैलरी';

  @override
  String get profileSetupCamera => 'कैमरा';

  @override
  String profileSetupFailedImage(Object error) {
    return 'फ़ोटो चुनने में विफल: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'दिखाया जाने वाला नाम (वैकल्पिक)';

  @override
  String get profileSetupDisplayNameHint => 'हम आपको क्या कहकर बुलाएं?';

  @override
  String get profileSetupSaveContinue => 'सहेजें और आगे बढ़ें';

  @override
  String profileSetupFailedSave(Object error) {
    return 'प्रोफ़ाइल सहेजने में विफल: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return 'अभी कोई $title उपलब्ध नहीं है।';
  }

  @override
  String get payoutHistoryScreenTitle => 'भुगतान इतिहास';

  @override
  String get payoutNoHistory => 'कोई भुगतान इतिहास नहीं मिला।';

  @override
  String get payoutViewTx => 'TX देखें';

  @override
  String payoutAddressTo(Object address) {
    return 'को: $address';
  }

  @override
  String get commonAdd => 'जोड़ें';

  @override
  String get commonEdit => 'संपादित करें';

  @override
  String get missionVerifyTitle => 'सत्यापन आवश्यक';

  @override
  String get missionVerifyDiscord =>
      'अपना डिस्कॉर्ड उपयोगकर्ता नाम दर्ज करें ताकि हम सत्यापित कर सकें कि आप शामिल हुए हैं:';

  @override
  String get missionVerifyTelegram =>
      'अपनी संख्यात्मक टेलीग्राम आईडी दर्ज करें:';

  @override
  String get missionVerifyGeneric =>
      'सत्यापित करने के लिए अपना उपयोगकर्ता नाम/हैंडल दर्ज करें:';

  @override
  String get missionHintDiscord => 'डिस्कॉर्ड उपयोगकर्ता नाम दर्ज करें';

  @override
  String get missionHintTelegram => 'संख्यात्मक आईडी दर्ज करें';

  @override
  String get missionHintGeneric => 'उपयोगकर्ता नाम/हैंडल दर्ज करें';

  @override
  String get missionHelpGetId => 'आईडी कैसे प्राप्त करें?';

  @override
  String get missionSaveContinue => 'सहेजें और आगे बढ़ें';

  @override
  String get missionVerificationStarted =>
      'सत्यापन शुरू! कृपया कार्य पूरा करें।';

  @override
  String missionClaimedSuccess(Object amount) {
    return 'दावा किया गया $amount Catoshi!';
  }

  @override
  String missionFailed(Object error) {
    return 'विफल: $error';
  }

  @override
  String get missionExpired => 'समय समाप्त';

  @override
  String missionExpiresInDays(Object days) {
    return '$days दिनों में समाप्त हो रहा है';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return '$hours घंटों में समाप्त हो रहा है';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'सत्यापित किया जा रहा है...';

  @override
  String get missionBtnClaim => 'दावा करें';

  @override
  String get telegramHelpInstructions =>
      '1. टेलीग्राम खोलें।\n2. @userinfobot खोजें (या नीचे क्यूआर स्कैन करें)।\n3. स्टार्ट पर क्लिक करें (या /start भेजें)।\n4. यह आपके विवरण के साथ उत्तर देगा। \"Id\" देखें।\n5. उस नंबर को कॉपी करें और यहां पेस्ट करें।';

  @override
  String get telegramHelpBtnOpen => 'खोलें @userinfobot';

  @override
  String get telegramHelpQrLabel => 'या क्यूआर कोड स्कैन करें:';

  @override
  String get telegramHelpQrError =>
      'क्यूआर कोड नहीं मिला।\n(assets/images/telegram_qr.png जोड़ें)';

  @override
  String get resetPasswordSuccess =>
      'पासवर्ड सफलतापूर्वक रीसेट हो गया। कृपया लॉगिन करें।';

  @override
  String get resetPasswordFailed => 'पासवर्ड रीसेट करने में विफल';

  @override
  String resetPasswordInstruction(Object email) {
    return '$email पर भेजा गया 6-अंकीय कोड और अपना नया पासवर्ड दर्ज करें।';
  }

  @override
  String get emailVerificationCodeSent =>
      'सत्यापन कोड आपके ईमेल पर भेज दिया गया है!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => 'गेम एसेट्स डाउनलोड हो रहे हैं...';

  @override
  String get gameLauncherReady => 'इंजन तैयार है';

  @override
  String get gameLauncherRequired => 'गेम एसेट्स आवश्यक हैं';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'एसेट्स डाउनलोड करें (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'गेम शुरू करें';

  @override
  String get gameLauncherResetBtn => 'एसेट्स रीसेट करें';

  @override
  String get gameNewGame => 'नया खेल';

  @override
  String get gameYouWin => 'आपकी जीत!';

  @override
  String get gameCpuWins => 'कंप्यूटर की जीत';

  @override
  String get gameDraw => 'ड्रॉ!';

  @override
  String get gameYourTurnX => 'आपकी बारी (X)';

  @override
  String get gameYourTurnO => 'कंप्यूटर की बारी (O)';

  @override
  String gameWinReward(Object amount) {
    return 'Win $amount Catoshi';
  }

  @override
  String gameSudokuSuccess(Object amount) {
    return 'बहुत बढ़िया! आपने सुडोकू हल किया और $amount catoshi कमाए!';
  }

  @override
  String get gameRewardBoostBonusTitle => 'Bonus Game Boost';

  @override
  String gameRewardBoostBonusBody(Object percentage, Object minutes) {
    return '+$percentage% mining yield for $minutes minutes. Open Boosters to activate while mining.';
  }

  @override
  String gameRewardRunnerSummary(Object amount) {
    return 'You earned $amount Catoshi!';
  }

  @override
  String gameTictactoeSuccess(Object amount) {
    return 'बधाई हो! आपने $amount catoshi कमाए!';
  }

  @override
  String gamePuzzleSuccess(Object amount) {
    return 'शानदार! आपने पहेली हल की और $amount catoshi कमाए!';
  }

  @override
  String get gameMinerTitle => 'CatCoin Miner';

  @override
  String get gamesTunnelMinerTitle => 'Tunnel Miner';

  @override
  String get gamesTunnelMinerDesc =>
      'Mine downward, reach the green extraction pad, and avoid hazards.';

  @override
  String gameRewardMinerSummary(Object amount) {
    return 'You earned $amount Catoshi!';
  }

  @override
  String get tunnelMinerHudDepth => 'Depth';

  @override
  String get tunnelMinerHudEnergy => 'Energy';

  @override
  String get tunnelMinerHudShards => 'Shards';

  @override
  String get tunnelMinerDigHint => 'Dig';

  @override
  String get tunnelMinerLoading => 'Loading Tunnel Miner...';

  @override
  String get tunnelMinerIntroTitle => 'Tunnel Miner';

  @override
  String get tunnelMinerHowToPlayTitle => 'How to play';

  @override
  String get tunnelMinerGoal =>
      'Descend the tunnel, dig through brown dirt, collect gold ore, and stand on the green extraction pad to finish successfully. Loose dirt, ore, and lava fall downward through air while grey rock stays put. Hazards or running out of energy ends the run.';

  @override
  String get tunnelMinerDoHeading => 'What to do';

  @override
  String get tunnelMinerDoBody =>
      '• Move left or right into open space: air, gold ore, or the green extraction pad.\n• Dig straight down through brown dirt only. Each dig uses drill energy.\n• Walk onto ore to collect shards (they add to your score).\n• Reach and stand on the green extraction pad to complete a good run.\n• Brown dirt or grey rock beside you? Press left or right toward it again to mine sideways (grey rock costs double energy).';

  @override
  String get tunnelMinerDontHeading => 'What not to do';

  @override
  String get tunnelMinerDontBody =>
      '• Do not step on red lava — you lose immediately.\n• Do not stand under loose dirt, ore, or lava when there is only air beneath them — they fall; grey rock does not move and acts as a shelf. Falling ore is usually collectible; dirt or lava landing on you ends the run.\n• Do not try to dig grey rock — it cannot be broken; move around it.\n• Do not spend all energy — when energy reaches zero, the run ends.';

  @override
  String get tunnelMinerControlsHeading => 'Controls';

  @override
  String get tunnelMinerControlsBody =>
      'Bottom row: move left, dig down, move right.\nYou can also tap the left third, center, or right third of the mine area for the same actions.\nToward brown dirt or grey rock on your side, tap that direction again to chip through (grey rock uses extra energy).\nKeyboard: A or Left Arrow, D or Right Arrow to move; Space, S, or Down Arrow to dig.\nPause: tap the pause icon at the top.';

  @override
  String get tunnelMinerIntroTap =>
      'Read the notes above, then tap Start when you are ready.';

  @override
  String get tunnelMinerStartButton => 'Start mining';

  @override
  String get tunnelMinerWhatHappened => 'What happened';

  @override
  String get tunnelMinerLossExplainLava => 'You stepped on or fell into lava.';

  @override
  String get tunnelMinerLossExplainBoulder => 'Something heavy fell on you.';

  @override
  String get tunnelMinerLossExplainEnergy => 'Your drill ran out of power.';

  @override
  String get tunnelMinerLossExplainUnknown =>
      'The run ended before extraction.';

  @override
  String get tunnelMinerReviewMap => 'Review map';

  @override
  String get tunnelMinerBackToSummary => 'Back to summary';

  @override
  String get tunnelMinerMapReviewHint =>
      'Study the field. Return to the summary for Play again or Exit.';

  @override
  String get tunnelMinerResultExtracted => 'EXTRACTED';

  @override
  String get tunnelMinerResultReason => 'Outcome';

  @override
  String get tunnelMinerReasonEnergy => 'Drill out of power';

  @override
  String get tunnelMinerReasonHazard => 'Hazard';

  @override
  String get tunnelMinerReasonExtracted => 'Reached extraction';

  @override
  String get gameGameOverTitle => 'खेल समाप्त';

  @override
  String get gameStatScore => 'स्कोर';

  @override
  String get gameStatDistance => 'दूरी';

  @override
  String get gameStatCoins => 'सिक्के';

  @override
  String get gameStatCatoshiEarned => 'अर्जित कैटोशी';

  @override
  String get gamePlayAgain => 'फिर से खेलें';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'बाहर निकलें';

  @override
  String get gamePausedTitle => 'रुका हुआ';

  @override
  String get gameResume => 'जारी रखें';

  @override
  String get gameQuit => 'छोड़ें';

  @override
  String get updateTitle => 'अपडेट उपलब्ध है';

  @override
  String get updateLater => 'बाद में';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get updateUrlError => 'अपडेट URL लॉन्च नहीं किया जा सका';

  @override
  String balancePayoutTo(Object address) {
    return 'को: $address';
  }

  @override
  String get boostersSubtitle =>
      'अपनी माइनिंग गति को तेज करें और सत्रों को बढ़ाएं!';

  @override
  String get commonVersion => 'संस्करण';

  @override
  String get commonUser => 'उपयोगकर्ता';

  @override
  String get profileVerifiedTooltip =>
      'सत्यापित। अनलॉक करने और संपादित करने के लिए टैप करें।';

  @override
  String walletAddressLabel(Object address) {
    return 'पता: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'जेनरेशन त्रुटि: $error';
  }

  @override
  String get walletDeleteWallet => 'वॉलेट हटाएं';

  @override
  String get commonGenerate => 'जेनरेट करें';

  @override
  String get badgeWeeklyTop => 'साप्ताहिक टॉप';

  @override
  String get badgeMonthlyTop => 'मासिक टॉप';

  @override
  String get badgeAllTimeTop => 'सर्वकालिक टॉप';

  @override
  String get badgeVerified => 'सत्यापित उपयोगकर्ता';

  @override
  String get badgeMonthlyGlobalPodium => 'Monthly global podium';

  @override
  String get badgeMonthlyRegionalPodium => 'Monthly regional podium';

  @override
  String get badgeMonthlyGamePodium => 'Monthly game champion';

  @override
  String get awardDetailTitle => 'Award details';

  @override
  String get awardDetailMonthLabel => 'Month achieved';

  @override
  String get awardDetailTypeLabel => 'Award type';

  @override
  String get awardDetailHowLabel => 'How it was achieved';

  @override
  String get awardDetailHowFallback =>
      'Details for this award were not stored. Contact support if this looks wrong.';

  @override
  String awardDetailRankScope(int rank, String scope) {
    return 'Rank $rank · $scope';
  }

  @override
  String get awardDetailScopeGlobal => 'Global';

  @override
  String get awardDetailScopeRegional => 'Regional';

  @override
  String get awardDetailScopeGame => 'Games';

  @override
  String awardDetailRegion(String code) {
    return 'Region: $code';
  }

  @override
  String awardDetailGame(String name) {
    return 'Game: $name';
  }

  @override
  String awardsPrevMonthPeriod(String month) {
    return 'Previous month ($month)';
  }

  @override
  String get awardsPrevMonthGlobal => 'Global top miners';

  @override
  String get awardsPrevMonthRegional => 'Regional top miners (your country)';

  @override
  String get awardsPrevMonthGames => 'Game champions';

  @override
  String get profileShowcaseTitle => 'Showcase badges';

  @override
  String get profileShowcaseSubtitle =>
      'Pick up to 6 earned awards to show on your profile.';

  @override
  String get profileShowcaseManage => 'Choose badges';

  @override
  String get profileShowcaseEmpty => 'No badges on showcase yet.';

  @override
  String get profileShowcaseMax => 'You can showcase at most 6 badges.';

  @override
  String get profileShowcaseSave => 'Save showcase';

  @override
  String get awardDetailClose => 'Close';

  @override
  String updateAvailable(Object version) {
    return 'एक नया संस्करण ($version) उपलब्ध है।';
  }

  @override
  String get updateMandatory =>
      'ऐप का उपयोग जारी रखने के लिए यह अपडेट अनिवार्य है।';

  @override
  String boostersGameBoostTitle(String percentage) {
    return 'Game Boost +$percentage%';
  }

  @override
  String boostersGameBoostDuration(String hours, String minutes) {
    return 'Duration: ${hours}h ${minutes}m';
  }

  @override
  String get boostersActivate => 'Activate';

  @override
  String get boostersGameBoostSuccess => 'Game Boost activated successfully!';

  @override
  String boostersGameBoostError(String error) {
    return 'Failed to activate boost: $error';
  }

  @override
  String get languageGroupInternational => 'अंतर्राष्ट्रीय';

  @override
  String get languageGroupIndian => 'भारत';
}
