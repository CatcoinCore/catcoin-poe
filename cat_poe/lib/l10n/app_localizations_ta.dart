// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'விளையாட்டுகள்';

  @override
  String get navLeaders => 'தலைவர்கள்';

  @override
  String get navWallet => 'பணப்பை';

  @override
  String get navRewards => 'வெகுமதிகள்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonError => 'பிழை';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'ஏற்றுகிறது...';

  @override
  String get commonRetry => 'மீண்டும் முயற்சி';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonNone => 'எதுவும் இல்லை';

  @override
  String get commonGallery => 'தொகுப்பு';

  @override
  String get commonCamera => 'கேமரா';

  @override
  String get commonRemovePhoto => 'புகைப்படம் நீக்கு';

  @override
  String get commonRequired => 'அவசியம்';

  @override
  String get commonUnlockEdit => 'திறந்து திருத்து';

  @override
  String get loginTitle => 'உள்நுழை';

  @override
  String get loginEmailOrUsername => 'மின்னஞ்சல் அல்லது பயனர் பெயர்';

  @override
  String get loginEmailHint => 'your.email@example.com அல்லது 900123456';

  @override
  String get loginPassword => 'கடவுச்சொல்';

  @override
  String get loginButton => 'உள்நுழை';

  @override
  String get loginCreateAccount => 'கணக்கு உருவாக்கு';

  @override
  String get loginForgotPassword => 'கடவுச்சொல் மறந்தீர்களா?';

  @override
  String get loginUseEmailForVerification =>
      'சரிபார்ப்பை முடிக்க மின்னஞ்சல் மூலம் உள்நுழையவும்.';

  @override
  String get signupTitle => 'பதிவு செய்';

  @override
  String get signupEmail => 'மின்னஞ்சல்';

  @override
  String get signupEmailHint => 'your.email@example.com';

  @override
  String get signupPassword => 'கடவுச்சொல்';

  @override
  String get signupConfirmPassword => 'கடவுச்சொல் உறுதிப்படுத்தவும்';

  @override
  String get signupReferralCode => 'பரிந்துரை குறியீடு (விருப்பத்தேர்வு)';

  @override
  String get signupReferralCodeHint =>
      'பரிந்துரை குறியீடு இருந்தால் உள்ளிடவும்';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'பதிவு செய்';

  @override
  String get forgotPasswordTitle => 'கடவுச்சொல் மறந்தது';

  @override
  String get forgotPasswordEmail => 'மின்னஞ்சல்';

  @override
  String get forgotPasswordSendCode => 'மீட்டமை குறியீடு அனுப்பு';

  @override
  String get forgotPasswordBackToLogin => 'உள்நுழைவுக்கு திரும்பு';

  @override
  String get emailVerificationTitle => 'மின்னஞ்சல் சரிபார்ப்பு';

  @override
  String get emailVerificationInstruction =>
      'இங்கு அனுப்பப்பட்ட சரிபார்ப்பு குறியீட்டை உள்ளிடவும்';

  @override
  String get emailVerificationCode => 'சரிபார்ப்பு குறியீடு';

  @override
  String get emailVerificationVerify => 'சரிபார்';

  @override
  String get emailVerificationResend => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get resetPasswordTitle => 'கடவுச்சொல் மீட்டமை';

  @override
  String get resetPasswordNewPassword => 'புதிய கடவுச்சொல்';

  @override
  String get resetPasswordConfirm => 'புதிய கடவுச்சொல் உறுதிப்படுத்தவும்';

  @override
  String get resetPasswordButton => 'கடவுச்சொல் மீட்டமை';

  @override
  String get profileSetupTitle => 'சுயவிவர அமைவு';

  @override
  String get splashLoading => 'ஏற்றுகிறது...';

  @override
  String get dashboardTotalBalance => 'மொத்த இருப்பு';

  @override
  String get dashboardCatoshi => 'காட்டோஷி';

  @override
  String get dashboardCatoshiLabel => 'காட்டோஷி';

  @override
  String get dashboardNotMining => 'சுரங்கம் இல்லை';

  @override
  String get dashboardStartMining => 'சுரங்கம் தொடங்கு';

  @override
  String dashboardRewardRate(Object rate) {
    return 'வெகுமதி விகிதம்: $rate கேடோஷி/விநாடி';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'தற்போதைய காலம்: ${hours}h / அதிகபட்சம் ${maxHours}h';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'பூஸ்டர்கள்';

  @override
  String get boostersCardTitle => 'ஊக்கிகள்';

  @override
  String get boostersCardDescription =>
      'உங்கள் சுரங்க வேகத்தை அதிகரிக்கவும் மற்றும் அமர்வுகளை நீட்டிக்கவும்!';

  @override
  String get boostersOpenScreen => 'ஊக்கிகள் பார்';

  @override
  String get leaderboardTitle => 'தலைவர் பலகை';

  @override
  String get leaderboardTopMiners => 'சிறந்த சுரங்கத்தொழிலாளர்கள்';

  @override
  String get leaderboardRank => 'தரவரிசை';

  @override
  String get leaderboardUser => 'பயனர்';

  @override
  String get leaderboardBalance => 'இருப்பு';

  @override
  String get leaderboardYou => 'நீங்கள்';

  @override
  String get leaderboardGlobal => 'உலகளாவிய';

  @override
  String get leaderboardRegional => 'மண்டல';

  @override
  String get leaderboardGames => 'விளையாட்டுகள்';

  @override
  String get leaderboardAwards => 'விருதுகள்';

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
  String get leaderboardChallengers => 'சவாலளிப்பவர்கள்';

  @override
  String get leaderboardNoGlobal =>
      'உலகளாவிய சுரங்கத் தொழிலாளர்கள் எவரும் காணப்படவில்லை.';

  @override
  String get leaderboardNoRegional =>
      'மண்டல அளவிலான சுரங்கத் தொழிலாளர்கள் எவரும் காணப்படவில்லை.';

  @override
  String get leaderboardComingSoon =>
      'விரைவில் - மினி-கேம்களில் போட்டியிடுங்கள்!';

  @override
  String get leaderboardNoAwards => 'இன்னும் விருதுகள் இல்லை';

  @override
  String get leaderboardKeepMining => 'போடியத்தை கைப்பற்ற சுரங்கத்தை தொடரவும்!';

  @override
  String get walletTitle => 'பணப்பை';

  @override
  String get walletAddress => 'பணப்பை முகவரி';

  @override
  String get walletBalance => 'இருப்பு';

  @override
  String get walletCopy => 'நகலெடு';

  @override
  String get walletCopied => 'நகலெடுக்கப்பட்டது!';

  @override
  String get walletSend => 'அனுப்பு';

  @override
  String get walletReceive => 'பெறு';

  @override
  String get walletTransactions => 'பரிவர்த்தனைகள்';

  @override
  String get walletNoTransactions => 'இன்னும் பரிவர்த்தனைகள் இல்லை';

  @override
  String get walletConnectWallet => 'பணப்பையை இணை';

  @override
  String get walletDisconnect => 'துண்டிக்க';

  @override
  String get walletSolanaAddress => 'சோலானா முகவரி';

  @override
  String get walletEnterAddress => 'சோலானா முகவரியை உள்ளிடவும்';

  @override
  String get walletSaveAddress => 'முகவரியை சேமி';

  @override
  String get walletAddressSaved => 'முகவரி சேமிக்கப்பட்டது!';

  @override
  String get walletInvalidAddress => 'தவறான சோலானா முகவரி';

  @override
  String get walletMyWallets => 'எனது வாலெட்டுகள்';

  @override
  String get walletAddExisting => 'ஏற்கனவே உள்ள முகவரியைச் சேர்';

  @override
  String get walletCatcoinAddress => 'கேட்காயின் முகவரி';

  @override
  String get walletPasteHint => 'முகவரியை இங்கே ஒட்டவும்';

  @override
  String get walletSetPrimary => 'முதன்மை முகவரியாக அமை';

  @override
  String get walletInvalidAddressComplex =>
      'செல்லாத முகவரி. சரியான BEP20 (0x...), சோலானா அல்லது கேட்காயின் (9 இல் தொடங்கும்) முகவரியாக இருக்க வேண்டும்.';

  @override
  String get walletRecoverTitle => 'வாலெட்டை மீட்டெடுக்கவும்';

  @override
  String get walletRecoverInstruction =>
      'உங்கள் வாலெட்டை மீட்டெடுக்க உங்கள் 24-வார்த்தை ரகசிய சொற்றொடரை உள்ளிடவும்.';

  @override
  String get walletSecretPhrase => 'ரகசிய சொற்றொடர்';

  @override
  String get walletSecretPhraseHint => 'வார்த்தை1 வார்த்தை2 ... வார்த்தை24';

  @override
  String get walletInvalidPhrase =>
      'செல்லாத சொற்றொடர். சரியாக 24 வார்த்தைகள் இருக்க வேண்டும்.';

  @override
  String get walletDeleteTitle => 'வாலெட்டை நீக்கு';

  @override
  String walletDeleteConfirmMessage(String address) {
    return '$address வாலெட்டை நீக்க விரும்புகிறீர்களா? உங்களிடம் ரகசிய சாவி/சொற்றொடர் இல்லையென்றால் இந்தச் செயலை மாற்ற முடியாது.';
  }

  @override
  String get walletDeletedSuccess => 'வாலெட்டு வெற்றிகரமாக நீக்கப்பட்டது';

  @override
  String get walletAddedSuccess => 'வாலெட்டு வெற்றிகரமாக சேர்க்கப்பட்டது';

  @override
  String get walletGenerateTitle => 'புதிய வாலெட்டை உருவாக்கு';

  @override
  String get walletBackupTitle =>
      'வெற்றி! உங்கள் வாலெட்டை காப்புப்பிரதி எடுக்கவும்';

  @override
  String get walletBackupWarning =>
      'முக்கியமானது: இந்த 24 வார்த்தைகளை வரிசைப்படி எழுதி பாதுகாப்பாக வைக்கவும். இவை இல்லாமல் உங்கள் நிதியை மீட்டெடுக்க முடியாது!';

  @override
  String get walletGenerateInstruction =>
      'இது உங்களுக்காக ஒரு புதிய கேட்காயின் வாலெட்டை உருவாக்கும். உருவாக்கியவுடன் உங்கள் ரகசிய சொற்றொடரை காப்புப்பிரதி எடுப்பதை உறுதி செய்யவும்!';

  @override
  String get walletGenerating => 'சாவிகள் உருவாக்கப்படுகின்றன...';

  @override
  String get walletBackedUp => 'நான் காப்புப்பிரதி எடுத்துவிட்டேன்';

  @override
  String get walletRecoverFromPhrase => 'சொற்றொடரிலிருந்து மீட்டெடு';

  @override
  String get walletSetDefault => 'இயல்புநிலையாக அமை';

  @override
  String get walletSettingPrimary => 'வாலட்டை முதன்மையாக அமைக்கிறது...';

  @override
  String get walletPrimary => 'முதன்மை';

  @override
  String get walletSourceGenerated => 'உருவாக்கப்பட்டது';

  @override
  String get walletSourceRecovered => 'மீட்டெடுக்கப்பட்டது';

  @override
  String get walletSourceManual => 'கையேடு முகவரி';

  @override
  String walletDaysHeld(String days) {
    return 'வைத்திருந்த நாட்கள்: $days';
  }

  @override
  String get walletCalculating => 'கணக்கிடப்படுகிறது...';

  @override
  String get rewardsTitle => 'வெகுமதிகள்';

  @override
  String get rewardsClaim => 'கோரு';

  @override
  String get rewardsClaimed => 'கோரப்பட்டது';

  @override
  String get rewardsAvailable => 'கிடைக்கிறது';

  @override
  String get rewardsNoRewards => 'வெகுமதிகள் இல்லை';

  @override
  String get rewardsSocialTasks => 'சமூக பணிகள்';

  @override
  String get rewardsXTasks => 'X பணிகள்';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'அனைத்து பணிகள்';

  @override
  String get rewardsNoMissions => 'செயலில் உள்ள பணிகள் எதுவும் இல்லை.';

  @override
  String rewardsError(String error) {
    return 'பிழை: $error';
  }

  @override
  String get gamesTitle => 'விளையாட்டுகள்';

  @override
  String get gamesPlay => 'விளையாடு';

  @override
  String get gamesRunner => 'பூனை ஓட்டம்';

  @override
  String get gamesRunnerDescription => 'ஓடு, தாவு, நாணயங்களை சேகரி!';

  @override
  String get gamesNoGames => 'விளையாட்டுகள் இல்லை';

  @override
  String get referralTitle => 'என் பரிந்துரைகள்';

  @override
  String get referralCode => 'உங்கள் பரிந்துரை குறியீடு';

  @override
  String get referralCopyCode => 'குறியீட்டை நகலெடு';

  @override
  String get referralShareLink => 'இணைப்பை பகிர்';

  @override
  String get referralActiveReferrals => 'செயலில் உள்ள பரிந்துரைகள்';

  @override
  String get referralNoReferrals => 'இன்னும் பரிந்துரைகள் இல்லை';

  @override
  String get referralBoost => 'ஊக்குவி';

  @override
  String get referralBoosted => 'ஊக்குவிக்கப்பட்டது';

  @override
  String get referralInviteFriends => 'நண்பர்களை அழை';

  @override
  String get balanceDetailTitle => 'இருப்பு விவரங்கள்';

  @override
  String get payoutHistoryTitle => 'பணப்பட்டியல் வரலாறு';

  @override
  String get payoutHistoryNone => 'பணப்பட்டியல் வரலாறு இல்லை';

  @override
  String get awardsTitle => 'விருதுகள்';

  @override
  String get socialMissionsTitle => 'சமூக பணிகள்';

  @override
  String get profileTitle => 'சுயவிவரம்';

  @override
  String get profileAccountDetails => 'கணக்கு விவரங்கள்';

  @override
  String get profileReferredBy => 'பரிந்துரைத்தவர்';

  @override
  String get profileMyReferrals => 'என் பரிந்துரைகள்';

  @override
  String get profileSocialProfiles => 'சரிபார்ப்புக்கான சமூக சுயவிவரங்கள்';

  @override
  String get profileDiscord => 'Discord பயனர் பெயர்';

  @override
  String get profileTelegram => 'Telegram பயனர் ID (எண்)';

  @override
  String get profileTelegramHint => 'எ.கா: 123456789';

  @override
  String get profileX => 'X (Twitter) கைப்பிடி';

  @override
  String get profileFacebook => 'Facebook சுயவிவர இணைப்பு/ID';

  @override
  String get profileWhatsapp => 'WhatsApp எண்';

  @override
  String get profileSaveSocialIds => 'சமூக IDகளை சேமி';

  @override
  String get profileUpdatedSuccess =>
      'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

  @override
  String get profileSettings => 'அமைப்புகள்';

  @override
  String get profileAppearance => 'தோற்றம்';

  @override
  String get profileThemeSystem => 'கணினி';

  @override
  String get profileThemeLight => 'ஒளி';

  @override
  String get profileThemeDark => 'இருண்ட';

  @override
  String get profilePayoutHistory => 'பணப்பட்டியல் வரலாறு';

  @override
  String get profileChangePassword => 'கடவுச்சொல் மாற்று';

  @override
  String get profileLanguage => 'மொழி';

  @override
  String get profileLogout => 'வெளியேறு';

  @override
  String get profileDeleteAccount => 'கணக்கை நீக்கு';

  @override
  String get profileDiscordHint => 'உங்கள் Discord பயனர் பெயரை உள்ளிடவும்';

  @override
  String get profileVerified =>
      'சரிபார்க்கப்பட்டது. திருத்த 🔒 தட்டவும் (வெகுமதி ரத்தாகும்).';

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
  String get changePasswordTitle => 'கடவுச்சொல் மாற்று';

  @override
  String get changePasswordCurrent => 'தற்போதைய கடவுச்சொல்';

  @override
  String get changePasswordNew => 'புதிய கடவுச்சொல்';

  @override
  String get changePasswordConfirm => 'புதிய கடவுச்சொல் உறுதிப்படுத்தவும்';

  @override
  String get changePasswordMin6 => 'குறைந்தது 6 எழுத்துக்கள்';

  @override
  String get changePasswordMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get changePasswordSuccess => 'கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது!';

  @override
  String get deleteAccountTitle => 'கணக்கை நீக்கவா?';

  @override
  String get deleteAccountMessage =>
      'இந்த செயல் நிரந்தரமானது மற்றும் மாற்ற முடியாது.\n\nஉங்கள் அனைத்து சுரங்க முன்னேற்றம், இருப்பு மற்றும் பரிந்துரைகள் என்றென்றும் இழக்கப்படும்.';

  @override
  String get deleteAccountConfirm => 'நிரந்தரமாக நீக்கு';

  @override
  String deleteAccountFailed(String error) {
    return 'நீக்கம் தோல்வியடைந்தது: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return '$platform IDஐ திருத்தவா?';
  }

  @override
  String get resetSocialMessage =>
      'சரிபார்க்கப்பட்ட சமூக IDஐ மாற்றினால் புதிய ID சரிபார்க்கப்படும் வரை 1,00,000 காட்டோஷி பணி வெகுமதி ரத்தாகும்.\n\nதொடர விரும்புகிறீர்களா?';

  @override
  String get resetSocialUnlocked => 'ID திருத்துவதற்காக திறக்கப்பட்டது.';

  @override
  String resetSocialFailed(String error) {
    return 'திறக்க தோல்வியடைந்தது: $error';
  }

  @override
  String get languageSelectTitle => 'மொழியை தேர்ந்தெடு';

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
  String get telegramHelpTitle => 'உங்கள் Telegram IDஐ எவ்வாறு கண்டுபிடிப்பது';

  @override
  String get telegramHelpStep1 => 'Telegramஐ திறந்து @userinfobot தேடவும்';

  @override
  String get telegramHelpStep2 => 'bot உடன் அரட்டை தொடங்கவும்';

  @override
  String get telegramHelpStep3 => 'bot உங்கள் எண் பயனர் IDஐ அனுப்பும்';

  @override
  String get missionComplete => 'முடி';

  @override
  String get missionCompleted => 'முடிந்தது';

  @override
  String get missionClaim => 'கோரு';

  @override
  String get missionClaimed => 'கோரப்பட்டது';

  @override
  String get missionGo => 'செல்';

  @override
  String failedPickImage(String error) {
    return 'புகைப்படம் தேர்வு தோல்வியடைந்தது: $error';
  }

  @override
  String get awardsNoAwards => 'நீங்கள் இன்னும் விருதுகள் எதையும் பெறவில்லை.';

  @override
  String get awardsKeepMining =>
      'சுரங்கப் பணிகளைத் தொடர்ந்து செய்து லீடர்போர்டில் முன்னேறுங்கள்!';

  @override
  String get balanceSummary => 'சுருக்கம்';

  @override
  String get balanceEarnings => 'வருவாய்';

  @override
  String get balancePayouts => 'கொடுப்பனவுகள்';

  @override
  String get balanceLoadError => 'இருப்பு விவரங்களை ஏற்ற முடியவில்லை.';

  @override
  String get balanceWithdrawSoon =>
      'காத்திருங்கள் — திரும்பப் பெறுதல் விரைவில் செயல்படுத்தப்படும்!';

  @override
  String get balanceTotal => 'மொத்த இருப்பு';

  @override
  String get balanceNotWithdrawable => 'திரும்பப் பெற முடியாது';

  @override
  String get balanceBreakdown => 'வருவாய் விவரம்';

  @override
  String get balanceMining => 'சுரங்க வருவாய்';

  @override
  String get balanceReferral => 'பரிந்துரை வருவாய்';

  @override
  String get balanceMission => 'மிஷன் வருவாய்';

  @override
  String get balanceGame => 'விளையாட்டு வருவாய்';

  @override
  String get balanceWithdraw => 'திரும்பப் பெறு';

  @override
  String get balanceWithdrawSubmitted =>
      'திரும்பப் பெறுவதற்கான கோரிக்கை சமர்ப்பிக்கப்பட்டது!';

  @override
  String get balanceNoHistory => 'வருவாய் வரலாறு இல்லை.';

  @override
  String get balanceNoPayouts => 'கொடுப்பனவு வரலாறு இல்லை.';

  @override
  String get boostersActiveModifiers => 'செயலில் உள்ள மாற்றிகள்';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'தற்போதைய பரிந்துரை போனஸ்: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'கிடைக்கக்கூடிய மாற்றிகள்';

  @override
  String get boostersApplyExtensions =>
      'உங்கள் தற்போதைய சுரங்க அமர்வுக்கான நேர நீட்டிப்புகள் மற்றும் பரிந்துரை போனஸ்களைப் பயன்படுத்துங்கள்.';

  @override
  String get boostersStartMiningPrompt =>
      'மாற்றிகளைத் திறக்க டாஷ்போர்டில் சுரங்கப் பணியைத் தொடங்குங்கள்!';

  @override
  String get boostersNoBoosters => 'தற்போது பூஸ்டர்கள் எதுவும் இல்லை.';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return '$hours மணி நேர பூస్ట్';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'குளிர்ச்சி நேரம்: $duration';
  }

  @override
  String get boostersSessionMaxed =>
      'அமர்வு அதிகபட்சமாக 24 மணி நேரத்தை எட்டியது.';

  @override
  String boostersExtendBy(Object hours) {
    return '$hours மணி நேரத்திற்கு நீட்டிக்கவும் (அதிகபட்ச திறன்)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return '$hours மணி நேரத்திற்கு நீட்டிக்கவும்';
  }

  @override
  String get boostersApply => 'பயன்படுத்து';

  @override
  String boostersReferralBoosting(Object boost) {
    return 'உங்கள் வேகத்தை அதிகரிக்கிறது! (செயலில்) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'பரிந்துரை திறன் முடிந்தது.';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return 'செயலில் உள்ள சுரங்கத் தொழிலாளி! +$boost% போனஸ் பெற விண்ணப்பிக்கவும்.';
  }

  @override
  String get boostersActive => 'செயலில்';

  @override
  String get boostersErrorMustMine =>
      'முதலில் நீங்கள் சுரங்கப் பணியைத் தொடங்க வேண்டும்!';

  @override
  String get boostersEnergyPotionConsumed =>
      'எனர்ஜி போஷன் வெற்றிகரமாகப் பயன்படுத்தப்பட்டது!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'அமர்வு நீட்டிப்பு தோல்வியுற்றது: $error';
  }

  @override
  String get boostersReferralActivated =>
      'பரிந்துரை பூస్ట్ வெற்றிகரமாக செயல்படுத்தப்பட்டது!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc =>
      'ஓடுங்கள், தாவுங்கள் மற்றும் காட்டோஷி சம்பாதியுங்கள்!';

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
  String get gamesComingSoon => 'விரைவில் வருகிறது...';

  @override
  String get referralsTitle => 'பரிந்துரைகள்';

  @override
  String get referralsInvitedBy => 'அழைத்தவர்';

  @override
  String get referralsNoOneYet => 'இன்னும் யாருமில்லை';

  @override
  String get referralsYourCode => 'உங்கள் பரிந்துரை குறியீடு';

  @override
  String get referralsCopied => 'கிளிப்போர்டில் நகலெடுக்கப்பட்டது';

  @override
  String referralsShareMessage(Object code) {
    return 'Catcoin PoE இல் என்னுடன் சேருங்கள்! போனஸ் பெற எனது குறியீடு $code ஐப் பயன்படுத்தவும்.\n\nஇணைப்பு: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'மொத்தம்';

  @override
  String get referralsActiveCount => 'செயலில்';

  @override
  String get referralsBoostPercentage => 'பூஸ்ட் %';

  @override
  String get referralsYourReferrals => 'உங்கள் பரிந்துரைகள்';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'செயலிலுள்ளவர் (கடந்த 24 மணிநேரம்)';

  @override
  String get referralsInactive => 'செயலற்றவர்';

  @override
  String get referralsEnterInviterCode => 'அழைப்பாளர் குறியீட்டை உள்ளிடவும்';

  @override
  String get referralsInviterCodeInstruction =>
      'நீங்கள் யாராவது அழைத்திருந்தால், உங்கள் கணக்கை அவர்களுடன் இணைக்க அவர்களின் பரிந்துரை குறியீட்டை இங்கே உள்ளிடவும்.';

  @override
  String get referralsInviterCodeLabel => 'பரிந்துரை குறியீடு';

  @override
  String get referralsInviterCodeUpdated =>
      'அழைப்பாளர் குறியீடு வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

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
  String get referralMilestoneBonusTitle => 'பரிந்துரை மைல்கல் போனஸ்';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'அழைப்பிற்கு $amount கேடோஷி ஒருமுறை வெகுமதி';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'இந்த வெகுமதி தொகை சேவையகத்தில் அமைக்கப்படுகிறது; நிர்வாகிகள் புதுப்பிக்கலாம்.';

  @override
  String get referralBonusDetailAppTitle => 'பரிந்துரை போனஸ்';

  @override
  String get referralBonusStatusHeading => 'பரிந்துரை போனஸ் நிலை';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'உங்களுக்கு (பரிந்துரைப்பவர்): $amount கேடோஷி';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'வெகுமதி ஏற்கனவே வரவு வைக்கப்பட்டது ($amount கேடோஷி).';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '3 இல் $met நிபந்தனைகள் நிறைவு';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'பரிந்துரை போனஸ்: $amount கேடோஷி';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'சேர்ந்தது $joined · பரிந்துரை $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'சுரங்க நாட்கள்';

  @override
  String get referralBonusConditionMiningReward => 'சுரங்க வெகுமதி (BASE)';

  @override
  String get referralBonusConditionGameReward => 'விளையாட்டு வெகுமதிகள்';

  @override
  String get referralBonusStatePending => 'நிபந்தனைகள் நிலுவையில்';

  @override
  String get referralBonusStateEligible => 'வெகுமதிக்கு தகுதி';

  @override
  String get referralBonusStateRewarded => 'வெகுமதி வரவு';

  @override
  String get referralBonusStateUnderReview => 'நிர்வாக மதிப்பீட்டில்';

  @override
  String get referralBonusStateRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get profileSetupSkip => 'தவிர்';

  @override
  String get profileSetupGallery => 'கேலரி';

  @override
  String get profileSetupCamera => 'கேமரா';

  @override
  String profileSetupFailedImage(Object error) {
    return 'புகைப்படம் எடுப்பதில் தோல்வி: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'காட்சி பெயர் (விருப்பமானது)';

  @override
  String get profileSetupDisplayNameHint => 'நாங்கள் உங்களை எப்படி அழைப்பது?';

  @override
  String get profileSetupSaveContinue => 'சேமித்து தொடரவும்';

  @override
  String profileSetupFailedSave(Object error) {
    return 'சுயவிவரத்தைச் சேமிப்பதில் தோல்வி: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return '$title எதுவும் தற்போது கிடைக்கவில்லை.';
  }

  @override
  String get payoutHistoryScreenTitle => 'பணம் செலுத்திய வரலாறு';

  @override
  String get payoutNoHistory => 'பணம் செலுத்திய வரலாறு எதுவும் இல்லை.';

  @override
  String get payoutViewTx => 'TX பார்க்க';

  @override
  String payoutAddressTo(Object address) {
    return 'பெறுநர்: $address';
  }

  @override
  String get commonAdd => 'சேர்';

  @override
  String get commonEdit => 'திருத்து';

  @override
  String get missionVerifyTitle => 'சரிபார்ப்பு தேவை';

  @override
  String get missionVerifyDiscord =>
      'நீங்கள் சேர்ந்ததை நாங்கள் சரிபார்க்க உங்கள் டிஸ்கார்ட் பயனர் பெயரை உள்ளிடவும்:';

  @override
  String get missionVerifyTelegram => 'உங்கள் எண் டெலிகிராம் ஐடியை உள்ளிடவும்:';

  @override
  String get missionVerifyGeneric =>
      'சரிபார்க்க உங்கள் பயனர் பெயர்/ஹேண்டிலை உள்ளிடவும்:';

  @override
  String get missionHintDiscord => 'டிஸ்கார்ட் பயனர் பெயரை உள்ளிடவும்';

  @override
  String get missionHintTelegram => 'எண் ஐடியை உள்ளிடவும்';

  @override
  String get missionHintGeneric => 'பயனர் பெயர்/ஹேண்டிலை உள்ளிடவும்';

  @override
  String get missionHelpGetId => 'ஐடியை எவ்வாறு பெறுவது?';

  @override
  String get missionSaveContinue => 'சேமித்து தொடரவும்';

  @override
  String get missionVerificationStarted =>
      'சரிபார்ப்பு தொடங்கியது! பணியை முடிக்கவும்.';

  @override
  String missionClaimedSuccess(Object amount) {
    return '$amount Catoshi கோரப்பட்டது!';
  }

  @override
  String missionFailed(Object error) {
    return 'தோல்வி: $error';
  }

  @override
  String get missionExpired => 'காலாவதியானது';

  @override
  String missionExpiresInDays(Object days) {
    return '$days நாட்களில் காலாவதியாகிறது';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return '$hours மணிநேரத்தில் காலாவதியாகிறது';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'சரிபார்க்கப்படுகிறது...';

  @override
  String get missionBtnClaim => 'கோரு';

  @override
  String get telegramHelpInstructions =>
      '1. டெலிகிராம் திறக்கவும்.\n2. @userinfobot ஐத் தேடவும் (அல்லது கீழே உள்ள QR ஐ ஸ்கேன் செய்யவும்).\n3. தொடங்கு என்பதைக் கிளிக் செய்யவும் (அல்லது /start அனுப்பவும்).\n4. இது உங்கள் விவரங்களுடன் பதிலளிக்கும். \"Id\" ஐத் தேடவும்.\n5. அந்த எண்ணை நகலெடுத்து இங்கே ஒட்டவும்.';

  @override
  String get telegramHelpBtnOpen => '@userinfobot ஐத் திறக்கவும்';

  @override
  String get telegramHelpQrLabel => 'அல்லது QR குறியீட்டை ஸ்கேன் செய்யவும்:';

  @override
  String get telegramHelpQrError =>
      'QR குறியீடு காணப்படவில்லை.\n(assets/images/telegram_qr.png ஐச் சேர்க்கவும்)';

  @override
  String get resetPasswordSuccess =>
      'கடவுச்சொல் வெற்றிகரமாக மீட்டமைக்கப்பட்டது. தயவுசெய்து உள்நுழையவும்.';

  @override
  String get resetPasswordFailed => 'கடவுச்சொல்லை மீட்டமைப்பதில் தோல்வி';

  @override
  String resetPasswordInstruction(Object email) {
    return '$email க்கு அனுப்பப்பட்ட 6 இலக்கக் குறியீடு மற்றும் உங்கள் புதிய கடவுச்சொல்லை உள்ளிடவும்.';
  }

  @override
  String get emailVerificationCodeSent =>
      'சரிபார்ப்புக் குறியீடு உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்டது!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading =>
      'விளையாட்டு சொத்துக்கள் பதிவிறக்கம் செய்யப்படுகின்றன...';

  @override
  String get gameLauncherReady => 'இயந்திரம் தயார்';

  @override
  String get gameLauncherRequired => 'விளையாட்டு சொத்துக்கள் தேவை';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'சொத்துக்களைப் பதிவிறக்கவும் (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'விளையாட்டைத் தொடங்கு';

  @override
  String get gameLauncherResetBtn => 'சொத்துக்களை மீட்டமை';

  @override
  String get gameNewGame => 'New Game';

  @override
  String get gameYouWin => 'You Win!';

  @override
  String get gameCpuWins => 'CPU Wins!';

  @override
  String get gameDraw => 'Draw!';

  @override
  String get gameYourTurnX => 'Your Turn (X)';

  @override
  String get gameYourTurnO => 'Your Turn (O)';

  @override
  String gameWinReward(Object amount) {
    return 'Win $amount Catoshi';
  }

  @override
  String gameSudokuSuccess(Object amount) {
    return 'Awesome! You solved the Sudoku and earned $amount Catoshi!';
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
    return 'Congratulations! You earned $amount Catoshi!';
  }

  @override
  String gamePuzzleSuccess(Object amount) {
    return 'Fantastic! You solved the puzzle and earned $amount Catoshi!';
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
  String get gameGameOverTitle => 'விளையாட்டு முடிந்தது';

  @override
  String get gameStatScore => 'மதிப்பெண்';

  @override
  String get gameStatDistance => 'தூரம்';

  @override
  String get gameStatCoins => 'நாணயங்கள்';

  @override
  String get gameStatCatoshiEarned => 'ஈட்டிய கேடோஷி';

  @override
  String get gamePlayAgain => 'மீண்டும் விளையாடு';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'வெளியேறு';

  @override
  String get gamePausedTitle => 'நிறுத்தப்பட்டது';

  @override
  String get gameResume => 'தொடரவும்';

  @override
  String get gameQuit => 'வெளியேறு';

  @override
  String get updateTitle => 'புதுப்பிப்பு உள்ளது';

  @override
  String get updateLater => 'பிறகு';

  @override
  String get updateNow => 'இப்போது புதுப்பிக்கவும்';

  @override
  String get updateUrlError => 'புதுப்பிப்பு URL ஐத் தொடங்க முடியவில்லை';

  @override
  String balancePayoutTo(Object address) {
    return 'பெறுநர்: $address';
  }

  @override
  String get boostersSubtitle =>
      'உங்கள் சுரங்க வேகத்தை மிகைப்படுத்தி அமர்வுகளை நீட்டிக்கவும்!';

  @override
  String get commonVersion => 'பதிப்பு';

  @override
  String get commonUser => 'பயனர்';

  @override
  String get profileVerifiedTooltip =>
      'சரிபார்க்கப்பட்டது. திறக்க மற்றும் திருத்த தட்டவும்.';

  @override
  String walletAddressLabel(Object address) {
    return 'முகவரி: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'உருவாக்கப் பிழை: $error';
  }

  @override
  String get walletDeleteWallet => 'வாலட்டை நீக்கு';

  @override
  String get commonGenerate => 'உருவாக்கு';

  @override
  String get badgeWeeklyTop => 'வாராந்திர டாப்';

  @override
  String get badgeMonthlyTop => 'மாதாந்திர டாப்';

  @override
  String get badgeAllTimeTop => 'எல்லா காலத்திலும் டாப்';

  @override
  String get badgeVerified => 'சரிபார்க்கப்பட்ட பயனர்';

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
    return 'புதிய பதிப்பு ($version) கிடைக்கிறது.';
  }

  @override
  String get updateMandatory =>
      'பயன்பாட்டைத் தொடர்ந்து பயன்படுத்த இந்தப் புதுப்பிப்பு கட்டாயமாகும்.';

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
  String get languageGroupInternational => 'சர்வதேச';

  @override
  String get languageGroupIndian => 'இந்தியா';
}
