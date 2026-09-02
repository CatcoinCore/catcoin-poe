// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'ఆటలు';

  @override
  String get navLeaders => 'నాయకులు';

  @override
  String get navWallet => 'వాలెట్';

  @override
  String get navRewards => 'బహుమతులు';

  @override
  String get navProfile => 'ప్రొఫైల్';

  @override
  String get commonCancel => 'రద్దు చేయి';

  @override
  String get commonSave => 'సేవ్ చేయి';

  @override
  String get commonOk => 'సరే';

  @override
  String get commonError => 'లోపం';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'లోడవుతోంది...';

  @override
  String get commonRetry => 'మళ్ళీ ప్రయత్నించు';

  @override
  String get commonClose => 'మూసివేయి';

  @override
  String get commonNone => 'ఏదీ లేదు';

  @override
  String get commonGallery => 'గ్యాలరీ';

  @override
  String get commonCamera => 'కెమెరా';

  @override
  String get commonRemovePhoto => 'ఫోటో తొలగించు';

  @override
  String get commonRequired => 'అవసరం';

  @override
  String get commonUnlockEdit => 'అన్‌లాక్ చేసి సవరించు';

  @override
  String get loginTitle => 'లాగిన్';

  @override
  String get loginEmailOrUsername => 'ఇమెయిల్ లేదా వినియోగదారు పేరు';

  @override
  String get loginEmailHint => 'your.email@example.com లేదా 900123456';

  @override
  String get loginPassword => 'పాస్‌వర్డ్';

  @override
  String get loginButton => 'లాగిన్';

  @override
  String get loginCreateAccount => 'ఖాతా సృష్టించు';

  @override
  String get loginForgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get loginUseEmailForVerification =>
      'ధృవీకరణ పూర్తి చేయడానికి దయచేసి ఇమెయిల్‌తో లాగిన్ అవ్వండి.';

  @override
  String get signupTitle => 'సైన్ అప్';

  @override
  String get signupEmail => 'ఇమెయిల్';

  @override
  String get signupEmailHint => 'your.email@example.com';

  @override
  String get signupPassword => 'పాస్‌వర్డ్';

  @override
  String get signupConfirmPassword => 'పాస్‌వర్డ్ నిర్ధారించు';

  @override
  String get signupReferralCode => 'రెఫరల్ కోడ్ (ఐచ్ఛికం)';

  @override
  String get signupReferralCodeHint => 'మీకు రెఫరల్ కోడ్ ఉంటే నమోదు చేయండి';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'సైన్ అప్';

  @override
  String get forgotPasswordTitle => 'పాస్‌వర్డ్ మర్చిపోయారు';

  @override
  String get forgotPasswordEmail => 'ఇమెయిల్';

  @override
  String get forgotPasswordSendCode => 'రీసెట్ కోడ్ పంపు';

  @override
  String get forgotPasswordBackToLogin => 'లాగిన్‌కి తిరిగి వెళ్ళు';

  @override
  String get emailVerificationTitle => 'ఇమెయిల్ ధృవీకరణ';

  @override
  String get emailVerificationInstruction =>
      'ఇక్కడ పంపిన ధృవీకరణ కోడ్ నమోదు చేయండి';

  @override
  String get emailVerificationCode => 'ధృవీకరణ కోడ్';

  @override
  String get emailVerificationVerify => 'ధృవీకరించు';

  @override
  String get emailVerificationResend => 'కోడ్ మళ్ళీ పంపు';

  @override
  String get resetPasswordTitle => 'పాస్‌వర్డ్ రీసెట్ చేయి';

  @override
  String get resetPasswordNewPassword => 'కొత్త పాస్‌వర్డ్';

  @override
  String get resetPasswordConfirm => 'కొత్త పాస్‌వర్డ్ నిర్ధారించు';

  @override
  String get resetPasswordButton => 'పాస్‌వర్డ్ రీసెట్ చేయి';

  @override
  String get profileSetupTitle => 'ప్రొఫైల్ సెటప్';

  @override
  String get splashLoading => 'లోడవుతోంది...';

  @override
  String get dashboardTotalBalance => 'మొత్తం బ్యాలెన్స్';

  @override
  String get dashboardCatoshi => 'కాటోషి';

  @override
  String get dashboardCatoshiLabel => 'కాటోషి';

  @override
  String get dashboardNotMining => 'మైనింగ్ లేదు';

  @override
  String get dashboardStartMining => 'మైనింగ్ ప్రారంభించు';

  @override
  String dashboardRewardRate(Object rate) {
    return 'బహుమతి రేటు: $rate కాటోషి/సెకను';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'ప్రస్తుత వ్యవధి: ${hours}h / గరిష్టంగా ${maxHours}h';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'బూస్టర్లు';

  @override
  String get boostersCardTitle => 'బూస్టర్లు';

  @override
  String get boostersCardDescription =>
      'మీ మైనింగ్ వేగాన్ని పెంచండి మరియు సెషన్లను పొడిగించండి!';

  @override
  String get boostersOpenScreen => 'బూస్టర్లు చూడు';

  @override
  String get leaderboardTitle => 'లీడర్‌బోర్డ్';

  @override
  String get leaderboardTopMiners => 'అగ్ర మైనర్లు';

  @override
  String get leaderboardRank => 'ర్యాంక్';

  @override
  String get leaderboardUser => 'వినియోగదారు';

  @override
  String get leaderboardBalance => 'బ్యాలెన్స్';

  @override
  String get leaderboardYou => 'మీరు';

  @override
  String get leaderboardGlobal => 'ప్రపంచవ్యాప్త';

  @override
  String get leaderboardRegional => 'ప్రాంతీయ';

  @override
  String get leaderboardGames => 'క్రీడలు';

  @override
  String get leaderboardAwards => 'అవార్డులు';

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
  String get leaderboardChallengers => 'ఛాలెంజర్స్';

  @override
  String get leaderboardNoGlobal => 'ప్రపంచవ్యాప్త మైనర్లు ఎవరూ కనుగొనబడలేదు.';

  @override
  String get leaderboardNoRegional => 'ప్రాంతీయ మైనర్లు ఎవరూ కనుగొనబడలేదు.';

  @override
  String get leaderboardComingSoon =>
      'త్వరలో వస్తుంది — మినీ-గేమ్‌లలో పోటీపడండి!';

  @override
  String get leaderboardNoAwards => 'ఇంకా అవార్డులు లేవు';

  @override
  String get leaderboardKeepMining =>
      'పోడియంను క్లెయిమ్ చేయడానికి మైనింగ్‌ను కొనసాగించండి!';

  @override
  String get walletTitle => 'వాలెట్';

  @override
  String get walletAddress => 'వాలెట్ చిరునామా';

  @override
  String get walletBalance => 'బ్యాలెన్స్';

  @override
  String get walletCopy => 'కాపీ చేయి';

  @override
  String get walletCopied => 'కాపీ అయింది!';

  @override
  String get walletSend => 'పంపు';

  @override
  String get walletReceive => 'స్వీకరించు';

  @override
  String get walletTransactions => 'లావాదేవీలు';

  @override
  String get walletNoTransactions => 'ఇంకా లావాదేవీలు లేవు';

  @override
  String get walletConnectWallet => 'వాలెట్ కనెక్ట్ చేయి';

  @override
  String get walletDisconnect => 'డిస్‌కనెక్ట్';

  @override
  String get walletSolanaAddress => 'సోలానా చిరునామా';

  @override
  String get walletEnterAddress => 'సోలానా చిరునామా నమోదు చేయి';

  @override
  String get walletSaveAddress => 'చిరునామా సేవ్ చేయి';

  @override
  String get walletAddressSaved => 'చిరునామా సేవ్ అయింది!';

  @override
  String get walletInvalidAddress => 'చెల్లని సోలానా చిరునామా';

  @override
  String get walletMyWallets => 'నా వాలెట్లు';

  @override
  String get walletAddExisting => 'ఉన్న చిరునామాను జోడించండి';

  @override
  String get walletCatcoinAddress => 'క్యాట్‌కాయిన్ చిరునామా';

  @override
  String get walletPasteHint => 'చిరునామాను ఇక్కడ అతికించండి';

  @override
  String get walletSetPrimary => 'ప్రాథమికంగా సెట్ చేయండి';

  @override
  String get walletInvalidAddressComplex =>
      'చెల్లని చిరునామా. చెల్లుబాటు అయ్యే BEP20 (0x...), సోలానా లేదా క్యాట్‌కాయిన్ (9తో ప్రారంభమయ్యే) చిరునామా అయి ఉండాలి.';

  @override
  String get walletRecoverTitle => 'వాలెట్‌ను పునరుద్ధరించండి';

  @override
  String get walletRecoverInstruction =>
      'మీ వాలెట్‌ను పునరుద్ధరించడానికి మీ 24-పదాల రహస్య పదబంధాన్ని నమోదు చేయండి.';

  @override
  String get walletSecretPhrase => 'రహస్య పదబంధం';

  @override
  String get walletSecretPhraseHint => 'పదం1 పదం2 ... పదం24';

  @override
  String get walletInvalidPhrase => 'చెల్లని పదబంధం. సరిగ్గా 24 పదాలు ఉండాలి.';

  @override
  String get walletDeleteTitle => 'వాలెట్‌ను తొలగించండి';

  @override
  String walletDeleteConfirmMessage(String address) {
    return 'మీరు ఖచ్చితంగా వాలెట్ $addressని తొలగించాలనుకుంటున్నారా? మీ వద్ద ప్రైవేట్ కీ/పదబంధం లేకపోతే ఈ చర్యను రద్దు చేయలేరు.';
  }

  @override
  String get walletDeletedSuccess => 'వాలెట్ విజయవంతంగా తొలగించబడింది';

  @override
  String get walletAddedSuccess => 'వాలెట్ విజయవంతంగా జోడించబడింది';

  @override
  String get walletGenerateTitle => 'కొత్త వాలెట్‌ను రూపొందించండి';

  @override
  String get walletBackupTitle => 'విజయం! మీ వాలెట్‌ను బ్యాకప్ చేయండి';

  @override
  String get walletBackupWarning =>
      'ముఖ్యమైన గమనిక: ఈ 24 పదాలను క్రమంలో రాసి భద్రపరుచుకోండి. అవి లేకుండా మీరు మీ నిధులను తిరిగి పొందలేరు!';

  @override
  String get walletGenerateInstruction =>
      'ఇది మీ కోసం కొత్త క్యాట్‌కాయిన్ వాలెట్‌ను సృష్టిస్తుంది. సృష్టించిన వెంటనే మీ రహస్య పదబంధాన్ని బ్యాకప్ చేయడం నిర్ధారించుకోండి!';

  @override
  String get walletGenerating => 'కీలను రూపొందిస్తోంది...';

  @override
  String get walletBackedUp => 'నేను బ్యాకప్ చేసాను';

  @override
  String get walletRecoverFromPhrase => 'పదబంధం నుండి పునరుద్ధరించండి';

  @override
  String get walletSetDefault => 'డిఫాల్ట్‌గా సెట్ చేయండి';

  @override
  String get walletSettingPrimary => 'వాలెట్‌ను ప్రాథమికంగా సెట్ చేస్తోంది...';

  @override
  String get walletPrimary => 'ప్రాథమికం';

  @override
  String get walletSourceGenerated => 'రూపొందించబడింది';

  @override
  String get walletSourceRecovered => 'పునరుద్ధరించబడింది';

  @override
  String get walletSourceManual => 'మాన్యువల్ చిరునామా';

  @override
  String walletDaysHeld(String days) {
    return 'నిలిపి ఉంచిన రోజులు: $days';
  }

  @override
  String get walletCalculating => 'గణిస్తోంది...';

  @override
  String get rewardsTitle => 'బహుమతులు';

  @override
  String get rewardsClaim => 'క్లెయిమ్ చేయి';

  @override
  String get rewardsClaimed => 'క్లెయిమ్ అయింది';

  @override
  String get rewardsAvailable => 'అందుబాటులో ఉంది';

  @override
  String get rewardsNoRewards => 'బహుమతులు అందుబాటులో లేవు';

  @override
  String get rewardsSocialTasks => 'సోషల్ టాస్క్‌లు';

  @override
  String get rewardsXTasks => 'X టాస్క్‌లు';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'అన్ని మిషన్లు';

  @override
  String get rewardsNoMissions => 'చురుకైన మిషన్లు అందుబాటులో లేవు.';

  @override
  String rewardsError(String error) {
    return 'లోపం: $error';
  }

  @override
  String get gamesTitle => 'గేమ్స్';

  @override
  String get gamesPlay => 'ఆడు';

  @override
  String get gamesRunner => 'క్యాట్ రన్నర్';

  @override
  String get gamesRunnerDescription => 'పరుగెత్తు, దూకు మరియు నాణేలు సేకరించు!';

  @override
  String get gamesNoGames => 'గేమ్స్ అందుబాటులో లేవు';

  @override
  String get referralTitle => 'నా రెఫరళ్ళు';

  @override
  String get referralCode => 'మీ రెఫరల్ కోడ్';

  @override
  String get referralCopyCode => 'కోడ్ కాపీ చేయి';

  @override
  String get referralShareLink => 'లింక్ షేర్ చేయి';

  @override
  String get referralActiveReferrals => 'చురుకైన రెఫరళ్ళు';

  @override
  String get referralNoReferrals => 'ఇంకా రెఫరళ్ళు లేవు';

  @override
  String get referralBoost => 'బూస్ట్';

  @override
  String get referralBoosted => 'బూస్ట్ అయింది';

  @override
  String get referralInviteFriends => 'స్నేహితులను ఆహ్వానించు';

  @override
  String get balanceDetailTitle => 'బ్యాలెన్స్ వివరాలు';

  @override
  String get payoutHistoryTitle => 'చెల్లింపు చరిత్ర';

  @override
  String get payoutHistoryNone => 'చెల్లింపు చరిత్ర లేదు';

  @override
  String get awardsTitle => 'అవార్డులు';

  @override
  String get socialMissionsTitle => 'సోషల్ మిషన్లు';

  @override
  String get profileTitle => 'ప్రొఫైల్';

  @override
  String get profileAccountDetails => 'ఖాతా వివరాలు';

  @override
  String get profileReferredBy => 'రెఫర్ చేసింది';

  @override
  String get profileMyReferrals => 'నా రెఫరళ్ళు';

  @override
  String get profileSocialProfiles => 'ధృవీకరణ కోసం సోషల్ ప్రొఫైళ్ళు';

  @override
  String get profileDiscord => 'Discord వినియోగదారు పేరు';

  @override
  String get profileTelegram => 'Telegram వినియోగదారు ID (సంఖ్యాత్మక)';

  @override
  String get profileTelegramHint => 'ఉదా: 123456789';

  @override
  String get profileX => 'X (Twitter) హ్యాండిల్';

  @override
  String get profileFacebook => 'Facebook ప్రొఫైల్ లింక్/ID';

  @override
  String get profileWhatsapp => 'WhatsApp నంబర్';

  @override
  String get profileSaveSocialIds => 'సోషల్ IDలు సేవ్ చేయి';

  @override
  String get profileUpdatedSuccess => 'ప్రొఫైల్ విజయవంతంగా నవీకరించబడింది!';

  @override
  String get profileSettings => 'సెట్టింగ్స్';

  @override
  String get profileAppearance => 'రూపం';

  @override
  String get profileThemeSystem => 'సిస్టమ్';

  @override
  String get profileThemeLight => 'లైట్';

  @override
  String get profileThemeDark => 'డార్క్';

  @override
  String get profilePayoutHistory => 'చెల్లింపు చరిత్ర';

  @override
  String get profileChangePassword => 'పాస్‌వర్డ్ మార్చు';

  @override
  String get profileLanguage => 'భాష';

  @override
  String get profileLogout => 'లాగ్ అవుట్';

  @override
  String get profileDeleteAccount => 'ఖాతా తొలగించు';

  @override
  String get profileDiscordHint => 'మీ Discord వినియోగదారు పేరు నమోదు చేయండి';

  @override
  String get profileVerified =>
      'ధృవీకరించబడింది. సవరించడానికి 🔒 నొక్కండి (బహుమతి రద్దవుతుంది).';

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
  String get changePasswordTitle => 'పాస్‌వర్డ్ మార్చు';

  @override
  String get changePasswordCurrent => 'ప్రస్తుత పాస్‌వర్డ్';

  @override
  String get changePasswordNew => 'కొత్త పాస్‌వర్డ్';

  @override
  String get changePasswordConfirm => 'కొత్త పాస్‌వర్డ్ నిర్ధారించు';

  @override
  String get changePasswordMin6 => 'కనీసం 6 అక్షరాలు';

  @override
  String get changePasswordMismatch => 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు';

  @override
  String get changePasswordSuccess => 'పాస్‌వర్డ్ విజయవంతంగా మార్చబడింది!';

  @override
  String get deleteAccountTitle => 'ఖాతా తొలగించాలా?';

  @override
  String get deleteAccountMessage =>
      'ఈ చర్య శాశ్వతమైనది మరియు రద్దు చేయలేము.\n\nమీ మైనింగ్ పురోగతి, బ్యాలెన్స్ మరియు రెఫరళ్ళు అన్నీ శాశ్వతంగా కోల్పోతారు.';

  @override
  String get deleteAccountConfirm => 'శాశ్వతంగా తొలగించు';

  @override
  String deleteAccountFailed(String error) {
    return 'తొలగించడం విఫలమైంది: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return '$platform ID సవరించాలా?';
  }

  @override
  String get resetSocialMessage =>
      'ధృవీకరించబడిన సోషల్ ID మార్చడం వల్ల కొత్త ID ధృవీకరించబడే వరకు 1,00,000 కాటోషి మిషన్ బహుమతి రద్దవుతుంది.\n\nకొనసాగించాలా?';

  @override
  String get resetSocialUnlocked => 'ID సవరణకు అన్‌లాక్ అయింది.';

  @override
  String resetSocialFailed(String error) {
    return 'అన్‌లాక్ విఫలమైంది: $error';
  }

  @override
  String get languageSelectTitle => 'భాష ఎంచుకోండి';

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
  String get telegramHelpTitle => 'మీ Telegram ID ఎలా కనుగొనాలి';

  @override
  String get telegramHelpStep1 => 'Telegram తెరవండి మరియు @userinfobot వెతకండి';

  @override
  String get telegramHelpStep2 => 'బాట్‌తో చాట్ ప్రారంభించండి';

  @override
  String get telegramHelpStep3 => 'బాట్ మీ సంఖ్యా వినియోగదారు IDని పంపుతుంది';

  @override
  String get missionComplete => 'పూర్తి చేయి';

  @override
  String get missionCompleted => 'పూర్తయింది';

  @override
  String get missionClaim => 'క్లెయిమ్ చేయి';

  @override
  String get missionClaimed => 'క్లెయిమ్ అయింది';

  @override
  String get missionGo => 'వెళ్ళు';

  @override
  String failedPickImage(String error) {
    return 'ఫోటో ఎంచుకోవడం విఫలమైంది: $error';
  }

  @override
  String get awardsNoAwards => 'మీరు ఇంకా ఎటువంటి అవార్డులను గెలుచుకోలేదు.';

  @override
  String get awardsKeepMining =>
      'మైనింగ్ కొనసాగించండి మరియు లీడర్‌బోర్డ్ పైకి వెళ్లండి!';

  @override
  String get balanceSummary => 'సారాంశం';

  @override
  String get balanceEarnings => 'సంపాదన';

  @override
  String get balancePayouts => 'చెల్లింపులు';

  @override
  String get balanceLoadError => 'బ్యాలెన్స్ వివరాలను లోడ్ చేయడం విఫలమైంది.';

  @override
  String get balanceWithdrawSoon =>
      'వేచి ఉండండి — ఉపసంహరణలు త్వరలో అందుబాటులోకి వస్తాయి!';

  @override
  String get balanceTotal => 'మొత్తం బ్యాలెన్స్';

  @override
  String get balanceNotWithdrawable => 'ఉపసంహరించుకోలేరు';

  @override
  String get balanceBreakdown => 'సంపాదన వివరాలు';

  @override
  String get balanceMining => 'మైనింగ్ సంపాదన';

  @override
  String get balanceReferral => 'రెఫరల్ సంపాదన';

  @override
  String get balanceMission => 'మిషన్ సంపాదన';

  @override
  String get balanceGame => 'గేమ్ సంపాదన';

  @override
  String get balanceWithdraw => 'ఉపసంహరణ';

  @override
  String get balanceWithdrawSubmitted => 'ఉపసంహరణ అభ్యర్థన సమర్పించబడింది!';

  @override
  String get balanceNoHistory => 'సంపాదన చరిత్ర లేదు.';

  @override
  String get balanceNoPayouts => 'చెల్లింపు చరిత్ర లేదు.';

  @override
  String get boostersActiveModifiers => 'చురుకైన మోడిఫైయర్లు';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'ప్రస్తుత రెఫరల్ బోనస్: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'అందుబాటులో ఉన్న మోడిఫైయర్లు';

  @override
  String get boostersApplyExtensions =>
      'మీ ప్రస్తుత మైనింగ్ సెషన్ కోసం సమయ పొడిగింపులు మరియు రెఫరల్ బోనస్‌లను వర్తింపజేయండి.';

  @override
  String get boostersStartMiningPrompt =>
      'మోడిఫైయర్లను అన్లాక్ చేయడానికి డాష్‌బోర్డ్ లో మైనింగ్ ప్రారంభించండి!';

  @override
  String get boostersNoBoosters =>
      'ప్రస్తుతం ఎటువంటి బూస్టర్లు అందుబాటులో లేవు.';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return '$hoursగం సమయ బూస్ట్';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'కూల్‌డౌన్: $duration';
  }

  @override
  String get boostersSessionMaxed => 'సెషన్ గరిష్టంగా 24 గంటలకు చేరుకుంది.';

  @override
  String boostersExtendBy(Object hours) {
    return 'సెషన్‌ను $hoursగం పొడిగించండి (గరిష్ట సామర్థ్యం)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return 'సెషన్‌ను $hoursగం పొడిగించండి';
  }

  @override
  String get boostersApply => 'వర్తింపజేయి';

  @override
  String boostersReferralBoosting(Object boost) {
    return 'మీ వేగాన్ని పెంచుతోంది! (యాక్టివ్) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'రెఫరల్ సామర్థ్యం పూర్తయింది.';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return 'యాక్టివ్ మైనర్! +$boost% బోనస్ పొందండి.';
  }

  @override
  String get boostersActive => 'యాక్టివ్';

  @override
  String get boostersErrorMustMine => 'ముందుగా మీరు మైనింగ్ ప్రారంభించాలి!';

  @override
  String get boostersEnergyPotionConsumed =>
      'ఎనర్జీ పోషన్ విజయవంతంగా ఉపయోగించబడింది!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'సెషన్ పొడిగింపు విఫలమైంది: $error';
  }

  @override
  String get boostersReferralActivated =>
      'రెఫరల్ బూస్ట్ విజయవంతంగా యాక్టివేట్ చేయబడింది!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => 'పరుగెత్తు, దూకు మరియు కాటోషి సంపాదించు!';

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
  String get gamesComingSoon => 'త్వరలో వస్తోంది...';

  @override
  String get referralsTitle => 'రెఫరల్స్';

  @override
  String get referralsInvitedBy => 'ఆహ్వానించింది';

  @override
  String get referralsNoOneYet => 'ఇంకా ఎవరూ లేరు';

  @override
  String get referralsYourCode => 'మీ రెఫరల్ కోడ్';

  @override
  String get referralsCopied => 'క్లిప్‌బోర్డ్‌కు కాపీ చేయబడింది';

  @override
  String referralsShareMessage(Object code) {
    return 'కాట్‌కాయిన్ PoE లో నాతో చేరండి! బోనస్ పొందడానికి నా కోడ్ $code ఉపయోగించండి.\n\nలింక్: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'మొత్తం';

  @override
  String get referralsActiveCount => 'యాక్టివ్';

  @override
  String get referralsBoostPercentage => 'బూస్ట్ %';

  @override
  String get referralsYourReferrals => 'మీ రెఫరల్స్';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'యాక్టివ్ (గడచిన 24గం)';

  @override
  String get referralsInactive => 'యాక్టివ్ కాదు';

  @override
  String get referralsEnterInviterCode => 'ఆహ్వానించిన వారి కోడ్ నమోదు చేయండి';

  @override
  String get referralsInviterCodeInstruction =>
      'మిమ్మల్ని ఎవరైనా ఆహ్వానించి ఉంటే, మీ ఖాతాను వారితో అనుసంధానించడానికి వారి రెఫరల్ కోడ్‌ను ఇక్కడ నమోదు చేయండి.';

  @override
  String get referralsInviterCodeLabel => 'రెఫరల్ కోడ్';

  @override
  String get referralsInviterCodeUpdated =>
      'ఆహ్వానించిన వారి కోడ్ విజయవంతంగా నవీకరించబడింది!';

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
  String get referralMilestoneBonusTitle => 'రెఫరల్ మైలురాళ్ల బోనస్';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'ప్రతి ఆహ్వానానికి $amount కాటోషి ఒకసారి బహుమతి';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'ఈ బహుమతి మొత్తం సర్వర్‌లో కాన్ఫిగర్ చేయబడుతుంది మరియు నిర్వాహకులు నవీకరించవచ్చు.';

  @override
  String get referralBonusDetailAppTitle => 'రెఫరల్ బోనస్';

  @override
  String get referralBonusStatusHeading => 'రెఫరల్ బోనస్ స్థితి';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'మీకు (రెఫరర్): $amount కాటోషి';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'బహుమతి ఇప్పటికే జమ చేయబడింది ($amount కాటోషి).';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '3లో $met షరతులు నెరవేరాయి';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'రెఫరల్ బోనస్: $amount కాటోషి';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'చేరిన $joined · రెఫర్ చేసిన $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'మైనింగ్ రోజులు';

  @override
  String get referralBonusConditionMiningReward => 'మైనింగ్ బహుమతి (బేస్)';

  @override
  String get referralBonusConditionGameReward => 'గేమ్ బహుమతులు';

  @override
  String get referralBonusStatePending => 'షరతులు పెండింగ్';

  @override
  String get referralBonusStateEligible => 'బహుమతికి అర్హత';

  @override
  String get referralBonusStateRewarded => 'బహుమతి జమ';

  @override
  String get referralBonusStateUnderReview => 'అడ్మిన్ సమీక్షలో';

  @override
  String get referralBonusStateRejected => 'తిరస్కరించబడింది';

  @override
  String get profileSetupSkip => 'వదిలివేయి';

  @override
  String get profileSetupGallery => 'గ్యాలరీ';

  @override
  String get profileSetupCamera => 'కెమెరా';

  @override
  String profileSetupFailedImage(Object error) {
    return 'ఫోటో ఎంచుకోవడం విఫలమైంది: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'డిస్‌ప్లే పేరు (ఐచ్ఛికం)';

  @override
  String get profileSetupDisplayNameHint => 'మిమ్మల్ని ఏమని పిలవాలి?';

  @override
  String get profileSetupSaveContinue => 'మరియు కొనసాగించు';

  @override
  String profileSetupFailedSave(Object error) {
    return 'ప్రొఫైల్ సేవ్ చేయడం విఫలమైంది: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return 'ప్రస్తుతం ఏ $title అందుబాటులో లేవు.';
  }

  @override
  String get payoutHistoryScreenTitle => 'చెల్లింపు చరిత్ర';

  @override
  String get payoutNoHistory => 'చెల్లింపు చరిత్ర కనుగొనబడలేదు.';

  @override
  String get payoutViewTx => 'TX చూడండి';

  @override
  String payoutAddressTo(Object address) {
    return 'కు: $address';
  }

  @override
  String get commonAdd => 'జోడించు';

  @override
  String get commonEdit => 'సవరించు';

  @override
  String get missionVerifyTitle => 'ధృవీకరణ అవసరం';

  @override
  String get missionVerifyDiscord =>
      'మీరు చేరినట్లు మేము ధృవీకరించడానికి మీ డిస్కార్డ్ వినియోగదారు పేరును నమోదు చేయండి:';

  @override
  String get missionVerifyTelegram => 'మీ సంఖ్యా టెలిగ్రామ్ IDని నమోదు చేయండి:';

  @override
  String get missionVerifyGeneric =>
      'ధృవీకరించడానికి మీ వినియోగదారు పేరు/హ్యాండిల్‌ను నమోదు చేయండి:';

  @override
  String get missionHintDiscord => 'డిస్కార్డ్ వినియోగదారు పేరును నమోదు చేయండి';

  @override
  String get missionHintTelegram => 'సంఖ్యా IDని నమోదు చేయండి';

  @override
  String get missionHintGeneric => 'వినియోగదారు పేరు/హ్యాండిల్‌ను నమోదు చేయండి';

  @override
  String get missionHelpGetId => 'IDని ఎలా పొందాలి?';

  @override
  String get missionSaveContinue => 'సేవ్ చేసి కొనసాగించు';

  @override
  String get missionVerificationStarted =>
      'ధృవీకరణ ప్రారంభమైంది! దయచేసి పనిని పూర్తి చేయండి.';

  @override
  String missionClaimedSuccess(Object amount) {
    return '$amount Catoshi క్లెయిమ్ చేయబడింది!';
  }

  @override
  String missionFailed(Object error) {
    return 'విఫలమైంది: $error';
  }

  @override
  String get missionExpired => 'గడువు ముగిసింది';

  @override
  String missionExpiresInDays(Object days) {
    return '$days రోజుల్లో గడువు ముగుస్తుంది';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return '$hours గంటల్లో గడువు ముగుస్తుంది';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'ధృవీకరిస్తోంది...';

  @override
  String get missionBtnClaim => 'క్లెయిమ్';

  @override
  String get telegramHelpInstructions =>
      '1. టెలిగ్రామ్ తెరవండి.\n2. @userinfobot కోసం శోధించండి (లేదా క్రింద QR స్కాన్ చేయండి).\n3. స్టార్ట్ క్లిక్ చేయండి (లేదా /start పంపండి).\n4. ఇది మీ వివరాలతో సమాధానం ఇస్తుంది. \"Id\" కోసం చూడండి.\n5. ఆ నంబర్‌ను కాపీ చేసి ఇక్కడ పేస్ట్ చేయండి.';

  @override
  String get telegramHelpBtnOpen => '@userinfobot తెరవండి';

  @override
  String get telegramHelpQrLabel => 'లేదా QR కోడ్ స్కాన్ చేయండి:';

  @override
  String get telegramHelpQrError =>
      'QR కోడ్ కనుగొనబడలేదు.\n(assets/images/telegram_qr.png జోడించండి)';

  @override
  String get resetPasswordSuccess =>
      'పాస్‌వర్డ్ విజయవంతంగా రీసెట్ చేయబడింది. దయచేసి లాగిన్ చేయండి.';

  @override
  String get resetPasswordFailed => 'పాస్‌వర్డ్ రీసెట్ చేయడం విఫలమైంది';

  @override
  String resetPasswordInstruction(Object email) {
    return '$emailకి పంపిన 6-అంకెల కోడ్ మరియు మీ కొత్త పాస్‌వర్డ్‌ను నమోదు చేయండి.';
  }

  @override
  String get emailVerificationCodeSent =>
      'ధృవీకరణ కోడ్ మీ ఇమెయిల్‌కు పంపబడింది!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => 'గేమ్ వనరులు డౌన్‌లోడ్ అవుతున్నాయి...';

  @override
  String get gameLauncherReady => 'ఇంజిన్ సిద్ధంగా ఉంది';

  @override
  String get gameLauncherRequired => 'గేమ్ వనరులు అవసరం';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'వనరులను డౌన్‌లోడ్ చేయండి (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'గేమ్ ప్రారంభించండి';

  @override
  String get gameLauncherResetBtn => 'వనరులను రీసెట్ చేయండి';

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
  String get gameGameOverTitle => 'ఆట ముగిసింది';

  @override
  String get gameStatScore => 'స్కోరు';

  @override
  String get gameStatDistance => 'దూరం';

  @override
  String get gameStatCoins => 'నాణెం';

  @override
  String get gameStatCatoshiEarned => 'సంపాదించిన కాటోషి';

  @override
  String get gamePlayAgain => 'మళ్ళీ ఆడండి';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'నిష్క్రమించు';

  @override
  String get gamePausedTitle => 'పాజ్ చేయబడింది';

  @override
  String get gameResume => 'కొనసాగించు';

  @override
  String get gameQuit => 'నిష్క్రమించు';

  @override
  String get updateTitle => 'అప్‌డేట్ అందుబాటులో ఉంది';

  @override
  String get updateLater => 'తర్వాత';

  @override
  String get updateNow => 'ఇప్పుడే అప్‌డేట్ చేయండి';

  @override
  String get updateUrlError => 'అప్‌డేట్ URLని ప్రారంభించలేకపోయింది';

  @override
  String balancePayoutTo(Object address) {
    return 'కి: $address';
  }

  @override
  String get boostersSubtitle =>
      'మీ మైనింగ్ వేగాన్ని పెంచండి మరియు సెషన్లను పొడిగించండి!';

  @override
  String get commonVersion => 'వెర్షన్';

  @override
  String get commonUser => 'వినియోగదారు';

  @override
  String get profileVerifiedTooltip =>
      'ధృవీకరించబడింది. అన్‌లాక్ చేయడానికి మరియు సవరించడానికి నొక్కండి.';

  @override
  String walletAddressLabel(Object address) {
    return 'చిరునామా: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'జనరేషన్ లోపం: $error';
  }

  @override
  String get walletDeleteWallet => 'వాలెట్‌ను తొలగించు';

  @override
  String get commonGenerate => 'జనరేట్ చేయండి';

  @override
  String get badgeWeeklyTop => 'వీక్లీ టాప్';

  @override
  String get badgeMonthlyTop => 'మంత్లీ టాప్';

  @override
  String get badgeAllTimeTop => 'ఆల్ టైమ్ టాప్';

  @override
  String get badgeVerified => 'ధృవీకరించబడిన వినియోగదారు';

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
    return 'కొత్త వెర్షన్ ($version) అందుబాటులో ఉంది.';
  }

  @override
  String get updateMandatory =>
      'యాప్‌ను ఉపయోగించడం కొనసాగించడానికి ఈ అప్‌డేట్ తప్పనిసరి.';

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
  String get languageGroupInternational => 'అంతర్జాతీయ';

  @override
  String get languageGroupIndian => 'భారతదేశం';
}
