// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'હોમ';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'રમતો';

  @override
  String get navLeaders => 'લીડર્સ';

  @override
  String get navWallet => 'વૉલેટ';

  @override
  String get navRewards => 'ઇનામ';

  @override
  String get navProfile => 'પ્રોફાઇલ';

  @override
  String get commonCancel => 'રદ કરો';

  @override
  String get commonSave => 'સાચવો';

  @override
  String get commonOk => 'ચોક્કસ';

  @override
  String get commonError => 'ભૂલ';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'લોડ કરી રહ્યું છે...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNone => 'None';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonRemovePhoto => 'Remove Photo';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonUnlockEdit => 'Unlock & Edit';

  @override
  String get loginTitle => 'લોગિન';

  @override
  String get loginEmailOrUsername => 'Email or Username';

  @override
  String get loginEmailHint => 'your.email@example.com or 900123456';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'લોગિન';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginUseEmailForVerification =>
      'Please login with your Email to complete verification.';

  @override
  String get signupTitle => 'સાઇન અપ';

  @override
  String get signupEmail => 'Email';

  @override
  String get signupEmailHint => 'your.email@example.com';

  @override
  String get signupPassword => 'Password';

  @override
  String get signupConfirmPassword => 'Confirm Password';

  @override
  String get signupReferralCode => 'Referral Code (Optional)';

  @override
  String get signupReferralCodeHint => 'Enter referral code if you have one';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'સાઇન અપ';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordEmail => 'Email';

  @override
  String get forgotPasswordSendCode => 'Send Reset Code';

  @override
  String get forgotPasswordBackToLogin => 'Back to Login';

  @override
  String get emailVerificationTitle => 'Email Verification';

  @override
  String get emailVerificationInstruction =>
      'Enter the verification code sent to';

  @override
  String get emailVerificationCode => 'Verification Code';

  @override
  String get emailVerificationVerify => 'Verify';

  @override
  String get emailVerificationResend => 'Resend Code';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordNewPassword => 'New Password';

  @override
  String get resetPasswordConfirm => 'Confirm New Password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get profileSetupTitle => 'Setup Profile';

  @override
  String get splashLoading => 'લોડ કરી રહ્યું છે...';

  @override
  String get dashboardTotalBalance => 'કુલ બેલેન્સ';

  @override
  String get dashboardCatoshi => 'catoshi';

  @override
  String get dashboardCatoshiLabel => 'Catoshi';

  @override
  String get dashboardNotMining => 'Not Mining';

  @override
  String get dashboardStartMining => 'માઇનિંગ શરૂ કરો';

  @override
  String dashboardRewardRate(Object rate) {
    return 'Reward Rate: $rate Catoshi/sec';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'Current duration: ${hours}h / ${maxHours}h max';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'બૂસ્ટર્સ';

  @override
  String get boostersCardTitle => 'Boosters';

  @override
  String get boostersCardDescription =>
      'Supercharge your mining speed & extend sessions!';

  @override
  String get boostersOpenScreen => 'View Boosters';

  @override
  String get leaderboardTitle => 'લીડરબોર્ડ';

  @override
  String get leaderboardTopMiners => 'Top Miners';

  @override
  String get leaderboardRank => 'ક્રમ';

  @override
  String get leaderboardUser => 'વપરાશકર્તા';

  @override
  String get leaderboardBalance => 'બેલેન્સ';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardGlobal => 'Global';

  @override
  String get leaderboardRegional => 'Regional';

  @override
  String get leaderboardGames => 'Games';

  @override
  String get leaderboardAwards => 'Awards';

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
  String get leaderboardChallengers => 'Challengers';

  @override
  String get leaderboardNoGlobal => 'No global miners found.';

  @override
  String get leaderboardNoRegional => 'No regional miners found.';

  @override
  String get leaderboardComingSoon =>
      'Coming soon — compete across mini-games!';

  @override
  String get leaderboardNoAwards => 'No awards yet';

  @override
  String get leaderboardKeepMining => 'Keep mining to claim the podium!';

  @override
  String get walletTitle => 'વૉલેટ';

  @override
  String get walletAddress => 'સરનામું';

  @override
  String get walletBalance => 'બેલેન્સ';

  @override
  String get walletCopy => 'Copy';

  @override
  String get walletCopied => 'Copied!';

  @override
  String get walletSend => 'Send';

  @override
  String get walletReceive => 'Receive';

  @override
  String get walletTransactions => 'ટ્રાન્ઝેક્શન';

  @override
  String get walletNoTransactions => 'No transactions yet';

  @override
  String get walletConnectWallet => 'Connect Wallet';

  @override
  String get walletDisconnect => 'Disconnect';

  @override
  String get walletSolanaAddress => 'Solana Address';

  @override
  String get walletEnterAddress => 'Enter Solana address';

  @override
  String get walletSaveAddress => 'Save Address';

  @override
  String get walletAddressSaved => 'Address saved!';

  @override
  String get walletInvalidAddress => 'Invalid Solana address';

  @override
  String get walletMyWallets => 'My Wallets';

  @override
  String get walletAddExisting => 'Add Existing Address';

  @override
  String get walletCatcoinAddress => 'Catcoin Address';

  @override
  String get walletPasteHint => 'Paste address here';

  @override
  String get walletSetPrimary => 'Set as Primary';

  @override
  String get walletInvalidAddressComplex =>
      'Invalid Address. Must be a valid BEP20 (0x...), Solana, or Catcoin (starts with 9) address.';

  @override
  String get walletRecoverTitle => 'Recover Wallet';

  @override
  String get walletRecoverInstruction =>
      'Enter your 24-word secret phrase to recover your wallet.';

  @override
  String get walletSecretPhrase => 'Secret Phrase';

  @override
  String get walletSecretPhraseHint => 'word1 word2 ... word24';

  @override
  String get walletInvalidPhrase => 'Invalid phrase. Must be exactly 24 words.';

  @override
  String get walletDeleteTitle => 'Delete Wallet';

  @override
  String walletDeleteConfirmMessage(String address) {
    return 'Are you sure you want to delete wallet $address? This action cannot be undone if you do not have the private key/phrase.';
  }

  @override
  String get walletDeletedSuccess => 'Wallet deleted successfully';

  @override
  String get walletAddedSuccess => 'Wallet added successfully';

  @override
  String get walletGenerateTitle => 'Generate New Wallet';

  @override
  String get walletBackupTitle => 'Success! Backup Your Wallet';

  @override
  String get walletBackupWarning =>
      'IMPORTANT: Write down these 24 words in order and keep them safe. You cannot recover your funds without them!';

  @override
  String get walletGenerateInstruction =>
      'This will create a new Catcoin wallet for you. Make sure to back up your secret phrase immediately after creation!';

  @override
  String get walletGenerating => 'Generating keys...';

  @override
  String get walletBackedUp => 'I have backed it up';

  @override
  String get walletRecoverFromPhrase => 'Recover from Phrase';

  @override
  String get walletSetDefault => 'Set Default';

  @override
  String get walletSettingPrimary => 'Setting wallet as primary...';

  @override
  String get walletPrimary => 'Primary';

  @override
  String get walletSourceGenerated => 'Generated';

  @override
  String get walletSourceRecovered => 'Recovered';

  @override
  String get walletSourceManual => 'Manual Address';

  @override
  String walletDaysHeld(String days) {
    return 'Days held: $days';
  }

  @override
  String get walletCalculating => 'Calculating...';

  @override
  String get rewardsTitle => 'ઇનામ';

  @override
  String get rewardsClaim => 'ક્લેમ કરો';

  @override
  String get rewardsClaimed => 'Claimed';

  @override
  String get rewardsAvailable => 'Available';

  @override
  String get rewardsNoRewards => 'No rewards available';

  @override
  String get rewardsSocialTasks => 'સોશિયલ ટાસ્ક';

  @override
  String get rewardsXTasks => 'X ટાસ્ક';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'All Missions';

  @override
  String get rewardsNoMissions => 'No active missions available.';

  @override
  String rewardsError(String error) {
    return 'Error: $error';
  }

  @override
  String get gamesTitle => 'રમતો';

  @override
  String get gamesPlay => 'Play';

  @override
  String get gamesRunner => 'Cat Runner';

  @override
  String get gamesRunnerDescription => 'Run, jump and collect coins!';

  @override
  String get gamesNoGames => 'No games are currently available.';

  @override
  String get referralTitle => 'મારા સંદર્ભો';

  @override
  String get referralCode => 'Your Referral Code';

  @override
  String get referralCopyCode => 'Copy Code';

  @override
  String get referralShareLink => 'Share Link';

  @override
  String get referralActiveReferrals => 'Active Referrals';

  @override
  String get referralNoReferrals => 'No referrals yet';

  @override
  String get referralBoost => 'Boost';

  @override
  String get referralBoosted => 'Boosted';

  @override
  String get referralInviteFriends => 'Invite Friends';

  @override
  String get balanceDetailTitle => 'Balance Details';

  @override
  String get payoutHistoryTitle => 'ચુકવણી ઇતિહાસ';

  @override
  String get payoutHistoryNone => 'No payout history';

  @override
  String get awardsTitle => 'Awards Room';

  @override
  String get socialMissionsTitle => 'Social Missions';

  @override
  String get profileTitle => 'પ્રોફાઇલ';

  @override
  String get profileAccountDetails => 'Account Details';

  @override
  String get profileReferredBy => 'Referred By';

  @override
  String get profileMyReferrals => 'My Referrals';

  @override
  String get profileSocialProfiles => 'Social Profiles for Verification';

  @override
  String get profileDiscord => 'Discord Username';

  @override
  String get profileTelegram => 'Telegram User ID (Numeric)';

  @override
  String get profileTelegramHint => 'e.g. 123456789';

  @override
  String get profileX => 'X (Twitter) Handle';

  @override
  String get profileFacebook => 'Facebook Profile Link/ID';

  @override
  String get profileWhatsapp => 'WhatsApp Number';

  @override
  String get profileSaveSocialIds => 'Save Social IDs';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profilePayoutHistory => 'Payout History';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileLanguage => 'ભાષા';

  @override
  String get profileLogout => 'લોગઆઉટ';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDiscordHint => 'Enter your Discord Username';

  @override
  String get profileVerified => 'Verified. Tap 🔒 to edit (revokes reward).';

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
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordCurrent => 'Current Password';

  @override
  String get changePasswordNew => 'New Password';

  @override
  String get changePasswordConfirm => 'Confirm New Password';

  @override
  String get changePasswordMin6 => 'Min 6 characters';

  @override
  String get changePasswordMismatch => 'Passwords do not match';

  @override
  String get changePasswordSuccess => 'Password changed successfully!';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountMessage =>
      'This action is permanent and cannot be undone.\n\nAll your mining progress, balance, and referrals will be lost forever.';

  @override
  String get deleteAccountConfirm => 'DELETE PERMANENTLY';

  @override
  String deleteAccountFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return 'Edit $platform ID?';
  }

  @override
  String get resetSocialMessage =>
      'Changing a verified social ID will revoke the 100,000 Catoshi mission reward until the new ID is verified again.\n\nAre you sure you want to proceed?';

  @override
  String get resetSocialUnlocked => 'ID unlocked for editing.';

  @override
  String resetSocialFailed(String error) {
    return 'Failed to unlock: $error';
  }

  @override
  String get languageSelectTitle => 'Select Language';

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
  String get telegramHelpTitle => 'How to find your Telegram ID';

  @override
  String get telegramHelpStep1 => 'Open Telegram and search for @userinfobot';

  @override
  String get telegramHelpStep2 => 'Start a chat with the bot';

  @override
  String get telegramHelpStep3 => 'It will reply with your numeric User ID';

  @override
  String get missionComplete => 'Complete';

  @override
  String get missionCompleted => 'Completed';

  @override
  String get missionClaim => 'Claim';

  @override
  String get missionClaimed => 'Claimed';

  @override
  String get missionGo => 'Go';

  @override
  String failedPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get awardsNoAwards => 'You have not earned any awards yet.';

  @override
  String get awardsKeepMining => 'Keep mining and climbing the leaderboards!';

  @override
  String get balanceSummary => 'Summary';

  @override
  String get balanceEarnings => 'Earnings';

  @override
  String get balancePayouts => 'Payouts';

  @override
  String get balanceLoadError => 'Failed to load balance details.';

  @override
  String get balanceWithdrawSoon =>
      'Stay tuned — withdrawals will be activated soon!';

  @override
  String get balanceTotal => 'Total Balance';

  @override
  String get balanceNotWithdrawable => 'Not withdrawable';

  @override
  String get balanceBreakdown => 'Earnings Breakdown';

  @override
  String get balanceMining => 'Mining Earnings';

  @override
  String get balanceReferral => 'Referral Earnings';

  @override
  String get balanceMission => 'Mission Earnings';

  @override
  String get balanceGame => 'Game Earnings';

  @override
  String get balanceWithdraw => 'Withdraw';

  @override
  String get balanceWithdrawSubmitted => 'Withdrawal request submitted!';

  @override
  String get balanceNoHistory => 'No earnings history.';

  @override
  String get balanceNoPayouts => 'No payout history.';

  @override
  String get boostersActiveModifiers => 'Active Session Modifiers';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'Current Referral Bonus: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'Available Modifiers';

  @override
  String get boostersApplyExtensions =>
      'Apply time extensions and activate referral bonuses for your current mining session.';

  @override
  String get boostersStartMiningPrompt =>
      'Start mining on the dashboard to unlock modifiers!';

  @override
  String get boostersNoBoosters => 'No boosters available right now.';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return '${hours}h Time Boost';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'Cooldown: $duration';
  }

  @override
  String get boostersSessionMaxed => 'Session fully maxed out at 24h.';

  @override
  String boostersExtendBy(Object hours) {
    return 'Extend your session by ${hours}h (Max Capacity)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return 'Extend your session by ${hours}h';
  }

  @override
  String get boostersApply => 'Apply';

  @override
  String boostersReferralBoosting(Object boost) {
    return 'Currently boosting your speed! (Active) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'Referral capacity maxed out.';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return 'Active miner! Apply for a +$boost% bonus.';
  }

  @override
  String get boostersActive => 'Active';

  @override
  String get boostersErrorMustMine => 'You must start mining first!';

  @override
  String get boostersEnergyPotionConsumed =>
      'Energy Potion successfully consumed!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'Failed to extend session: $error';
  }

  @override
  String get boostersReferralActivated => 'Referral boost activated!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => 'Run, jump & earn catoshi!';

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
  String get gamesComingSoon => 'Coming soon...';

  @override
  String get referralsTitle => 'રેફરલ્સ';

  @override
  String get referralsInvitedBy => 'Referred by';

  @override
  String get referralsNoOneYet => 'No one yet';

  @override
  String get referralsYourCode => 'તમારો કોડ';

  @override
  String get referralsCopied => 'Copied to clipboard';

  @override
  String referralsShareMessage(Object code) {
    return 'Join me on Catcoin PoE! Use my code $code to get a bonus.\n\nLink: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'કુલ';

  @override
  String get referralsActiveCount => 'સક્રિય';

  @override
  String get referralsBoostPercentage => 'Boost %';

  @override
  String get referralsYourReferrals => 'Your Referrals';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'Active (Last 24h)';

  @override
  String get referralsInactive => 'Inactive';

  @override
  String get referralsEnterInviterCode => 'Enter Inviter Code';

  @override
  String get referralsInviterCodeInstruction =>
      'If you were invited by someone, enter their referral code here to link your account to theirs.';

  @override
  String get referralsInviterCodeLabel => 'Referral Code';

  @override
  String get referralsInviterCodeUpdated =>
      'Inviter code updated successfully!';

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
  String get referralMilestoneBonusTitle => 'રેફરલ માઇલસ્ટોન બોનસ';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'દરેક આમંત્રણ માટે $amount કેટોશીનો એક વાર પુરસ્કાર';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'આ બોનસ રકમ સર્વર પર રૂપરેખાંકિત છે અને એડમિન અપડેટ કરી શકે છે.';

  @override
  String get referralBonusDetailAppTitle => 'રેફરલ બોનસ';

  @override
  String get referralBonusStatusHeading => 'રેફરલ બોનસ સ્થિતિ';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'તમારા માટે (રેફરર): $amount કેટોશી';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'બોનસ પહેલેથી જમા થયો ($amount કેટોશી).';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '3 માંથી $met શરતો પૂર્ણ';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'રેફરલ બોનસ: $amount કેટોશી';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'જોડાયા $joined · રેફર કર્યા $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'માઇનિંગ દિવસો';

  @override
  String get referralBonusConditionMiningReward => 'માઇનિંગ ઇનામ (BASE)';

  @override
  String get referralBonusConditionGameReward => 'ગેમ ઇનામો';

  @override
  String get referralBonusStatePending => 'શરતો બાકી';

  @override
  String get referralBonusStateEligible => 'ઇનામ માટે યોગ્ય';

  @override
  String get referralBonusStateRewarded => 'ઇનામ જમા';

  @override
  String get referralBonusStateUnderReview => 'એડમિન સમીક્ષામાં';

  @override
  String get referralBonusStateRejected => 'નકાર્યું';

  @override
  String get profileSetupSkip => 'Skip';

  @override
  String get profileSetupGallery => 'Gallery';

  @override
  String get profileSetupCamera => 'Camera';

  @override
  String profileSetupFailedImage(Object error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'Display Name (Optional)';

  @override
  String get profileSetupDisplayNameHint => 'How should we call you?';

  @override
  String get profileSetupSaveContinue => 'Save & Continue';

  @override
  String profileSetupFailedSave(Object error) {
    return 'Failed to save profile: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return 'No $title available right now.';
  }

  @override
  String get payoutHistoryScreenTitle => 'Payout History';

  @override
  String get payoutNoHistory => 'કોઈ ઇતિહાસ નથી';

  @override
  String get payoutViewTx => 'View TX';

  @override
  String payoutAddressTo(Object address) {
    return 'To: $address';
  }

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get missionVerifyTitle => 'Verification Required';

  @override
  String get missionVerifyDiscord =>
      'Enter your Discord Username so we can verify you joined:';

  @override
  String get missionVerifyTelegram => 'Enter your Numeric Telegram ID:';

  @override
  String get missionVerifyGeneric => 'Enter your username/handle to verify:';

  @override
  String get missionHintDiscord => 'Enter Discord Username';

  @override
  String get missionHintTelegram => 'Enter Numeric ID';

  @override
  String get missionHintGeneric => 'Enter Username/Handle';

  @override
  String get missionHelpGetId => 'How to get ID?';

  @override
  String get missionSaveContinue => 'Save & Continue';

  @override
  String get missionVerificationStarted =>
      'Verification started! Please complete the task.';

  @override
  String missionClaimedSuccess(Object amount) {
    return 'Claimed $amount Catoshi!';
  }

  @override
  String missionFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String get missionExpired => 'Expired';

  @override
  String missionExpiresInDays(Object days) {
    return 'Expires in $days days';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return 'Expires in $hours hours';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'Verifying...';

  @override
  String get missionBtnClaim => 'Claim';

  @override
  String get telegramHelpInstructions =>
      '1. Open Telegram.\n2. Search for @userinfobot (or scan QR below).\n3. Click Start (or send /start).\n4. It will reply with your details. Look for \"Id\".\n5. Copy that number and paste it here.';

  @override
  String get telegramHelpBtnOpen => 'Open @userinfobot';

  @override
  String get telegramHelpQrLabel => 'Or Scan QR Code:';

  @override
  String get telegramHelpQrError =>
      'QR Code not found.\n(Add assets/images/telegram_qr.png)';

  @override
  String get resetPasswordSuccess =>
      'Password reset successfully. Please login.';

  @override
  String get resetPasswordFailed => 'Failed to reset password';

  @override
  String resetPasswordInstruction(Object email) {
    return 'Enter the 6-digit code sent to $email and your new password.';
  }

  @override
  String get emailVerificationCodeSent =>
      'Verification code sent to your email!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => 'Downloading Game Assets...';

  @override
  String get gameLauncherReady => 'Engine Ready';

  @override
  String get gameLauncherRequired => 'Game Assets Required';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'DOWNLOAD ASSETS (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'START GAME';

  @override
  String get gameLauncherResetBtn => 'Reset Assets';

  @override
  String get gameNewGame => 'નવી રમત';

  @override
  String get gameYouWin => 'તમે જીત્યા!';

  @override
  String get gameCpuWins => 'કમ્પ્યુટર જીત્યું';

  @override
  String get gameDraw => 'ડ્રો!';

  @override
  String get gameYourTurnX => 'તમારી વારો (X)';

  @override
  String get gameYourTurnO => 'કમ્પ્યુટરનો વારો (O)';

  @override
  String gameWinReward(Object amount) {
    return 'Win $amount Catoshi';
  }

  @override
  String gameSudokuSuccess(Object amount) {
    return 'સરસ! તમે સુડોકુ ઉકેલ્યું અને $amount catoshi મેળવ્યા!';
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
    return 'અભિનંદન! તમે $amount catoshi મેળવ્યા!';
  }

  @override
  String gamePuzzleSuccess(Object amount) {
    return 'શ્રેષ્ઠ! તમે પઝલ ઉકેલી અને $amount catoshi મેળવ્યા!';
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
  String get gameGameOverTitle => 'GAME OVER';

  @override
  String get gameStatScore => 'Score';

  @override
  String get gameStatDistance => 'Distance';

  @override
  String get gameStatCoins => 'Coins';

  @override
  String get gameStatCatoshiEarned => 'Catoshi Earned';

  @override
  String get gamePlayAgain => 'PLAY AGAIN';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'EXIT';

  @override
  String get gamePausedTitle => 'PAUSED';

  @override
  String get gameResume => 'RESUME';

  @override
  String get gameQuit => 'QUIT';

  @override
  String get updateTitle => 'Update Available';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateUrlError => 'Could not launch update URL';

  @override
  String balancePayoutTo(Object address) {
    return 'To: $address';
  }

  @override
  String get boostersSubtitle =>
      'Supercharge your mining speed & extend sessions!';

  @override
  String get commonVersion => 'Version';

  @override
  String get commonUser => 'User';

  @override
  String get profileVerifiedTooltip => 'Verified. Tap to unlock and edit.';

  @override
  String walletAddressLabel(Object address) {
    return 'Address: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'Generation Error: $error';
  }

  @override
  String get walletDeleteWallet => 'Delete Wallet';

  @override
  String get commonGenerate => 'Generate';

  @override
  String get badgeWeeklyTop => 'Weekly Top';

  @override
  String get badgeMonthlyTop => 'Monthly Top';

  @override
  String get badgeAllTimeTop => 'All Time Top';

  @override
  String get badgeVerified => 'Verified User';

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
    return 'A new version ($version) is available.';
  }

  @override
  String get updateMandatory =>
      'This update is mandatory to continue using the app.';

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
  String get languageGroupInternational => 'આંતરરાષ્ટ્રીય';

  @override
  String get languageGroupIndian => 'ભારત';
}
