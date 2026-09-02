import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('or'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('vi'),
    Locale('zh')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Catcoin'**
  String get appTitle;

  /// The title of the home tab in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// The title of the updates tab in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get navUpdates;

  /// Bottom nav: Games
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// Bottom nav: Leaderboard
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get navLeaders;

  /// Bottom nav: Wallet
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// Bottom nav: Rewards
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get navRewards;

  /// Bottom nav: Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonAppName.
  ///
  /// In en, this message translates to:
  /// **'Catcoin'**
  String get commonAppName;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get commonRemovePhoto;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonUnlockEdit.
  ///
  /// In en, this message translates to:
  /// **'Unlock & Edit'**
  String get commonUnlockEdit;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get loginEmailOrUsername;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com or 900123456'**
  String get loginEmailHint;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginUseEmailForVerification.
  ///
  /// In en, this message translates to:
  /// **'Please login with your Email to complete verification.'**
  String get loginUseEmailForVerification;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupTitle;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmail;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get signupEmailHint;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get signupReferralCode;

  /// No description provided for @signupReferralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code if you have one'**
  String get signupReferralCodeHint;

  /// No description provided for @signupReferralFromInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite link applied'**
  String get signupReferralFromInviteTitle;

  /// No description provided for @signupReferralFromInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Referral code {code} will be used when you create your account. You do not need to type it.'**
  String signupReferralFromInviteBody(String code);

  /// No description provided for @signupReferralChangeCode.
  ///
  /// In en, this message translates to:
  /// **'Use a different code'**
  String get signupReferralChangeCode;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotPasswordEmail;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to'**
  String get emailVerificationInstruction;

  /// No description provided for @emailVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get emailVerificationCode;

  /// No description provided for @emailVerificationVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get emailVerificationVerify;

  /// No description provided for @emailVerificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get emailVerificationResend;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewPassword;

  /// No description provided for @resetPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get resetPasswordConfirm;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Profile'**
  String get profileSetupTitle;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @dashboardTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get dashboardTotalBalance;

  /// No description provided for @dashboardCatoshi.
  ///
  /// In en, this message translates to:
  /// **'catoshi'**
  String get dashboardCatoshi;

  /// No description provided for @dashboardCatoshiLabel.
  ///
  /// In en, this message translates to:
  /// **'Catoshi'**
  String get dashboardCatoshiLabel;

  /// No description provided for @dashboardNotMining.
  ///
  /// In en, this message translates to:
  /// **'Not Mining'**
  String get dashboardNotMining;

  /// No description provided for @dashboardStartMining.
  ///
  /// In en, this message translates to:
  /// **'START MINING'**
  String get dashboardStartMining;

  /// No description provided for @dashboardRewardRate.
  ///
  /// In en, this message translates to:
  /// **'Reward Rate: {rate} Catoshi/sec'**
  String dashboardRewardRate(Object rate);

  /// No description provided for @dashboardCurrentDuration.
  ///
  /// In en, this message translates to:
  /// **'Current duration: {hours}h / {maxHours}h max'**
  String dashboardCurrentDuration(Object hours, Object maxHours);

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String dashboardWelcome(String name);

  /// No description provided for @boostersTitle.
  ///
  /// In en, this message translates to:
  /// **'Boosters'**
  String get boostersTitle;

  /// No description provided for @boostersCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Boosters'**
  String get boostersCardTitle;

  /// No description provided for @boostersCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Supercharge your mining speed & extend sessions!'**
  String get boostersCardDescription;

  /// No description provided for @boostersOpenScreen.
  ///
  /// In en, this message translates to:
  /// **'View Boosters'**
  String get boostersOpenScreen;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardTopMiners.
  ///
  /// In en, this message translates to:
  /// **'Top Miners'**
  String get leaderboardTopMiners;

  /// No description provided for @leaderboardRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get leaderboardRank;

  /// No description provided for @leaderboardUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get leaderboardUser;

  /// No description provided for @leaderboardBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get leaderboardBalance;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get leaderboardGlobal;

  /// No description provided for @leaderboardRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get leaderboardRegional;

  /// No description provided for @leaderboardGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get leaderboardGames;

  /// No description provided for @leaderboardAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get leaderboardAwards;

  /// No description provided for @leaderboardGlobalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Global (Monthly)'**
  String get leaderboardGlobalMonthly;

  /// No description provided for @leaderboardRegionalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Regional (Monthly)'**
  String get leaderboardRegionalMonthly;

  /// No description provided for @awardsLifetimeAchievements.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Achievements'**
  String get awardsLifetimeAchievements;

  /// No description provided for @awardsMonthlyChampions.
  ///
  /// In en, this message translates to:
  /// **'Previous Month Champions'**
  String get awardsMonthlyChampions;

  /// No description provided for @awardsPreviousMonthWinners.
  ///
  /// In en, this message translates to:
  /// **'Previous Month Leaders'**
  String get awardsPreviousMonthWinners;

  /// No description provided for @leaderboardChallengers.
  ///
  /// In en, this message translates to:
  /// **'Challengers'**
  String get leaderboardChallengers;

  /// No description provided for @leaderboardNoGlobal.
  ///
  /// In en, this message translates to:
  /// **'No global miners found.'**
  String get leaderboardNoGlobal;

  /// No description provided for @leaderboardNoRegional.
  ///
  /// In en, this message translates to:
  /// **'No regional miners found.'**
  String get leaderboardNoRegional;

  /// No description provided for @leaderboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — compete across mini-games!'**
  String get leaderboardComingSoon;

  /// No description provided for @leaderboardNoAwards.
  ///
  /// In en, this message translates to:
  /// **'No awards yet'**
  String get leaderboardNoAwards;

  /// No description provided for @leaderboardKeepMining.
  ///
  /// In en, this message translates to:
  /// **'Keep mining to claim the podium!'**
  String get leaderboardKeepMining;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddress;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalance;

  /// No description provided for @walletCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get walletCopy;

  /// No description provided for @walletCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get walletCopied;

  /// No description provided for @walletSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get walletSend;

  /// No description provided for @walletReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get walletReceive;

  /// No description provided for @walletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get walletTransactions;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletNoTransactions;

  /// No description provided for @walletConnectWallet.
  ///
  /// In en, this message translates to:
  /// **'Connect Wallet'**
  String get walletConnectWallet;

  /// No description provided for @walletDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get walletDisconnect;

  /// No description provided for @walletSolanaAddress.
  ///
  /// In en, this message translates to:
  /// **'Solana Address'**
  String get walletSolanaAddress;

  /// No description provided for @walletEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter Solana address'**
  String get walletEnterAddress;

  /// No description provided for @walletSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get walletSaveAddress;

  /// No description provided for @walletAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved!'**
  String get walletAddressSaved;

  /// No description provided for @walletInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Solana address'**
  String get walletInvalidAddress;

  /// No description provided for @walletMyWallets.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get walletMyWallets;

  /// No description provided for @walletAddExisting.
  ///
  /// In en, this message translates to:
  /// **'Add Existing Address'**
  String get walletAddExisting;

  /// No description provided for @walletCatcoinAddress.
  ///
  /// In en, this message translates to:
  /// **'Catcoin Address'**
  String get walletCatcoinAddress;

  /// No description provided for @walletPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste address here'**
  String get walletPasteHint;

  /// No description provided for @walletSetPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get walletSetPrimary;

  /// No description provided for @walletInvalidAddressComplex.
  ///
  /// In en, this message translates to:
  /// **'Invalid Address. Must be a valid BEP20 (0x...), Solana, or Catcoin (starts with 9) address.'**
  String get walletInvalidAddressComplex;

  /// No description provided for @walletRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Wallet'**
  String get walletRecoverTitle;

  /// No description provided for @walletRecoverInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your 24-word secret phrase to recover your wallet.'**
  String get walletRecoverInstruction;

  /// No description provided for @walletSecretPhrase.
  ///
  /// In en, this message translates to:
  /// **'Secret Phrase'**
  String get walletSecretPhrase;

  /// No description provided for @walletSecretPhraseHint.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 ... word24'**
  String get walletSecretPhraseHint;

  /// No description provided for @walletInvalidPhrase.
  ///
  /// In en, this message translates to:
  /// **'Invalid phrase. Must be exactly 24 words.'**
  String get walletInvalidPhrase;

  /// No description provided for @walletDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get walletDeleteTitle;

  /// No description provided for @walletDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete wallet {address}? This action cannot be undone if you do not have the private key/phrase.'**
  String walletDeleteConfirmMessage(String address);

  /// No description provided for @walletDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted successfully'**
  String get walletDeletedSuccess;

  /// No description provided for @walletAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet added successfully'**
  String get walletAddedSuccess;

  /// No description provided for @walletGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate New Wallet'**
  String get walletGenerateTitle;

  /// No description provided for @walletBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Success! Backup Your Wallet'**
  String get walletBackupTitle;

  /// No description provided for @walletBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: Write down these 24 words in order and keep them safe. You cannot recover your funds without them!'**
  String get walletBackupWarning;

  /// No description provided for @walletGenerateInstruction.
  ///
  /// In en, this message translates to:
  /// **'This will create a new Catcoin wallet for you. Make sure to back up your secret phrase immediately after creation!'**
  String get walletGenerateInstruction;

  /// No description provided for @walletGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating keys...'**
  String get walletGenerating;

  /// No description provided for @walletBackedUp.
  ///
  /// In en, this message translates to:
  /// **'I have backed it up'**
  String get walletBackedUp;

  /// No description provided for @walletRecoverFromPhrase.
  ///
  /// In en, this message translates to:
  /// **'Recover from Phrase'**
  String get walletRecoverFromPhrase;

  /// No description provided for @walletSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set Default'**
  String get walletSetDefault;

  /// No description provided for @walletSettingPrimary.
  ///
  /// In en, this message translates to:
  /// **'Setting wallet as primary...'**
  String get walletSettingPrimary;

  /// No description provided for @walletPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get walletPrimary;

  /// No description provided for @walletSourceGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get walletSourceGenerated;

  /// No description provided for @walletSourceRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get walletSourceRecovered;

  /// No description provided for @walletSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Address'**
  String get walletSourceManual;

  /// No description provided for @walletDaysHeld.
  ///
  /// In en, this message translates to:
  /// **'Days held: {days}'**
  String walletDaysHeld(String days);

  /// No description provided for @walletCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get walletCalculating;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewardsTitle;

  /// No description provided for @rewardsClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get rewardsClaim;

  /// No description provided for @rewardsClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get rewardsClaimed;

  /// No description provided for @rewardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get rewardsAvailable;

  /// No description provided for @rewardsNoRewards.
  ///
  /// In en, this message translates to:
  /// **'No rewards available'**
  String get rewardsNoRewards;

  /// No description provided for @rewardsSocialTasks.
  ///
  /// In en, this message translates to:
  /// **'Social Tasks'**
  String get rewardsSocialTasks;

  /// No description provided for @rewardsXTasks.
  ///
  /// In en, this message translates to:
  /// **'X Tasks'**
  String get rewardsXTasks;

  /// No description provided for @rewardsTelegramTasks.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get rewardsTelegramTasks;

  /// No description provided for @rewardsDiscordTasks.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get rewardsDiscordTasks;

  /// No description provided for @rewardsAllMissions.
  ///
  /// In en, this message translates to:
  /// **'All Missions'**
  String get rewardsAllMissions;

  /// No description provided for @rewardsNoMissions.
  ///
  /// In en, this message translates to:
  /// **'No active missions available.'**
  String get rewardsNoMissions;

  /// No description provided for @rewardsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String rewardsError(String error);

  /// No description provided for @gamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesTitle;

  /// No description provided for @gamesPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get gamesPlay;

  /// No description provided for @gamesRunner.
  ///
  /// In en, this message translates to:
  /// **'Cat Runner'**
  String get gamesRunner;

  /// No description provided for @gamesRunnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Run, jump and collect coins!'**
  String get gamesRunnerDescription;

  /// No description provided for @gamesNoGames.
  ///
  /// In en, this message translates to:
  /// **'No games are currently available.'**
  String get gamesNoGames;

  /// No description provided for @referralTitle.
  ///
  /// In en, this message translates to:
  /// **'My Referrals'**
  String get referralTitle;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referralCode;

  /// No description provided for @referralCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get referralCopyCode;

  /// No description provided for @referralShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get referralShareLink;

  /// No description provided for @referralActiveReferrals.
  ///
  /// In en, this message translates to:
  /// **'Active Referrals'**
  String get referralActiveReferrals;

  /// No description provided for @referralNoReferrals.
  ///
  /// In en, this message translates to:
  /// **'No referrals yet'**
  String get referralNoReferrals;

  /// No description provided for @referralBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get referralBoost;

  /// No description provided for @referralBoosted.
  ///
  /// In en, this message translates to:
  /// **'Boosted'**
  String get referralBoosted;

  /// No description provided for @referralInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get referralInviteFriends;

  /// No description provided for @balanceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance Details'**
  String get balanceDetailTitle;

  /// No description provided for @payoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get payoutHistoryTitle;

  /// No description provided for @payoutHistoryNone.
  ///
  /// In en, this message translates to:
  /// **'No payout history'**
  String get payoutHistoryNone;

  /// No description provided for @awardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Awards Room'**
  String get awardsTitle;

  /// No description provided for @socialMissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Missions'**
  String get socialMissionsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get profileAccountDetails;

  /// No description provided for @profileReferredBy.
  ///
  /// In en, this message translates to:
  /// **'Referred By'**
  String get profileReferredBy;

  /// No description provided for @profileMyReferrals.
  ///
  /// In en, this message translates to:
  /// **'My Referrals'**
  String get profileMyReferrals;

  /// No description provided for @profileSocialProfiles.
  ///
  /// In en, this message translates to:
  /// **'Social Profiles for Verification'**
  String get profileSocialProfiles;

  /// No description provided for @profileDiscord.
  ///
  /// In en, this message translates to:
  /// **'Discord Username'**
  String get profileDiscord;

  /// No description provided for @profileTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram User ID (Numeric)'**
  String get profileTelegram;

  /// No description provided for @profileTelegramHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123456789'**
  String get profileTelegramHint;

  /// No description provided for @profileX.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter) Handle'**
  String get profileX;

  /// No description provided for @profileFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook Profile Link/ID'**
  String get profileFacebook;

  /// No description provided for @profileWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get profileWhatsapp;

  /// No description provided for @profileSaveSocialIds.
  ///
  /// In en, this message translates to:
  /// **'Save Social IDs'**
  String get profileSaveSocialIds;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profilePayoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get profilePayoutHistory;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDiscordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Discord Username'**
  String get profileDiscordHint;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified. Tap 🔒 to edit (revokes reward).'**
  String get profileVerified;

  /// No description provided for @profileVerifiedLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Verified and reward locked. Edit the ID and tap Save; you will be asked to confirm reward removal until the new ID is verified.'**
  String get profileVerifiedLockedHint;

  /// No description provided for @profileSocialChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change verified social ID?'**
  String get profileSocialChangeTitle;

  /// No description provided for @profileSocialChangeBody.
  ///
  /// In en, this message translates to:
  /// **'Changing this social ID will remove your current reward until the new ID is verified. Do you want to continue?'**
  String get profileSocialChangeBody;

  /// No description provided for @profileSocialChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileSocialChangeConfirm;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get changePasswordMin6;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get changePasswordSuccess;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone.\n\nAll your mining progress, balance, and referrals will be lost forever.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE PERMANENTLY'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String deleteAccountFailed(String error);

  /// No description provided for @resetSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {platform} ID?'**
  String resetSocialTitle(String platform);

  /// No description provided for @resetSocialMessage.
  ///
  /// In en, this message translates to:
  /// **'Changing a verified social ID will revoke the 100,000 Catoshi mission reward until the new ID is verified again.\n\nAre you sure you want to proceed?'**
  String get resetSocialMessage;

  /// No description provided for @resetSocialUnlocked.
  ///
  /// In en, this message translates to:
  /// **'ID unlocked for editing.'**
  String get resetSocialUnlocked;

  /// No description provided for @resetSocialFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlock: {error}'**
  String resetSocialFailed(String error);

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelectTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు'**
  String get languageTelugu;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get languageMalay;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get languageGujarati;

  /// No description provided for @languageOdia.
  ///
  /// In en, this message translates to:
  /// **'ଓଡ଼િଆ'**
  String get languageOdia;

  /// No description provided for @telegramHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to find your Telegram ID'**
  String get telegramHelpTitle;

  /// No description provided for @telegramHelpStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Telegram and search for @userinfobot'**
  String get telegramHelpStep1;

  /// No description provided for @telegramHelpStep2.
  ///
  /// In en, this message translates to:
  /// **'Start a chat with the bot'**
  String get telegramHelpStep2;

  /// No description provided for @telegramHelpStep3.
  ///
  /// In en, this message translates to:
  /// **'It will reply with your numeric User ID'**
  String get telegramHelpStep3;

  /// No description provided for @missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get missionComplete;

  /// No description provided for @missionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get missionCompleted;

  /// No description provided for @missionClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get missionClaim;

  /// No description provided for @missionClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get missionClaimed;

  /// No description provided for @missionGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get missionGo;

  /// No description provided for @failedPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedPickImage(String error);

  /// No description provided for @awardsNoAwards.
  ///
  /// In en, this message translates to:
  /// **'You have not earned any awards yet.'**
  String get awardsNoAwards;

  /// No description provided for @awardsKeepMining.
  ///
  /// In en, this message translates to:
  /// **'Keep mining and climbing the leaderboards!'**
  String get awardsKeepMining;

  /// No description provided for @balanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get balanceSummary;

  /// No description provided for @balanceEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get balanceEarnings;

  /// No description provided for @balancePayouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get balancePayouts;

  /// No description provided for @balanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load balance details.'**
  String get balanceLoadError;

  /// No description provided for @balanceWithdrawSoon.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned — withdrawals will be activated soon!'**
  String get balanceWithdrawSoon;

  /// No description provided for @balanceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get balanceTotal;

  /// No description provided for @balanceNotWithdrawable.
  ///
  /// In en, this message translates to:
  /// **'Not withdrawable'**
  String get balanceNotWithdrawable;

  /// No description provided for @balanceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings Breakdown'**
  String get balanceBreakdown;

  /// No description provided for @balanceMining.
  ///
  /// In en, this message translates to:
  /// **'Mining Earnings'**
  String get balanceMining;

  /// No description provided for @balanceReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral Earnings'**
  String get balanceReferral;

  /// No description provided for @balanceMission.
  ///
  /// In en, this message translates to:
  /// **'Mission Earnings'**
  String get balanceMission;

  /// No description provided for @balanceGame.
  ///
  /// In en, this message translates to:
  /// **'Game Earnings'**
  String get balanceGame;

  /// No description provided for @balanceWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get balanceWithdraw;

  /// No description provided for @balanceWithdrawSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted!'**
  String get balanceWithdrawSubmitted;

  /// No description provided for @balanceNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No earnings history.'**
  String get balanceNoHistory;

  /// No description provided for @balanceNoPayouts.
  ///
  /// In en, this message translates to:
  /// **'No payout history.'**
  String get balanceNoPayouts;

  /// No description provided for @boostersActiveModifiers.
  ///
  /// In en, this message translates to:
  /// **'Active Session Modifiers'**
  String get boostersActiveModifiers;

  /// No description provided for @boostersCurrentReferralBonus.
  ///
  /// In en, this message translates to:
  /// **'Current Referral Bonus: +{bonus}%'**
  String boostersCurrentReferralBonus(Object bonus);

  /// No description provided for @boostersAvailableModifiers.
  ///
  /// In en, this message translates to:
  /// **'Available Modifiers'**
  String get boostersAvailableModifiers;

  /// No description provided for @boostersApplyExtensions.
  ///
  /// In en, this message translates to:
  /// **'Apply time extensions and activate referral bonuses for your current mining session.'**
  String get boostersApplyExtensions;

  /// No description provided for @boostersStartMiningPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start mining on the dashboard to unlock modifiers!'**
  String get boostersStartMiningPrompt;

  /// No description provided for @boostersNoBoosters.
  ///
  /// In en, this message translates to:
  /// **'No boosters available right now.'**
  String get boostersNoBoosters;

  /// No description provided for @boostersTimeBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'{hours}h Time Boost'**
  String boostersTimeBoostTitle(Object hours);

  /// No description provided for @boostersCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown: {duration}'**
  String boostersCooldown(Object duration);

  /// No description provided for @boostersSessionMaxed.
  ///
  /// In en, this message translates to:
  /// **'Session fully maxed out at 24h.'**
  String get boostersSessionMaxed;

  /// No description provided for @boostersExtendBy.
  ///
  /// In en, this message translates to:
  /// **'Extend your session by {hours}h (Max Capacity)'**
  String boostersExtendBy(Object hours);

  /// No description provided for @boostersExtendBySimple.
  ///
  /// In en, this message translates to:
  /// **'Extend your session by {hours}h'**
  String boostersExtendBySimple(Object hours);

  /// No description provided for @boostersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get boostersApply;

  /// No description provided for @boostersReferralBoosting.
  ///
  /// In en, this message translates to:
  /// **'Boosting your speed by {boost}%'**
  String boostersReferralBoosting(Object boost);

  /// No description provided for @boostersReferralMaxed.
  ///
  /// In en, this message translates to:
  /// **'Referral capacity maxed out.'**
  String get boostersReferralMaxed;

  /// No description provided for @boostersReferralActiveMiner.
  ///
  /// In en, this message translates to:
  /// **'Active miner! Apply for a +{boost}% bonus.'**
  String boostersReferralActiveMiner(Object boost);

  /// No description provided for @boostersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get boostersActive;

  /// No description provided for @boostersErrorMustMine.
  ///
  /// In en, this message translates to:
  /// **'You must start mining first!'**
  String get boostersErrorMustMine;

  /// No description provided for @boostersEnergyPotionConsumed.
  ///
  /// In en, this message translates to:
  /// **'Energy Potion successfully consumed!'**
  String get boostersEnergyPotionConsumed;

  /// No description provided for @boostersErrorFailedToExtend.
  ///
  /// In en, this message translates to:
  /// **'Failed to extend session: {error}'**
  String boostersErrorFailedToExtend(Object error);

  /// No description provided for @boostersReferralActivated.
  ///
  /// In en, this message translates to:
  /// **'Referral boost activated!'**
  String get boostersReferralActivated;

  /// No description provided for @gamesRunnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Cat Runner'**
  String get gamesRunnerTitle;

  /// No description provided for @gamesRunnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Run, jump & earn catoshi!'**
  String get gamesRunnerDesc;

  /// No description provided for @gamesTictactoeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tic Tac Toe'**
  String get gamesTictactoeTitle;

  /// No description provided for @gamesTictactoeDesc.
  ///
  /// In en, this message translates to:
  /// **'Get three in a row to win!'**
  String get gamesTictactoeDesc;

  /// No description provided for @gamesSudokuTitle.
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get gamesSudokuTitle;

  /// No description provided for @gamesSudokuDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill the grid with numbers 1-9.'**
  String get gamesSudokuDesc;

  /// No description provided for @gameSudokuScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String gameSudokuScore(Object score);

  /// No description provided for @gameSudokuMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {mistakes}/3'**
  String gameSudokuMistakes(Object mistakes);

  /// No description provided for @gameSudokuStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak {streak}'**
  String gameSudokuStreak(Object streak);

  /// No description provided for @gameSudokuLevelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get gameSudokuLevelEasy;

  /// No description provided for @gameSudokuLevelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gameSudokuLevelMedium;

  /// No description provided for @gameSudokuLevelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gameSudokuLevelHard;

  /// No description provided for @gameSudokuLevelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get gameSudokuLevelExpert;

  /// No description provided for @gameSudokuUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gameSudokuUndo;

  /// No description provided for @gameSudokuErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get gameSudokuErase;

  /// No description provided for @gameSudokuPencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get gameSudokuPencil;

  /// No description provided for @gameSudokuFastPencil.
  ///
  /// In en, this message translates to:
  /// **'Fast Pencil'**
  String get gameSudokuFastPencil;

  /// No description provided for @gameSudokuHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get gameSudokuHint;

  /// No description provided for @gamesCollageTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Collage'**
  String get gamesCollageTitle;

  /// No description provided for @gamesCollageDesc.
  ///
  /// In en, this message translates to:
  /// **'Arrange the cat pieces to solve the puzzle.'**
  String get gamesCollageDesc;

  /// No description provided for @gamesArrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Escape'**
  String get gamesArrowTitle;

  /// No description provided for @gamesArrowDesc.
  ///
  /// In en, this message translates to:
  /// **'Random layout each round — bent arrows are at least two cells long. Tap to slide along the tip direction; blocked arrows bump back. Clear all before lives run out.'**
  String get gamesArrowDesc;

  /// No description provided for @gameArrowScore.
  ///
  /// In en, this message translates to:
  /// **'Arrows {current}/{target}'**
  String gameArrowScore(Object current, Object target);

  /// No description provided for @gameArrowLives.
  ///
  /// In en, this message translates to:
  /// **'Lives {lives}'**
  String gameArrowLives(Object lives);

  /// No description provided for @gameArrowGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameArrowGameOver;

  /// No description provided for @gameArrowFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Arrow taps: {score}'**
  String gameArrowFinalScore(Object score);

  /// No description provided for @gameArrowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Board cleared! You earned {amount} Catoshi!'**
  String gameArrowSuccess(Object amount);

  /// No description provided for @gamesTwenty48Title.
  ///
  /// In en, this message translates to:
  /// **'2048'**
  String get gamesTwenty48Title;

  /// No description provided for @gamesTwenty48Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach 2048, keep merging — Catoshi scales with your final score when the run ends.'**
  String get gamesTwenty48Desc;

  /// No description provided for @gamesTileSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile Swap'**
  String get gamesTileSwapTitle;

  /// No description provided for @gamesTileSwapDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag a tile onto an adjacent one to swap. Match three or more to clear. Invalid swaps bounce back. Reach the goal before moves run out.'**
  String get gamesTileSwapDesc;

  /// No description provided for @gameTileSwapHudScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String gameTileSwapHudScore(Object score);

  /// No description provided for @gameTileSwapHudMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves {moves}'**
  String gameTileSwapHudMoves(Object moves);

  /// No description provided for @gameTileSwapHudTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal {target}'**
  String gameTileSwapHudTarget(Object target);

  /// No description provided for @gameTileSwapSuccess.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! You earned {amount} Catoshi!'**
  String gameTileSwapSuccess(Object amount);

  /// No description provided for @gameTileSwapLossBody.
  ///
  /// In en, this message translates to:
  /// **'Score {score} — goal was {target}. Try again!'**
  String gameTileSwapLossBody(Object score, Object target);

  /// No description provided for @gameTwenty48Score.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get gameTwenty48Score;

  /// No description provided for @gameTwenty48Best.
  ///
  /// In en, this message translates to:
  /// **'BEST TILE'**
  String get gameTwenty48Best;

  /// No description provided for @gameTwenty48Reached2048.
  ///
  /// In en, this message translates to:
  /// **'2048 reached — keep merging for a bigger payout at game over!'**
  String get gameTwenty48Reached2048;

  /// No description provided for @gameTwenty48GameOver.
  ///
  /// In en, this message translates to:
  /// **'No more moves!'**
  String get gameTwenty48GameOver;

  /// No description provided for @gameTwenty48Restart.
  ///
  /// In en, this message translates to:
  /// **'RESTART'**
  String get gameTwenty48Restart;

  /// No description provided for @gameTwenty48SwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up, down, left or right to slide tiles.'**
  String get gameTwenty48SwipeHint;

  /// No description provided for @gameTwenty48ExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave 2048?'**
  String get gameTwenty48ExitTitle;

  /// No description provided for @gameTwenty48ExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically. You can continue this game later from the games menu.'**
  String get gameTwenty48ExitBody;

  /// No description provided for @gameTwenty48Stay.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get gameTwenty48Stay;

  /// No description provided for @gameTwenty48Leave.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get gameTwenty48Leave;

  /// No description provided for @gameSudokuExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Sudoku?'**
  String get gameSudokuExitTitle;

  /// No description provided for @gameSudokuExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically. You can continue this game later from the games menu.'**
  String get gameSudokuExitBody;

  /// No description provided for @gameCollageExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the collage puzzle?'**
  String get gameCollageExitTitle;

  /// No description provided for @gameCollageExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically. You can continue this puzzle later from the games menu.'**
  String get gameCollageExitBody;

  /// No description provided for @gameTwenty48Success.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount} Catoshi!'**
  String gameTwenty48Success(Object amount);

  /// No description provided for @gameTwenty48KeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep playing for an even higher score before the board fills up.'**
  String get gameTwenty48KeepGoing;

  /// No description provided for @gamesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get gamesComingSoon;

  /// No description provided for @referralsTitle.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralsTitle;

  /// No description provided for @referralsInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Referred by'**
  String get referralsInvitedBy;

  /// No description provided for @referralsNoOneYet.
  ///
  /// In en, this message translates to:
  /// **'No one yet'**
  String get referralsNoOneYet;

  /// No description provided for @referralsYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referralsYourCode;

  /// No description provided for @referralsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get referralsCopied;

  /// No description provided for @referralsShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Catcoin PoE! Use my code {code} to get a bonus.\n\nLink: https://poe.catcoin.in/invite/{code}'**
  String referralsShareMessage(Object code);

  /// No description provided for @referralsTotal.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralsTotal;

  /// No description provided for @referralsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get referralsActiveCount;

  /// No description provided for @referralsBoostPercentage.
  ///
  /// In en, this message translates to:
  /// **'Boost %'**
  String get referralsBoostPercentage;

  /// No description provided for @referralsYourReferrals.
  ///
  /// In en, this message translates to:
  /// **'Your Referrals'**
  String get referralsYourReferrals;

  /// No description provided for @referralsNoReferrals.
  ///
  /// In en, this message translates to:
  /// **'No referrals yet'**
  String get referralsNoReferrals;

  /// No description provided for @referralsSharePrompt.
  ///
  /// In en, this message translates to:
  /// **'Share your referral code to earn bonuses!'**
  String get referralsSharePrompt;

  /// No description provided for @referralsActiveLast24h.
  ///
  /// In en, this message translates to:
  /// **'Actively mining'**
  String get referralsActiveLast24h;

  /// No description provided for @referralsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get referralsInactive;

  /// No description provided for @referralsEnterInviterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Inviter Code'**
  String get referralsEnterInviterCode;

  /// No description provided for @referralsInviterCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'If you were invited by someone, enter their referral code here to link your account to theirs.'**
  String get referralsInviterCodeInstruction;

  /// No description provided for @referralsInviterCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralsInviterCodeLabel;

  /// No description provided for @referralsInviterCodeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Inviter code updated successfully!'**
  String get referralsInviterCodeUpdated;

  /// No description provided for @referralsPingAll.
  ///
  /// In en, this message translates to:
  /// **'Ping inactive referrals'**
  String get referralsPingAll;

  /// No description provided for @referralsPingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ping inactive referrals?'**
  String get referralsPingConfirmTitle;

  /// No description provided for @referralsPingConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Creates in-app reminder records only for referrals who have not opened the app recently (same inactive rule as admin tools). Not a device push. You can do this about once per hour.'**
  String get referralsPingConfirmMessage;

  /// No description provided for @referralsPingResult.
  ///
  /// In en, this message translates to:
  /// **'Pinged: {pinged}, skipped: {skipped}, failed: {failed} (of {total})'**
  String referralsPingResult(
      Object pinged, Object skipped, Object failed, Object total);

  /// Heading for the list of invitees and progress toward the one-time referrer payout
  ///
  /// In en, this message translates to:
  /// **'Referral milestone bonus'**
  String get referralMilestoneBonusTitle;

  /// No description provided for @referralMilestoneBonusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time reward of {amount} catoshi per invite'**
  String referralMilestoneBonusSubtitle(Object amount);

  /// No description provided for @referralBonusRewardAmountNote.
  ///
  /// In en, this message translates to:
  /// **'This reward amount is configured on the server and may be updated by administrators.'**
  String get referralBonusRewardAmountNote;

  /// App bar title for per-referee milestone detail
  ///
  /// In en, this message translates to:
  /// **'Referral bonus'**
  String get referralBonusDetailAppTitle;

  /// No description provided for @referralBonusStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Referral bonus status'**
  String get referralBonusStatusHeading;

  /// No description provided for @referralBonusRewardForReferrer.
  ///
  /// In en, this message translates to:
  /// **'Bonus for you (referrer): {amount} catoshi'**
  String referralBonusRewardForReferrer(Object amount);

  /// No description provided for @referralBonusRewardCredited.
  ///
  /// In en, this message translates to:
  /// **'Reward already credited ({amount} catoshi).'**
  String referralBonusRewardCredited(Object amount);

  /// No description provided for @referralBonusConditionsProgress.
  ///
  /// In en, this message translates to:
  /// **'{met} of 3 conditions met'**
  String referralBonusConditionsProgress(Object met);

  /// No description provided for @referralBonusListAmount.
  ///
  /// In en, this message translates to:
  /// **'Referral bonus: {amount} catoshi'**
  String referralBonusListAmount(Object amount);

  /// No description provided for @referralBonusDatesLine.
  ///
  /// In en, this message translates to:
  /// **'Joined {joined} · Referred {referred}'**
  String referralBonusDatesLine(Object joined, Object referred);

  /// No description provided for @referralBonusConditionMinedDays.
  ///
  /// In en, this message translates to:
  /// **'Mined days'**
  String get referralBonusConditionMinedDays;

  /// No description provided for @referralBonusConditionMiningReward.
  ///
  /// In en, this message translates to:
  /// **'Mining reward (BASE)'**
  String get referralBonusConditionMiningReward;

  /// No description provided for @referralBonusConditionGameReward.
  ///
  /// In en, this message translates to:
  /// **'Game rewards'**
  String get referralBonusConditionGameReward;

  /// No description provided for @referralBonusStatePending.
  ///
  /// In en, this message translates to:
  /// **'Pending conditions'**
  String get referralBonusStatePending;

  /// No description provided for @referralBonusStateEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible for reward'**
  String get referralBonusStateEligible;

  /// No description provided for @referralBonusStateRewarded.
  ///
  /// In en, this message translates to:
  /// **'Reward credited'**
  String get referralBonusStateRewarded;

  /// No description provided for @referralBonusStateUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under admin review'**
  String get referralBonusStateUnderReview;

  /// No description provided for @referralBonusStateRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get referralBonusStateRejected;

  /// No description provided for @profileSetupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get profileSetupSkip;

  /// No description provided for @profileSetupGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileSetupGallery;

  /// No description provided for @profileSetupCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileSetupCamera;

  /// No description provided for @profileSetupFailedImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String profileSetupFailedImage(Object error);

  /// No description provided for @profileSetupDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Optional)'**
  String get profileSetupDisplayNameLabel;

  /// No description provided for @profileSetupDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get profileSetupDisplayNameHint;

  /// No description provided for @profileSetupSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get profileSetupSaveContinue;

  /// No description provided for @profileSetupFailedSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String profileSetupFailedSave(Object error);

  /// No description provided for @socialNoMissions.
  ///
  /// In en, this message translates to:
  /// **'No {title} available right now.'**
  String socialNoMissions(Object title);

  /// No description provided for @payoutHistoryScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get payoutHistoryScreenTitle;

  /// No description provided for @payoutNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No payout history found.'**
  String get payoutNoHistory;

  /// No description provided for @payoutViewTx.
  ///
  /// In en, this message translates to:
  /// **'View TX'**
  String get payoutViewTx;

  /// No description provided for @payoutAddressTo.
  ///
  /// In en, this message translates to:
  /// **'To: {address}'**
  String payoutAddressTo(Object address);

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @missionVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Required'**
  String get missionVerifyTitle;

  /// No description provided for @missionVerifyDiscord.
  ///
  /// In en, this message translates to:
  /// **'Enter your Discord Username so we can verify you joined:'**
  String get missionVerifyDiscord;

  /// No description provided for @missionVerifyTelegram.
  ///
  /// In en, this message translates to:
  /// **'Enter your Numeric Telegram ID:'**
  String get missionVerifyTelegram;

  /// No description provided for @missionVerifyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enter your username/handle to verify:'**
  String get missionVerifyGeneric;

  /// No description provided for @missionHintDiscord.
  ///
  /// In en, this message translates to:
  /// **'Enter Discord Username'**
  String get missionHintDiscord;

  /// No description provided for @missionHintTelegram.
  ///
  /// In en, this message translates to:
  /// **'Enter Numeric ID'**
  String get missionHintTelegram;

  /// No description provided for @missionHintGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enter Username/Handle'**
  String get missionHintGeneric;

  /// No description provided for @missionHelpGetId.
  ///
  /// In en, this message translates to:
  /// **'How to get ID?'**
  String get missionHelpGetId;

  /// No description provided for @missionSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get missionSaveContinue;

  /// No description provided for @missionVerificationStarted.
  ///
  /// In en, this message translates to:
  /// **'Verification started! Please complete the task.'**
  String get missionVerificationStarted;

  /// No description provided for @missionClaimedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Claimed {amount} Catoshi!'**
  String missionClaimedSuccess(Object amount);

  /// No description provided for @missionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String missionFailed(Object error);

  /// No description provided for @missionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get missionExpired;

  /// No description provided for @missionExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String missionExpiresInDays(Object days);

  /// No description provided for @missionExpiresInHours.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours} hours'**
  String missionExpiresInHours(Object hours);

  /// No description provided for @missionReward.
  ///
  /// In en, this message translates to:
  /// **'+{amount} Catoshi'**
  String missionReward(Object amount);

  /// No description provided for @missionStatusVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get missionStatusVerifying;

  /// No description provided for @missionBtnClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get missionBtnClaim;

  /// No description provided for @telegramHelpInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Open Telegram.\n2. Search for @userinfobot (or scan QR below).\n3. Click Start (or send /start).\n4. It will reply with your details. Look for \"Id\".\n5. Copy that number and paste it here.'**
  String get telegramHelpInstructions;

  /// No description provided for @telegramHelpBtnOpen.
  ///
  /// In en, this message translates to:
  /// **'Open @userinfobot'**
  String get telegramHelpBtnOpen;

  /// No description provided for @telegramHelpQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Or Scan QR Code:'**
  String get telegramHelpQrLabel;

  /// No description provided for @telegramHelpQrError.
  ///
  /// In en, this message translates to:
  /// **'QR Code not found.\n(Add assets/images/telegram_qr.png)'**
  String get telegramHelpQrError;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully. Please login.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get resetPasswordFailed;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email} and your new password.'**
  String resetPasswordInstruction(Object email);

  /// No description provided for @emailVerificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email!'**
  String get emailVerificationCodeSent;

  /// No description provided for @gameLauncherTitle.
  ///
  /// In en, this message translates to:
  /// **'Cat Runner'**
  String get gameLauncherTitle;

  /// No description provided for @gameLauncherDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading Game Assets...'**
  String get gameLauncherDownloading;

  /// No description provided for @gameLauncherReady.
  ///
  /// In en, this message translates to:
  /// **'Engine Ready'**
  String get gameLauncherReady;

  /// No description provided for @gameLauncherRequired.
  ///
  /// In en, this message translates to:
  /// **'Game Assets Required'**
  String get gameLauncherRequired;

  /// No description provided for @gameLauncherDownloadBtn.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD ASSETS (~{size})'**
  String gameLauncherDownloadBtn(Object size);

  /// No description provided for @gameLauncherStartBtn.
  ///
  /// In en, this message translates to:
  /// **'START GAME'**
  String get gameLauncherStartBtn;

  /// No description provided for @gameLauncherResetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Assets'**
  String get gameLauncherResetBtn;

  /// No description provided for @gameNewGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get gameNewGame;

  /// No description provided for @gameYouWin.
  ///
  /// In en, this message translates to:
  /// **'You Win!'**
  String get gameYouWin;

  /// No description provided for @gameCpuWins.
  ///
  /// In en, this message translates to:
  /// **'CPU Wins!'**
  String get gameCpuWins;

  /// No description provided for @gameDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get gameDraw;

  /// No description provided for @gameYourTurnX.
  ///
  /// In en, this message translates to:
  /// **'Your Turn (X)'**
  String get gameYourTurnX;

  /// No description provided for @gameYourTurnO.
  ///
  /// In en, this message translates to:
  /// **'Your Turn (O)'**
  String get gameYourTurnO;

  /// No description provided for @gameWinReward.
  ///
  /// In en, this message translates to:
  /// **'Win {amount} Catoshi'**
  String gameWinReward(Object amount);

  /// No description provided for @gameSudokuSuccess.
  ///
  /// In en, this message translates to:
  /// **'Awesome! You solved the Sudoku and earned {amount} Catoshi!'**
  String gameSudokuSuccess(Object amount);

  /// No description provided for @gameRewardBoostBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Game Boost'**
  String get gameRewardBoostBonusTitle;

  /// No description provided for @gameRewardBoostBonusBody.
  ///
  /// In en, this message translates to:
  /// **'+{percentage}% mining yield for {minutes} minutes. Open Boosters to activate while mining.'**
  String gameRewardBoostBonusBody(Object percentage, Object minutes);

  /// No description provided for @gameRewardRunnerSummary.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount} Catoshi!'**
  String gameRewardRunnerSummary(Object amount);

  /// No description provided for @gameTictactoeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You earned {amount} Catoshi!'**
  String gameTictactoeSuccess(Object amount);

  /// No description provided for @gamePuzzleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fantastic! You solved the puzzle and earned {amount} Catoshi!'**
  String gamePuzzleSuccess(Object amount);

  /// No description provided for @gameMinerTitle.
  ///
  /// In en, this message translates to:
  /// **'CatCoin Miner'**
  String get gameMinerTitle;

  /// No description provided for @gamesTunnelMinerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunnel Miner'**
  String get gamesTunnelMinerTitle;

  /// No description provided for @gamesTunnelMinerDesc.
  ///
  /// In en, this message translates to:
  /// **'Mine downward, reach the green extraction pad, and avoid hazards.'**
  String get gamesTunnelMinerDesc;

  /// No description provided for @gameRewardMinerSummary.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount} Catoshi!'**
  String gameRewardMinerSummary(Object amount);

  /// No description provided for @tunnelMinerHudDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get tunnelMinerHudDepth;

  /// No description provided for @tunnelMinerHudEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get tunnelMinerHudEnergy;

  /// No description provided for @tunnelMinerHudShards.
  ///
  /// In en, this message translates to:
  /// **'Shards'**
  String get tunnelMinerHudShards;

  /// No description provided for @tunnelMinerDigHint.
  ///
  /// In en, this message translates to:
  /// **'Dig'**
  String get tunnelMinerDigHint;

  /// No description provided for @tunnelMinerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading Tunnel Miner...'**
  String get tunnelMinerLoading;

  /// No description provided for @tunnelMinerIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Tunnel Miner'**
  String get tunnelMinerIntroTitle;

  /// No description provided for @tunnelMinerHowToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get tunnelMinerHowToPlayTitle;

  /// No description provided for @tunnelMinerGoal.
  ///
  /// In en, this message translates to:
  /// **'Descend the tunnel, dig through brown dirt, collect gold ore, and stand on the green extraction pad to finish successfully. Loose dirt, ore, and lava fall downward through air while grey rock stays put. Hazards or running out of energy ends the run.'**
  String get tunnelMinerGoal;

  /// No description provided for @tunnelMinerDoHeading.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get tunnelMinerDoHeading;

  /// No description provided for @tunnelMinerDoBody.
  ///
  /// In en, this message translates to:
  /// **'• Move left or right into open space: air, gold ore, or the green extraction pad.\n• Dig straight down through brown dirt only. Each dig uses drill energy.\n• Walk onto ore to collect shards and recharge drill energy.\n• Reach and stand on the green extraction pad to complete a good run.\n• Brown dirt or grey rock beside you? Press left or right toward it again to mine sideways (grey rock costs double energy).'**
  String get tunnelMinerDoBody;

  /// No description provided for @tunnelMinerDontHeading.
  ///
  /// In en, this message translates to:
  /// **'What not to do'**
  String get tunnelMinerDontHeading;

  /// No description provided for @tunnelMinerDontBody.
  ///
  /// In en, this message translates to:
  /// **'• Do not step on red lava — you lose immediately.\n• Do not stand under loose dirt, ore, or lava when there is only air beneath them — they fall; grey rock does not move and acts as a shelf. Falling ore is usually collectible; dirt or lava landing on you ends the run.\n• Do not try to dig grey rock — it cannot be broken; move around it.\n• Do not spend all energy — when energy reaches zero, the run ends.'**
  String get tunnelMinerDontBody;

  /// No description provided for @tunnelMinerControlsHeading.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get tunnelMinerControlsHeading;

  /// No description provided for @tunnelMinerControlsBody.
  ///
  /// In en, this message translates to:
  /// **'Bottom row: move left, dig down, move right.\nYou can also tap the left third, center, or right third of the mine area for the same actions.\nToward brown dirt or grey rock on your side, tap that direction again to chip through (grey rock uses extra energy).\nKeyboard: A or Left Arrow, D or Right Arrow to move; Space, S, or Down Arrow to dig.\nPause: tap the pause icon at the top.'**
  String get tunnelMinerControlsBody;

  /// No description provided for @tunnelMinerIntroTap.
  ///
  /// In en, this message translates to:
  /// **'Read the notes above, then tap Start when you are ready.'**
  String get tunnelMinerIntroTap;

  /// No description provided for @tunnelMinerStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start mining'**
  String get tunnelMinerStartButton;

  /// No description provided for @tunnelMinerWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get tunnelMinerWhatHappened;

  /// No description provided for @tunnelMinerLossExplainLava.
  ///
  /// In en, this message translates to:
  /// **'You stepped on or fell into lava.'**
  String get tunnelMinerLossExplainLava;

  /// No description provided for @tunnelMinerLossExplainBoulder.
  ///
  /// In en, this message translates to:
  /// **'Something heavy fell on you.'**
  String get tunnelMinerLossExplainBoulder;

  /// No description provided for @tunnelMinerLossExplainEnergy.
  ///
  /// In en, this message translates to:
  /// **'Your drill ran out of power.'**
  String get tunnelMinerLossExplainEnergy;

  /// No description provided for @tunnelMinerLossExplainUnknown.
  ///
  /// In en, this message translates to:
  /// **'The run ended before extraction.'**
  String get tunnelMinerLossExplainUnknown;

  /// No description provided for @tunnelMinerReviewMap.
  ///
  /// In en, this message translates to:
  /// **'Review map'**
  String get tunnelMinerReviewMap;

  /// No description provided for @tunnelMinerBackToSummary.
  ///
  /// In en, this message translates to:
  /// **'Back to summary'**
  String get tunnelMinerBackToSummary;

  /// No description provided for @tunnelMinerMapReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Study the field. Return to the summary for Play again or Exit.'**
  String get tunnelMinerMapReviewHint;

  /// No description provided for @tunnelMinerResultExtracted.
  ///
  /// In en, this message translates to:
  /// **'EXTRACTED'**
  String get tunnelMinerResultExtracted;

  /// No description provided for @tunnelMinerResultReason.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get tunnelMinerResultReason;

  /// No description provided for @tunnelMinerReasonEnergy.
  ///
  /// In en, this message translates to:
  /// **'Drill out of power'**
  String get tunnelMinerReasonEnergy;

  /// No description provided for @tunnelMinerReasonHazard.
  ///
  /// In en, this message translates to:
  /// **'Hazard'**
  String get tunnelMinerReasonHazard;

  /// No description provided for @tunnelMinerReasonExtracted.
  ///
  /// In en, this message translates to:
  /// **'Reached extraction'**
  String get tunnelMinerReasonExtracted;

  /// No description provided for @gameGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get gameGameOverTitle;

  /// No description provided for @gameStatScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameStatScore;

  /// No description provided for @gameStatDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get gameStatDistance;

  /// No description provided for @gameStatCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get gameStatCoins;

  /// No description provided for @gameStatCatoshiEarned.
  ///
  /// In en, this message translates to:
  /// **'Catoshi Earned'**
  String get gameStatCatoshiEarned;

  /// No description provided for @gamePlayAgain.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get gamePlayAgain;

  /// No description provided for @gameCooldownComeBack.
  ///
  /// In en, this message translates to:
  /// **'Come back in {time}'**
  String gameCooldownComeBack(Object time);

  /// No description provided for @gameCooldownLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Play limit reached. Please wait before playing again.'**
  String get gameCooldownLimitReached;

  /// No description provided for @gameExit.
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get gameExit;

  /// No description provided for @gamePausedTitle.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get gamePausedTitle;

  /// No description provided for @gameResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get gameResume;

  /// No description provided for @gameQuit.
  ///
  /// In en, this message translates to:
  /// **'QUIT'**
  String get gameQuit;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateTitle;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateUrlError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch update URL'**
  String get updateUrlError;

  /// No description provided for @balancePayoutTo.
  ///
  /// In en, this message translates to:
  /// **'To: {address}'**
  String balancePayoutTo(Object address);

  /// No description provided for @boostersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supercharge your mining speed & extend sessions!'**
  String get boostersSubtitle;

  /// No description provided for @commonVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get commonVersion;

  /// No description provided for @commonUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get commonUser;

  /// No description provided for @profileVerifiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Verified. Tap to unlock and edit.'**
  String get profileVerifiedTooltip;

  /// No description provided for @walletAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String walletAddressLabel(Object address);

  /// No description provided for @walletGenerationError.
  ///
  /// In en, this message translates to:
  /// **'Generation Error: {error}'**
  String walletGenerationError(Object error);

  /// No description provided for @walletDeleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get walletDeleteWallet;

  /// No description provided for @commonGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get commonGenerate;

  /// No description provided for @badgeWeeklyTop.
  ///
  /// In en, this message translates to:
  /// **'Weekly Top'**
  String get badgeWeeklyTop;

  /// No description provided for @badgeMonthlyTop.
  ///
  /// In en, this message translates to:
  /// **'Monthly Top'**
  String get badgeMonthlyTop;

  /// No description provided for @badgeAllTimeTop.
  ///
  /// In en, this message translates to:
  /// **'All Time Top'**
  String get badgeAllTimeTop;

  /// No description provided for @badgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get badgeVerified;

  /// No description provided for @badgeMonthlyGlobalPodium.
  ///
  /// In en, this message translates to:
  /// **'Monthly global podium'**
  String get badgeMonthlyGlobalPodium;

  /// No description provided for @badgeMonthlyRegionalPodium.
  ///
  /// In en, this message translates to:
  /// **'Monthly regional podium'**
  String get badgeMonthlyRegionalPodium;

  /// No description provided for @badgeMonthlyGamePodium.
  ///
  /// In en, this message translates to:
  /// **'Monthly game champion'**
  String get badgeMonthlyGamePodium;

  /// No description provided for @awardDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Award details'**
  String get awardDetailTitle;

  /// No description provided for @awardDetailMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month achieved'**
  String get awardDetailMonthLabel;

  /// No description provided for @awardDetailTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Award type'**
  String get awardDetailTypeLabel;

  /// No description provided for @awardDetailHowLabel.
  ///
  /// In en, this message translates to:
  /// **'How it was achieved'**
  String get awardDetailHowLabel;

  /// No description provided for @awardDetailHowFallback.
  ///
  /// In en, this message translates to:
  /// **'Details for this award were not stored. Contact support if this looks wrong.'**
  String get awardDetailHowFallback;

  /// No description provided for @awardDetailRankScope.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} · {scope}'**
  String awardDetailRankScope(int rank, String scope);

  /// No description provided for @awardDetailScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get awardDetailScopeGlobal;

  /// No description provided for @awardDetailScopeRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get awardDetailScopeRegional;

  /// No description provided for @awardDetailScopeGame.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get awardDetailScopeGame;

  /// No description provided for @awardDetailRegion.
  ///
  /// In en, this message translates to:
  /// **'Region: {code}'**
  String awardDetailRegion(String code);

  /// No description provided for @awardDetailGame.
  ///
  /// In en, this message translates to:
  /// **'Game: {name}'**
  String awardDetailGame(String name);

  /// No description provided for @awardsPrevMonthPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous month ({month})'**
  String awardsPrevMonthPeriod(String month);

  /// No description provided for @awardsPrevMonthGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global top miners'**
  String get awardsPrevMonthGlobal;

  /// No description provided for @awardsPrevMonthRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional top miners (your country)'**
  String get awardsPrevMonthRegional;

  /// No description provided for @awardsPrevMonthGames.
  ///
  /// In en, this message translates to:
  /// **'Game champions'**
  String get awardsPrevMonthGames;

  /// No description provided for @profileShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Showcase badges'**
  String get profileShowcaseTitle;

  /// No description provided for @profileShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 6 earned awards to show on your profile.'**
  String get profileShowcaseSubtitle;

  /// No description provided for @profileShowcaseManage.
  ///
  /// In en, this message translates to:
  /// **'Choose badges'**
  String get profileShowcaseManage;

  /// No description provided for @profileShowcaseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No badges on showcase yet.'**
  String get profileShowcaseEmpty;

  /// No description provided for @profileShowcaseMax.
  ///
  /// In en, this message translates to:
  /// **'You can showcase at most 6 badges.'**
  String get profileShowcaseMax;

  /// No description provided for @profileShowcaseSave.
  ///
  /// In en, this message translates to:
  /// **'Save showcase'**
  String get profileShowcaseSave;

  /// No description provided for @awardDetailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get awardDetailClose;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version ({version}) is available.'**
  String updateAvailable(Object version);

  /// No description provided for @updateMandatory.
  ///
  /// In en, this message translates to:
  /// **'This update is mandatory to continue using the app.'**
  String get updateMandatory;

  /// No description provided for @boostersGameBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Boost +{percentage}%'**
  String boostersGameBoostTitle(String percentage);

  /// No description provided for @boostersGameBoostDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {hours}h {minutes}m'**
  String boostersGameBoostDuration(String hours, String minutes);

  /// No description provided for @boostersActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get boostersActivate;

  /// No description provided for @boostersGameBoostSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game Boost activated successfully!'**
  String get boostersGameBoostSuccess;

  /// No description provided for @boostersGameBoostError.
  ///
  /// In en, this message translates to:
  /// **'Failed to activate boost: {error}'**
  String boostersGameBoostError(String error);

  /// No description provided for @languageGroupInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get languageGroupInternational;

  /// No description provided for @languageGroupIndian.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get languageGroupIndian;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'es',
        'fr',
        'gu',
        'hi',
        'id',
        'ja',
        'ko',
        'ms',
        'or',
        'ru',
        'ta',
        'te',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'or':
      return AppLocalizationsOr();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
