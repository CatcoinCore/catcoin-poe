// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => '首页';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => '游戏';

  @override
  String get navLeaders => '排行榜';

  @override
  String get navWallet => '钱包';

  @override
  String get navRewards => '奖励';

  @override
  String get navProfile => '个人资料';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonOk => '确定';

  @override
  String get commonError => '错误';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonRetry => '重试';

  @override
  String get commonClose => '关闭';

  @override
  String get commonNone => '无';

  @override
  String get commonGallery => '相册';

  @override
  String get commonCamera => '相机';

  @override
  String get commonRemovePhoto => '删除照片';

  @override
  String get commonRequired => '必填';

  @override
  String get commonUnlockEdit => '解锁并编辑';

  @override
  String get loginTitle => '登录';

  @override
  String get loginEmailOrUsername => '邮箱或用户名';

  @override
  String get loginEmailHint => 'your.email@example.com 或 900123456';

  @override
  String get loginPassword => '密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginCreateAccount => '创建账号';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginUseEmailForVerification => '请使用邮箱登录以完成验证。';

  @override
  String get signupTitle => '注册';

  @override
  String get signupEmail => '邮箱';

  @override
  String get signupEmailHint => 'your.email@example.com';

  @override
  String get signupPassword => '密码';

  @override
  String get signupConfirmPassword => '确认密码';

  @override
  String get signupReferralCode => '推荐码（可选）';

  @override
  String get signupReferralCodeHint => '如有推荐码请输入';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => '注册';

  @override
  String get forgotPasswordTitle => '忘记密码';

  @override
  String get forgotPasswordEmail => '邮箱';

  @override
  String get forgotPasswordSendCode => '发送重置码';

  @override
  String get forgotPasswordBackToLogin => '返回登录';

  @override
  String get emailVerificationTitle => '邮箱验证';

  @override
  String get emailVerificationInstruction => '请输入发送到以下邮箱的验证码：';

  @override
  String get emailVerificationCode => '验证码';

  @override
  String get emailVerificationVerify => '验证';

  @override
  String get emailVerificationResend => '重新发送';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get resetPasswordNewPassword => '新密码';

  @override
  String get resetPasswordConfirm => '确认新密码';

  @override
  String get resetPasswordButton => '重置密码';

  @override
  String get profileSetupTitle => '设置个人资料';

  @override
  String get splashLoading => '加载中...';

  @override
  String get dashboardTotalBalance => '总余额';

  @override
  String get dashboardCatoshi => '卡托希';

  @override
  String get dashboardCatoshiLabel => '卡托希';

  @override
  String get dashboardNotMining => '未在挖矿';

  @override
  String get dashboardStartMining => '开始挖矿';

  @override
  String dashboardRewardRate(Object rate) {
    return '奖励率：$rate Catoshi/秒';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return '当前时长：${hours}h / 最大 ${maxHours}h';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => '加速器';

  @override
  String get boostersCardTitle => '加速器';

  @override
  String get boostersCardDescription => '提高挖矿速度并延长挖矿时长！';

  @override
  String get boostersOpenScreen => '查看加速器';

  @override
  String get leaderboardTitle => '排行榜';

  @override
  String get leaderboardTopMiners => '顶级矿工';

  @override
  String get leaderboardRank => '排名';

  @override
  String get leaderboardUser => '用户';

  @override
  String get leaderboardBalance => '余额';

  @override
  String get leaderboardYou => '你';

  @override
  String get leaderboardGlobal => '全球';

  @override
  String get leaderboardRegional => '地区';

  @override
  String get leaderboardGames => '游戏';

  @override
  String get leaderboardAwards => '奖项';

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
  String get leaderboardChallengers => '挑战者';

  @override
  String get leaderboardNoGlobal => '未发现全球矿工。';

  @override
  String get leaderboardNoRegional => '未发现地区矿工。';

  @override
  String get leaderboardComingSoon => '即将推出 — 参加小游戏竞赛！';

  @override
  String get leaderboardNoAwards => '暂无奖项';

  @override
  String get leaderboardKeepMining => '继续挖矿以登上领奖台！';

  @override
  String get walletTitle => '钱包';

  @override
  String get walletAddress => '钱包地址';

  @override
  String get walletBalance => '余额';

  @override
  String get walletCopy => '复制';

  @override
  String get walletCopied => '已复制！';

  @override
  String get walletSend => '发送';

  @override
  String get walletReceive => '接收';

  @override
  String get walletTransactions => '交易';

  @override
  String get walletNoTransactions => '暂无交易';

  @override
  String get walletConnectWallet => '连接钱包';

  @override
  String get walletDisconnect => '断开连接';

  @override
  String get walletSolanaAddress => 'Solana 地址';

  @override
  String get walletEnterAddress => '输入 Solana 地址';

  @override
  String get walletSaveAddress => '保存地址';

  @override
  String get walletAddressSaved => '地址已保存！';

  @override
  String get walletInvalidAddress => '无效的 Solana 地址';

  @override
  String get walletMyWallets => '我的钱包';

  @override
  String get walletAddExisting => '添加现有地址';

  @override
  String get walletCatcoinAddress => 'Catcoin 地址';

  @override
  String get walletPasteHint => '在此粘贴地址';

  @override
  String get walletSetPrimary => '设为主要地址';

  @override
  String get walletInvalidAddressComplex =>
      '地址无效。必须是有效的 BEP20 (0x...)、Solana 或 Catcoin（以 9 开头）地址。';

  @override
  String get walletRecoverTitle => '恢复钱包';

  @override
  String get walletRecoverInstruction => '输入您的 24 位助记词以恢复钱包。';

  @override
  String get walletSecretPhrase => '助记词';

  @override
  String get walletSecretPhraseHint => '单词1 单词2 ... 单词24';

  @override
  String get walletInvalidPhrase => '助记词无效。必须正好是 24 个单词。';

  @override
  String get walletDeleteTitle => '删除钱包';

  @override
  String walletDeleteConfirmMessage(String address) {
    return '您确定要删除钱包 $address 吗？如果您没有私钥/助记词，此操作将无法撤销。';
  }

  @override
  String get walletDeletedSuccess => '钱包已成功删除';

  @override
  String get walletAddedSuccess => '钱包已成功添加';

  @override
  String get walletGenerateTitle => '生成新钱包';

  @override
  String get walletBackupTitle => '生成成功！请备份您的钱包';

  @override
  String get walletBackupWarning => '重要提示：请按顺序记下这 24 个单词并安全保存。没有它们，您将无法找回资金！';

  @override
  String get walletGenerateInstruction =>
      '这将为您创建一个新的 Catcoin 钱包。生成后请务必立即备份您的助记词！';

  @override
  String get walletGenerating => '正在生成密钥...';

  @override
  String get walletBackedUp => '我已备份';

  @override
  String get walletRecoverFromPhrase => '通过助记词恢复';

  @override
  String get walletSetDefault => '设为默认';

  @override
  String get walletSettingPrimary => '正在将钱包设置为主要钱包...';

  @override
  String get walletPrimary => '主要';

  @override
  String get walletSourceGenerated => '已生成';

  @override
  String get walletSourceRecovered => '已恢复';

  @override
  String get walletSourceManual => '手动输入地址';

  @override
  String walletDaysHeld(String days) {
    return '持有天数：$days';
  }

  @override
  String get walletCalculating => '正在计算...';

  @override
  String get rewardsTitle => '奖励';

  @override
  String get rewardsClaim => '领取';

  @override
  String get rewardsClaimed => '已领取';

  @override
  String get rewardsAvailable => '可用';

  @override
  String get rewardsNoRewards => '暂无奖励';

  @override
  String get rewardsSocialTasks => '社交任务';

  @override
  String get rewardsXTasks => 'X 任务';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => '所有任务';

  @override
  String get rewardsNoMissions => '暂无进行中的任务。';

  @override
  String rewardsError(String error) {
    return '错误: $error';
  }

  @override
  String get gamesTitle => '游戏';

  @override
  String get gamesPlay => '开始';

  @override
  String get gamesRunner => '猫咪跑酷';

  @override
  String get gamesRunnerDescription => '奔跑、跳跃、收集硬币！';

  @override
  String get gamesNoGames => '暂无游戏';

  @override
  String get referralTitle => '我的推荐';

  @override
  String get referralCode => '你的推荐码';

  @override
  String get referralCopyCode => '复制推荐码';

  @override
  String get referralShareLink => '分享链接';

  @override
  String get referralActiveReferrals => '有效推荐';

  @override
  String get referralNoReferrals => '暂无推荐';

  @override
  String get referralBoost => '加速';

  @override
  String get referralBoosted => '已加速';

  @override
  String get referralInviteFriends => '邀请好友';

  @override
  String get balanceDetailTitle => '余额详情';

  @override
  String get payoutHistoryTitle => '提现记录';

  @override
  String get payoutHistoryNone => '暂无提现记录';

  @override
  String get awardsTitle => '荣誉';

  @override
  String get socialMissionsTitle => '社交任务';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileAccountDetails => '账号详情';

  @override
  String get profileReferredBy => '推荐人';

  @override
  String get profileMyReferrals => '我的推荐';

  @override
  String get profileSocialProfiles => '社交账号验证';

  @override
  String get profileDiscord => 'Discord 用户名';

  @override
  String get profileTelegram => 'Telegram 用户 ID（数字）';

  @override
  String get profileTelegramHint => '如：123456789';

  @override
  String get profileX => 'X (Twitter) 账号';

  @override
  String get profileFacebook => 'Facebook 链接/ID';

  @override
  String get profileWhatsapp => 'WhatsApp 号码';

  @override
  String get profileSaveSocialIds => '保存社交 ID';

  @override
  String get profileUpdatedSuccess => '个人资料更新成功！';

  @override
  String get profileSettings => '设置';

  @override
  String get profileAppearance => '外观';

  @override
  String get profileThemeSystem => '跟随系统';

  @override
  String get profileThemeLight => '浅色';

  @override
  String get profileThemeDark => '深色';

  @override
  String get profilePayoutHistory => '提现记录';

  @override
  String get profileChangePassword => '修改密码';

  @override
  String get profileLanguage => '语言';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get profileDiscordHint => '输入你的 Discord 用户名';

  @override
  String get profileVerified => '已验证。点击 🔒 编辑（将撤销奖励）。';

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
  String get changePasswordTitle => '修改密码';

  @override
  String get changePasswordCurrent => '当前密码';

  @override
  String get changePasswordNew => '新密码';

  @override
  String get changePasswordConfirm => '确认新密码';

  @override
  String get changePasswordMin6 => '最少 6 个字符';

  @override
  String get changePasswordMismatch => '两次密码不一致';

  @override
  String get changePasswordSuccess => '密码修改成功！';

  @override
  String get deleteAccountTitle => '删除账号？';

  @override
  String get deleteAccountMessage => '此操作不可撤销。\n\n你的所有挖矿进度、余额和推荐关系将永久消失。';

  @override
  String get deleteAccountConfirm => '永久删除';

  @override
  String deleteAccountFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String resetSocialTitle(String platform) {
    return '编辑 $platform ID？';
  }

  @override
  String get resetSocialMessage =>
      '更改已验证的社交 ID 将撤销 100,000 卡托希任务奖励，直到新 ID 通过验证。\n\n确认继续？';

  @override
  String get resetSocialUnlocked => '已解锁，可以编辑。';

  @override
  String resetSocialFailed(String error) {
    return '解锁失败：$error';
  }

  @override
  String get languageSelectTitle => '选择语言';

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
  String get telegramHelpTitle => '如何查找你的 Telegram ID';

  @override
  String get telegramHelpStep1 => '打开 Telegram，搜索 @userinfobot';

  @override
  String get telegramHelpStep2 => '与机器人开始对话';

  @override
  String get telegramHelpStep3 => '机器人将回复你的数字用户 ID';

  @override
  String get missionComplete => '完成';

  @override
  String get missionCompleted => '已完成';

  @override
  String get missionClaim => '领取';

  @override
  String get missionClaimed => '已领取';

  @override
  String get missionGo => '前往';

  @override
  String failedPickImage(String error) {
    return '选择图片失败：$error';
  }

  @override
  String get awardsNoAwards => '暂无任何荣誉奖励。';

  @override
  String get awardsKeepMining => '继续挖矿并提升排名！';

  @override
  String get balanceSummary => '概览';

  @override
  String get balanceEarnings => '收益';

  @override
  String get balancePayouts => '提现';

  @override
  String get balanceLoadError => '余额详情加载失败。';

  @override
  String get balanceWithdrawSoon => '敬请期待 — 提现功能即将开启！';

  @override
  String get balanceTotal => '总余额';

  @override
  String get balanceNotWithdrawable => '不可提现';

  @override
  String get balanceBreakdown => '收益构成';

  @override
  String get balanceMining => '挖矿收益';

  @override
  String get balanceReferral => '推荐收益';

  @override
  String get balanceMission => '任务收益';

  @override
  String get balanceGame => '游戏收益';

  @override
  String get balanceWithdraw => '提现';

  @override
  String get balanceWithdrawSubmitted => '提现申请已提交！';

  @override
  String get balanceNoHistory => '暂无收益记录。';

  @override
  String get balanceNoPayouts => '暂无提现记录。';

  @override
  String get boostersActiveModifiers => '当前生效修正项';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return '当前推荐奖励: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => '可用修正器';

  @override
  String get boostersApplyExtensions => '为当前挖矿会话应用时间延长和激活推荐奖励。';

  @override
  String get boostersStartMiningPrompt => '请在仪表盘开始挖矿以解锁修正器！';

  @override
  String get boostersNoBoosters => '目前暂无倍增器。';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return '$hours小时时间加速';
  }

  @override
  String boostersCooldown(Object duration) {
    return '冷却时间: $duration';
  }

  @override
  String get boostersSessionMaxed => '会话已达24小时上限。';

  @override
  String boostersExtendBy(Object hours) {
    return '延长会话 $hours小时 (最大容量)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return '延长会话 $hours小时';
  }

  @override
  String get boostersApply => '应用';

  @override
  String boostersReferralBoosting(Object boost) {
    return '正在为你加速！(生效中) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => '推荐容量已满。';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return '活跃矿工！应用可获得 +$boost% 奖励。';
  }

  @override
  String get boostersActive => '生效中';

  @override
  String get boostersErrorMustMine => '请先开始挖矿！';

  @override
  String get boostersEnergyPotionConsumed => '能量药水使用成功！';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return '会话延长失败: $error';
  }

  @override
  String get boostersReferralActivated => '推荐加速已成功激活！';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => '奔跑、跳跃，赚取卡托希！';

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
  String get gamesComingSoon => '敬请期待...';

  @override
  String get referralsTitle => '推介';

  @override
  String get referralsInvitedBy => '邀请人';

  @override
  String get referralsNoOneYet => '暂无';

  @override
  String get referralsYourCode => '你的推荐码';

  @override
  String get referralsCopied => '已复制到剪贴板';

  @override
  String referralsShareMessage(Object code) {
    return '快来加入 Catcoin PoE！使用我的邀请码 $code 领取奖励。\n\n链接: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => '总计';

  @override
  String get referralsActiveCount => '活跃';

  @override
  String get referralsBoostPercentage => '加速百分比';

  @override
  String get referralsYourReferrals => '你的推荐';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => '活跃 (最近24小时)';

  @override
  String get referralsInactive => '不活跃';

  @override
  String get referralsEnterInviterCode => '输入邀请码';

  @override
  String get referralsInviterCodeInstruction => '如果你是由他人邀请的，请在此输入他们的推荐码以绑定账号。';

  @override
  String get referralsInviterCodeLabel => '推荐码';

  @override
  String get referralsInviterCodeUpdated => '邀请码更新成功！';

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
  String get referralMilestoneBonusTitle => '推荐里程碑奖励';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return '每次邀请一次性奖励 $amount 卡托希';
  }

  @override
  String get referralBonusRewardAmountNote => '奖励金额由服务器配置，管理员可更新。';

  @override
  String get referralBonusDetailAppTitle => '推荐奖励';

  @override
  String get referralBonusStatusHeading => '推荐奖励状态';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return '您（推荐人）的奖励：$amount 卡托希';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return '奖励已到账（$amount 卡托希）。';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '3 项条件中已完成 $met 项';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return '推荐奖励：$amount 卡托希';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return '加入 $joined · 推荐 $referred';
  }

  @override
  String get referralBonusConditionMinedDays => '挖矿天数';

  @override
  String get referralBonusConditionMiningReward => '挖矿奖励（基础）';

  @override
  String get referralBonusConditionGameReward => '游戏奖励';

  @override
  String get referralBonusStatePending => '条件未完成';

  @override
  String get referralBonusStateEligible => '符合领奖条件';

  @override
  String get referralBonusStateRewarded => '奖励已发放';

  @override
  String get referralBonusStateUnderReview => '管理员审核中';

  @override
  String get referralBonusStateRejected => '已拒绝';

  @override
  String get profileSetupSkip => '跳过';

  @override
  String get profileSetupGallery => '相册';

  @override
  String get profileSetupCamera => '相机';

  @override
  String profileSetupFailedImage(Object error) {
    return '图片选择失败: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => '显示名称 (可选)';

  @override
  String get profileSetupDisplayNameHint => '我们该如何称呼你？';

  @override
  String get profileSetupSaveContinue => '保存并继续';

  @override
  String profileSetupFailedSave(Object error) {
    return '资料保存失败: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return '目前没有可用的 $title。';
  }

  @override
  String get payoutHistoryScreenTitle => '支付历史';

  @override
  String get payoutNoHistory => '未找到支付历史。';

  @override
  String get payoutViewTx => '查看交易';

  @override
  String payoutAddressTo(Object address) {
    return '至: $address';
  }

  @override
  String get commonAdd => '添加';

  @override
  String get commonEdit => '编辑';

  @override
  String get missionVerifyTitle => '需要验证';

  @override
  String get missionVerifyDiscord => '请输入您的 Discord 用户名，以便我们验证您是否已加入：';

  @override
  String get missionVerifyTelegram => '请输入您的数字 Telegram ID：';

  @override
  String get missionVerifyGeneric => '请输入您的用户名/句柄以进行验证：';

  @override
  String get missionHintDiscord => '输入 Discord 用户名';

  @override
  String get missionHintTelegram => '输入数字 ID';

  @override
  String get missionHintGeneric => '输入用户名/句柄';

  @override
  String get missionHelpGetId => '如何获取 ID？';

  @override
  String get missionSaveContinue => '保存并继续';

  @override
  String get missionVerificationStarted => '验证已开始！请完成任务。';

  @override
  String missionClaimedSuccess(Object amount) {
    return '已领取 $amount Catoshi！';
  }

  @override
  String missionFailed(Object error) {
    return '失败：$error';
  }

  @override
  String get missionExpired => '已过期';

  @override
  String missionExpiresInDays(Object days) {
    return '$days 天后过期';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return '$hours 小时后过期';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => '正在验证...';

  @override
  String get missionBtnClaim => '领取';

  @override
  String get telegramHelpInstructions =>
      '1. 打开 Telegram。\n2. 搜索 @userinfobot（或扫描下方二维码）。\n3. 点击开始（或发送 /start）。\n4. 它会回复您的详细信息。寻找 \"Id\"。\n5. 复制该数字并将其粘贴到此处。';

  @override
  String get telegramHelpBtnOpen => '打开 @userinfobot';

  @override
  String get telegramHelpQrLabel => '或扫描二维码：';

  @override
  String get telegramHelpQrError =>
      '未找到二维码。\n(添加 assets/images/telegram_qr.png)';

  @override
  String get resetPasswordSuccess => '密码重置成功。请登录。';

  @override
  String get resetPasswordFailed => '密码重置失败';

  @override
  String resetPasswordInstruction(Object email) {
    return '输入发送至 $email 的 6 位代码及您的新密码。';
  }

  @override
  String get emailVerificationCodeSent => '验证码已发送至您的邮箱！';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => '正在下载游戏资源...';

  @override
  String get gameLauncherReady => '引擎就绪';

  @override
  String get gameLauncherRequired => '由于需要游戏资源';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return '下载资源 (~$size)';
  }

  @override
  String get gameLauncherStartBtn => '开始游戏';

  @override
  String get gameLauncherResetBtn => '重置资源';

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
  String get gameGameOverTitle => '游戏结束';

  @override
  String get gameStatScore => '得分';

  @override
  String get gameStatDistance => '距离';

  @override
  String get gameStatCoins => '硬币';

  @override
  String get gameStatCatoshiEarned => '赚取的 Catoshi';

  @override
  String get gamePlayAgain => '再玩一次';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => '退出';

  @override
  String get gamePausedTitle => '已暂停';

  @override
  String get gameResume => '继续';

  @override
  String get gameQuit => '退出';

  @override
  String get updateTitle => '有可用更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateNow => '现在更新';

  @override
  String get updateUrlError => '无法启动更新 URL';

  @override
  String balancePayoutTo(Object address) {
    return '至：$address';
  }

  @override
  String get boostersSubtitle => '超强制您的采矿速度并延长会话！';

  @override
  String get commonVersion => '版本';

  @override
  String get commonUser => '用户';

  @override
  String get profileVerifiedTooltip => '已验证。点击解锁并编辑。';

  @override
  String walletAddressLabel(Object address) {
    return '地址：$address';
  }

  @override
  String walletGenerationError(Object error) {
    return '生成错误：$error';
  }

  @override
  String get walletDeleteWallet => '删除钱包';

  @override
  String get commonGenerate => '生成';

  @override
  String get badgeWeeklyTop => '每周之星';

  @override
  String get badgeMonthlyTop => '每月之星';

  @override
  String get badgeAllTimeTop => '历史之星';

  @override
  String get badgeVerified => '已验证用户';

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
    return '新版本 ($version) 已发布。';
  }

  @override
  String get updateMandatory => '此更新是强制性的，才能继续使用该应用程序。';

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
  String get languageGroupInternational => '国际';

  @override
  String get languageGroupIndian => '印度';
}
