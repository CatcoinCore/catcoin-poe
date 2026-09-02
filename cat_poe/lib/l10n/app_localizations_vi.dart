// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'Trò chơi';

  @override
  String get navLeaders => 'Bảng xếp hạng';

  @override
  String get navWallet => 'Ví';

  @override
  String get navRewards => 'Phần thưởng';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonOk => 'OK';

  @override
  String get commonError => 'Lỗi';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonNone => 'Không có';

  @override
  String get commonGallery => 'Thư viện ảnh';

  @override
  String get commonCamera => 'Máy ảnh';

  @override
  String get commonRemovePhoto => 'Xóa ảnh';

  @override
  String get commonRequired => 'Bắt buộc';

  @override
  String get commonUnlockEdit => 'Mở khóa & Chỉnh sửa';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginEmailOrUsername => 'Email hoặc Tên đăng nhập';

  @override
  String get loginEmailHint => 'email@example.com hoặc 900123456';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get loginCreateAccount => 'Tạo tài khoản';

  @override
  String get loginForgotPassword => 'Quên mật khẩu?';

  @override
  String get loginUseEmailForVerification =>
      'Vui lòng đăng nhập bằng Email để hoàn tất xác minh.';

  @override
  String get signupTitle => 'Đăng ký';

  @override
  String get signupEmail => 'Email';

  @override
  String get signupEmailHint => 'email@example.com';

  @override
  String get signupPassword => 'Mật khẩu';

  @override
  String get signupConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get signupReferralCode => 'Mã giới thiệu (Tùy chọn)';

  @override
  String get signupReferralCodeHint => 'Nhập mã giới thiệu nếu bạn có';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'Đăng ký';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get forgotPasswordEmail => 'Email';

  @override
  String get forgotPasswordSendCode => 'Gửi mã đặt lại';

  @override
  String get forgotPasswordBackToLogin => 'Quay lại đăng nhập';

  @override
  String get emailVerificationTitle => 'Xác minh Email';

  @override
  String get emailVerificationInstruction => 'Nhập mã xác minh đã gửi tới';

  @override
  String get emailVerificationCode => 'Mã xác minh';

  @override
  String get emailVerificationVerify => 'Xác minh';

  @override
  String get emailVerificationResend => 'Gửi lại mã';

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordNewPassword => 'Mật khẩu mới';

  @override
  String get resetPasswordConfirm => 'Xác nhận mật khẩu mới';

  @override
  String get resetPasswordButton => 'Đặt lại mật khẩu';

  @override
  String get profileSetupTitle => 'Thiết lập hồ sơ';

  @override
  String get splashLoading => 'Đang tải...';

  @override
  String get dashboardTotalBalance => 'Tổng số dư';

  @override
  String get dashboardCatoshi => 'catoshi';

  @override
  String get dashboardCatoshiLabel => 'Catoshi';

  @override
  String get dashboardNotMining => 'Chưa đào';

  @override
  String get dashboardStartMining => 'BẮT ĐẦU ĐÀO';

  @override
  String dashboardRewardRate(Object rate) {
    return 'Tỷ lệ phần thưởng: $rate Catoshi/giây';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'Thời lượng hiện tại: ${hours}h / tối đa ${maxHours}h';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'Tăng tốc';

  @override
  String get boostersCardTitle => 'Tăng cường';

  @override
  String get boostersCardDescription =>
      'Tăng tốc độ khai thác và kéo dài phiên!';

  @override
  String get boostersOpenScreen => 'Xem tăng cường';

  @override
  String get leaderboardTitle => 'Bảng xếp hạng';

  @override
  String get leaderboardTopMiners => 'Top thợ đào';

  @override
  String get leaderboardRank => 'Hạng';

  @override
  String get leaderboardUser => 'Người dùng';

  @override
  String get leaderboardBalance => 'Số dư';

  @override
  String get leaderboardYou => 'Bạn';

  @override
  String get leaderboardGlobal => 'Toàn cầu';

  @override
  String get leaderboardRegional => 'Khu vực';

  @override
  String get leaderboardGames => 'Trò chơi';

  @override
  String get leaderboardAwards => 'Giải thưởng';

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
  String get leaderboardChallengers => 'Người thách đấu';

  @override
  String get leaderboardNoGlobal =>
      'Không tìm thấy người khai thác toàn cầu nào.';

  @override
  String get leaderboardNoRegional =>
      'Không tìm thấy người khai thác khu vực nào.';

  @override
  String get leaderboardComingSoon =>
      'Sắp ra mắt — hãy cạnh tranh qua các trò chơi nhỏ!';

  @override
  String get leaderboardNoAwards => 'Chưa có giải thưởng nào';

  @override
  String get leaderboardKeepMining =>
      'Hãy tiếp tục khai thác để đạt được bục vinh quang!';

  @override
  String get walletTitle => 'Ví';

  @override
  String get walletAddress => 'Địa chỉ ví';

  @override
  String get walletBalance => 'Số dư';

  @override
  String get walletCopy => 'Sao chép';

  @override
  String get walletCopied => 'Đã sao chép!';

  @override
  String get walletSend => 'Gửi';

  @override
  String get walletReceive => 'Nhận';

  @override
  String get walletTransactions => 'Giao dịch';

  @override
  String get walletNoTransactions => 'Chưa có giao dịch';

  @override
  String get walletConnectWallet => 'Kết nối ví';

  @override
  String get walletDisconnect => 'Ngắt kết nối';

  @override
  String get walletSolanaAddress => 'Địa chỉ Solana';

  @override
  String get walletEnterAddress => 'Nhập địa chỉ Solana';

  @override
  String get walletSaveAddress => 'Lưu địa chỉ';

  @override
  String get walletAddressSaved => 'Đã lưu địa chỉ!';

  @override
  String get walletInvalidAddress => 'Địa chỉ Solana không hợp lệ';

  @override
  String get walletMyWallets => 'Ví của tôi';

  @override
  String get walletAddExisting => 'Thêm địa chỉ hiện có';

  @override
  String get walletCatcoinAddress => 'Địa chỉ Catcoin';

  @override
  String get walletPasteHint => 'Dán địa chỉ vào đây';

  @override
  String get walletSetPrimary => 'Đặt làm chính';

  @override
  String get walletInvalidAddressComplex =>
      'Địa chỉ không hợp lệ. Phải là địa chỉ BEP20 (0x...), Solana hoặc Catcoin (bắt đầu bằng số 9) hợp lệ.';

  @override
  String get walletRecoverTitle => 'Khôi phục ví';

  @override
  String get walletRecoverInstruction =>
      'Nhập cụm từ bí mật 24 từ của bạn để khôi phục ví.';

  @override
  String get walletSecretPhrase => 'Cụm từ bí mật';

  @override
  String get walletSecretPhraseHint => 'từ1 từ2 ... từ24';

  @override
  String get walletInvalidPhrase => 'Cụm từ không hợp lệ. Phải có đúng 24 từ.';

  @override
  String get walletDeleteTitle => 'Xóa ví';

  @override
  String walletDeleteConfirmMessage(String address) {
    return 'Bạn có chắc chắn muốn xóa ví $address? Hành động này không thể hoàn tác nếu bạn không có khóa riêng/cụm từ bí mật.';
  }

  @override
  String get walletDeletedSuccess => 'Đã xóa ví thành công';

  @override
  String get walletAddedSuccess => 'Đã thêm ví thành công';

  @override
  String get walletGenerateTitle => 'Tạo ví mới';

  @override
  String get walletBackupTitle => 'Thành công! Hãy sao lưu ví của bạn';

  @override
  String get walletBackupWarning =>
      'QUAN TRỌNG: Hãy chép lại 24 từ này theo đúng thứ tự và giữ chúng an toàn. Bạn không thể khôi phục tiền nếu không có chúng!';

  @override
  String get walletGenerateInstruction =>
      'Hành động này sẽ tạo một ví Catcoin mới cho bạn. Hãy chắc chắn sao lưu cụm từ bí mật ngay sau khi tạo!';

  @override
  String get walletGenerating => 'Đang tạo mã khóa...';

  @override
  String get walletBackedUp => 'Tôi đã sao lưu';

  @override
  String get walletRecoverFromPhrase => 'Khôi phục từ cụm từ';

  @override
  String get walletSetDefault => 'Đặt mặc định';

  @override
  String get walletSettingPrimary => 'Đang đặt ví làm mặc định...';

  @override
  String get walletPrimary => 'Chính';

  @override
  String get walletSourceGenerated => 'Đã tạo';

  @override
  String get walletSourceRecovered => 'Đã khôi phục';

  @override
  String get walletSourceManual => 'Địa chỉ thủ công';

  @override
  String walletDaysHeld(String days) {
    return 'Số ngày nắm giữ: $days';
  }

  @override
  String get walletCalculating => 'Đang tính toán...';

  @override
  String get rewardsTitle => 'Phần thưởng';

  @override
  String get rewardsClaim => 'Nhận';

  @override
  String get rewardsClaimed => 'Đã nhận';

  @override
  String get rewardsAvailable => 'Có sẵn';

  @override
  String get rewardsNoRewards => 'Không có phần thưởng';

  @override
  String get rewardsSocialTasks => 'Nhiệm vụ xã hội';

  @override
  String get rewardsXTasks => 'Nhiệm vụ X';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'Tất cả nhiệm vụ';

  @override
  String get rewardsNoMissions => 'Không có nhiệm vụ hoạt động nào khả dụng.';

  @override
  String rewardsError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get gamesTitle => 'Trò chơi';

  @override
  String get gamesPlay => 'Chơi';

  @override
  String get gamesRunner => 'Mèo chạy';

  @override
  String get gamesRunnerDescription => 'Chạy, nhảy và thu thập xu!';

  @override
  String get gamesNoGames => 'Không có trò chơi';

  @override
  String get referralTitle => 'Giới thiệu của tôi';

  @override
  String get referralCode => 'Mã giới thiệu của bạn';

  @override
  String get referralCopyCode => 'Sao chép mã';

  @override
  String get referralShareLink => 'Chia sẻ liên kết';

  @override
  String get referralActiveReferrals => 'Giới thiệu đang hoạt động';

  @override
  String get referralNoReferrals => 'Chưa có giới thiệu';

  @override
  String get referralBoost => 'Tăng tốc';

  @override
  String get referralBoosted => 'Đã tăng tốc';

  @override
  String get referralInviteFriends => 'Mời bạn bè';

  @override
  String get balanceDetailTitle => 'Chi tiết số dư';

  @override
  String get payoutHistoryTitle => 'Lịch sử thanh toán';

  @override
  String get payoutHistoryNone => 'Chưa có lịch sử thanh toán';

  @override
  String get awardsTitle => 'Phần thưởng';

  @override
  String get socialMissionsTitle => 'Nhiệm vụ xã hội';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileAccountDetails => 'Chi tiết tài khoản';

  @override
  String get profileReferredBy => 'Được giới thiệu bởi';

  @override
  String get profileMyReferrals => 'Giới thiệu của tôi';

  @override
  String get profileSocialProfiles => 'Hồ sơ mạng xã hội để xác minh';

  @override
  String get profileDiscord => 'Tên người dùng Discord';

  @override
  String get profileTelegram => 'ID Telegram (số)';

  @override
  String get profileTelegramHint => 'vd: 123456789';

  @override
  String get profileX => 'Tài khoản X (Twitter)';

  @override
  String get profileFacebook => 'Liên kết/ID Facebook';

  @override
  String get profileWhatsapp => 'Số WhatsApp';

  @override
  String get profileSaveSocialIds => 'Lưu ID mạng xã hội';

  @override
  String get profileUpdatedSuccess => 'Cập nhật hồ sơ thành công!';

  @override
  String get profileSettings => 'Cài đặt';

  @override
  String get profileAppearance => 'Giao diện';

  @override
  String get profileThemeSystem => 'Hệ thống';

  @override
  String get profileThemeLight => 'Sáng';

  @override
  String get profileThemeDark => 'Tối';

  @override
  String get profilePayoutHistory => 'Lịch sử thanh toán';

  @override
  String get profileChangePassword => 'Đổi mật khẩu';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileLogout => 'ĐĂNG XUẤT';

  @override
  String get profileDeleteAccount => 'Xóa tài khoản';

  @override
  String get profileDiscordHint => 'Nhập tên người dùng Discord của bạn';

  @override
  String get profileVerified =>
      'Đã xác minh. Nhấn 🔒 để chỉnh sửa (hủy phần thưởng).';

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
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordCurrent => 'Mật khẩu hiện tại';

  @override
  String get changePasswordNew => 'Mật khẩu mới';

  @override
  String get changePasswordConfirm => 'Xác nhận mật khẩu mới';

  @override
  String get changePasswordMin6 => 'Tối thiểu 6 ký tự';

  @override
  String get changePasswordMismatch => 'Mật khẩu không khớp';

  @override
  String get changePasswordSuccess => 'Đổi mật khẩu thành công!';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản?';

  @override
  String get deleteAccountMessage =>
      'Hành động này không thể hoàn tác.\n\nToàn bộ tiến trình đào, số dư và giới thiệu sẽ bị mất vĩnh viễn.';

  @override
  String get deleteAccountConfirm => 'XÓA VĨNH VIỄN';

  @override
  String deleteAccountFailed(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return 'Chỉnh sửa ID $platform?';
  }

  @override
  String get resetSocialMessage =>
      'Thay đổi ID mạng xã hội đã xác minh sẽ hủy phần thưởng 100.000 Catoshi cho đến khi ID mới được xác minh.\n\nBạn có chắc muốn tiếp tục?';

  @override
  String get resetSocialUnlocked => 'Đã mở khóa để chỉnh sửa.';

  @override
  String resetSocialFailed(String error) {
    return 'Mở khóa thất bại: $error';
  }

  @override
  String get languageSelectTitle => 'Chọn ngôn ngữ';

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
  String get telegramHelpTitle => 'Cách tìm ID Telegram của bạn';

  @override
  String get telegramHelpStep1 => 'Mở Telegram và tìm @userinfobot';

  @override
  String get telegramHelpStep2 => 'Bắt đầu trò chuyện với bot';

  @override
  String get telegramHelpStep3 => 'Bot sẽ trả lời với ID người dùng số của bạn';

  @override
  String get missionComplete => 'Hoàn thành';

  @override
  String get missionCompleted => 'Đã hoàn thành';

  @override
  String get missionClaim => 'Nhận';

  @override
  String get missionClaimed => 'Đã nhận';

  @override
  String get missionGo => 'Đi';

  @override
  String failedPickImage(String error) {
    return 'Không thể chọn ảnh: $error';
  }

  @override
  String get awardsNoAwards => 'Bạn chưa nhận được giải thưởng nào.';

  @override
  String get awardsKeepMining =>
      'Hãy tiếp tục khai thác và leo lên bảng xếp hạng!';

  @override
  String get balanceSummary => 'Tóm tắt';

  @override
  String get balanceEarnings => 'Thu nhập';

  @override
  String get balancePayouts => 'Thanh toán';

  @override
  String get balanceLoadError => 'Không thể tải chi tiết số dư.';

  @override
  String get balanceWithdrawSoon =>
      'Hãy chú ý — tính năng rút tiền sẽ sớm được kích hoạt!';

  @override
  String get balanceTotal => 'Tổng số dư';

  @override
  String get balanceNotWithdrawable => 'Không thể rút';

  @override
  String get balanceBreakdown => 'Phân tích thu nhập';

  @override
  String get balanceMining => 'Thu nhập khai thác';

  @override
  String get balanceReferral => 'Thu nhập giới thiệu';

  @override
  String get balanceMission => 'Thu nhập nhiệm vụ';

  @override
  String get balanceGame => 'Thu nhập trò chơi';

  @override
  String get balanceWithdraw => 'Rút tiền';

  @override
  String get balanceWithdrawSubmitted => 'Yêu cầu rút tiền đã được gửi!';

  @override
  String get balanceNoHistory => 'Không có lịch sử thu nhập.';

  @override
  String get balanceNoPayouts => 'Không có lịch sử thanh toán.';

  @override
  String get boostersActiveModifiers => 'Mod hoạt động';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'Tiền thưởng giới thiệu hiện tại: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'Có sẵn mod';

  @override
  String get boostersApplyExtensions =>
      'Áp dụng gia hạn thời gian và kích hoạt tiền thưởng giới thiệu cho phiên khai thác hiện tại của bạn.';

  @override
  String get boostersStartMiningPrompt =>
      'Bắt đầu khai thác trên bảng điều khiển để mở khóa mod!';

  @override
  String get boostersNoBoosters => 'Hiện không có mod tăng cường nào.';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return 'Tăng thời gian $hours giờ';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'Thời gian chờ: $duration';
  }

  @override
  String get boostersSessionMaxed => 'Phiên đã đạt tối đa 24 giờ.';

  @override
  String boostersExtendBy(Object hours) {
    return 'Gia hạn phiên của bạn thêm $hours giờ (Công suất tối đa)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return 'Gia hạn phiên của bạn thêm $hours giờ';
  }

  @override
  String get boostersApply => 'Áp dụng';

  @override
  String boostersReferralBoosting(Object boost) {
    return 'Đang tăng tốc độ của bạn! (Hoạt động) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'Dung lượng giới thiệu đã đạt tối đa.';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return 'Người khai thác đang hoạt động! Áp dụng để nhận thêm +$boost% tiền thưởng.';
  }

  @override
  String get boostersActive => 'Hoạt động';

  @override
  String get boostersErrorMustMine => 'Bạn phải bắt đầu khai thác trước!';

  @override
  String get boostersEnergyPotionConsumed =>
      'Thuốc tăng lực đã được sử dụng thành công!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'Không thể gia hạn phiên: $error';
  }

  @override
  String get boostersReferralActivated =>
      'Tăng cường giới thiệu đã được kích hoạt thành công!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => 'Chạy, nhảy và kiếm catoshi!';

  @override
  String get gamesTictactoeTitle => 'Tic Tac Toe';

  @override
  String get gamesTictactoeDesc => 'Get three in a row to win!';

  @override
  String get gamesSudokuTitle => 'Sudoku';

  @override
  String get gamesSudokuDesc => 'Điền vào lưới các số từ 1-9.';

  @override
  String gameSudokuScore(Object score) {
    return 'Điểm: $score';
  }

  @override
  String gameSudokuMistakes(Object mistakes) {
    return 'Lỗi: $mistakes/3';
  }

  @override
  String gameSudokuStreak(Object streak) {
    return 'Chuỗi $streak';
  }

  @override
  String get gameSudokuLevelEasy => 'Dễ';

  @override
  String get gameSudokuLevelMedium => 'Trung bình';

  @override
  String get gameSudokuLevelHard => 'Khó';

  @override
  String get gameSudokuLevelExpert => 'Chuyên gia';

  @override
  String get gameSudokuUndo => 'Hoàn tác';

  @override
  String get gameSudokuErase => 'Xóa';

  @override
  String get gameSudokuPencil => 'Ghi chú';

  @override
  String get gameSudokuFastPencil => 'Ghi chú nhanh';

  @override
  String get gameSudokuHint => 'Gợi ý';

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
  String get gamesComingSoon => 'Sắp ra mắt...';

  @override
  String get referralsTitle => 'Giới thiệu';

  @override
  String get referralsInvitedBy => 'Người mời';

  @override
  String get referralsNoOneYet => 'Chưa có ai';

  @override
  String get referralsYourCode => 'Mã giới thiệu của bạn';

  @override
  String get referralsCopied => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String referralsShareMessage(Object code) {
    return 'Tham gia với tôi trên Catcoin PoE! Sử dụng mã $code của tôi để nhận tiền thưởng.\n\nLink: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'Tổng cộng';

  @override
  String get referralsActiveCount => 'Hoạt động';

  @override
  String get referralsBoostPercentage => 'Phần trăm tăng';

  @override
  String get referralsYourReferrals => 'Giới thiệu của bạn';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'Hoạt động (24h qua)';

  @override
  String get referralsInactive => 'Không hoạt động';

  @override
  String get referralsEnterInviterCode => 'Nhập mã người mời';

  @override
  String get referralsInviterCodeInstruction =>
      'Nếu bạn được ai đó mời, hãy nhập mã giới thiệu của họ vào đây để liên kết tài khoản của bạn.';

  @override
  String get referralsInviterCodeLabel => 'Mã giới thiệu';

  @override
  String get referralsInviterCodeUpdated => 'Cập nhật mã người mời thành công!';

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
  String get referralMilestoneBonusTitle => 'Thưởng cột mốc giới thiệu';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'Thưởng một lần $amount catoshi cho mỗi lời mời';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'Số tiền thưởng được cấu hình trên máy chủ và quản trị viên có thể cập nhật.';

  @override
  String get referralBonusDetailAppTitle => 'Thưởng giới thiệu';

  @override
  String get referralBonusStatusHeading => 'Trạng thái thưởng giới thiệu';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'Thưởng cho bạn (người giới thiệu): $amount catoshi';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'Đã ghi có thưởng ($amount catoshi).';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '$met/3 điều kiện đã đạt';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'Thưởng giới thiệu: $amount catoshi';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'Tham gia $joined · Được giới thiệu $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'Ngày đào';

  @override
  String get referralBonusConditionMiningReward => 'Thưởng đào (BASE)';

  @override
  String get referralBonusConditionGameReward => 'Thưởng game';

  @override
  String get referralBonusStatePending => 'Đang chờ điều kiện';

  @override
  String get referralBonusStateEligible => 'Đủ điều kiện nhận thưởng';

  @override
  String get referralBonusStateRewarded => 'Đã ghi có thưởng';

  @override
  String get referralBonusStateUnderReview => 'Đang xem xét bởi quản trị';

  @override
  String get referralBonusStateRejected => 'Bị từ chối';

  @override
  String get profileSetupSkip => 'Bỏ qua';

  @override
  String get profileSetupGallery => 'Thư viện';

  @override
  String get profileSetupCamera => 'Máy ảnh';

  @override
  String profileSetupFailedImage(Object error) {
    return 'Không thể chọn hình ảnh: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'Tên hiển thị (Tùy chọn)';

  @override
  String get profileSetupDisplayNameHint => 'Chúng tôi nên gọi bạn là gì?';

  @override
  String get profileSetupSaveContinue => 'Lưu & Tiếp tục';

  @override
  String profileSetupFailedSave(Object error) {
    return 'Không thể lưu hồ sơ: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return 'Hiện không có $title nào.';
  }

  @override
  String get payoutHistoryScreenTitle => 'Lịch sử thanh toán';

  @override
  String get payoutNoHistory => 'Không tìm thấy lịch sử thanh toán.';

  @override
  String get payoutViewTx => 'Xem TX';

  @override
  String payoutAddressTo(Object address) {
    return 'Đến: $address';
  }

  @override
  String get commonAdd => 'Thêm';

  @override
  String get commonEdit => 'Chỉnh sửa';

  @override
  String get missionVerifyTitle => 'Yêu cầu xác minh';

  @override
  String get missionVerifyDiscord =>
      'Nhập Tên người dùng Discord của bạn để chúng tôi có thể xác minh bạn đã tham gia:';

  @override
  String get missionVerifyTelegram => 'Nhập ID Telegram dạng số của bạn:';

  @override
  String get missionVerifyGeneric =>
      'Nhập tên người dùng/biệt danh của bạn để xác minh:';

  @override
  String get missionHintDiscord => 'Nhập Tên người dùng Discord';

  @override
  String get missionHintTelegram => 'Nhập ID dạng số';

  @override
  String get missionHintGeneric => 'Nhập Tên người dùng/Biệt danh';

  @override
  String get missionHelpGetId => 'Làm thế nào để lấy ID?';

  @override
  String get missionSaveContinue => 'Lưu & Tiếp tục';

  @override
  String get missionVerificationStarted =>
      'Đã bắt đầu xác minh! Vui lòng hoàn thành nhiệm vụ.';

  @override
  String missionClaimedSuccess(Object amount) {
    return 'Đã nhận $amount Catoshi!';
  }

  @override
  String missionFailed(Object error) {
    return 'Thất bại: $error';
  }

  @override
  String get missionExpired => 'Đã hết hạn';

  @override
  String missionExpiresInDays(Object days) {
    return 'Hết hạn sau $days ngày';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return 'Hết hạn sau $hours giờ';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'Đang xác minh...';

  @override
  String get missionBtnClaim => 'Nhận';

  @override
  String get telegramHelpInstructions =>
      '1. Mở Telegram.\n2. Tìm kiếm @userinfobot (hoặc quét mã QR bên dưới).\n3. Nhấp vào Bắt đầu (hoặc gửi /start).\n4. Nó sẽ trả lời bằng thông tin chi tiết của bạn. Hãy tìm \"Id\".\n5. Sao chép số đó và dán vào đây.';

  @override
  String get telegramHelpBtnOpen => 'Mở @userinfobot';

  @override
  String get telegramHelpQrLabel => 'Hoặc quét mã QR:';

  @override
  String get telegramHelpQrError =>
      'Không tìm thấy Mã QR.\n(Thêm assets/images/telegram_qr.png)';

  @override
  String get resetPasswordSuccess =>
      'Đặt lại mật khẩu thành công. Vui lòng đăng nhập.';

  @override
  String get resetPasswordFailed => 'Đặt lại mật khẩu thất bại';

  @override
  String resetPasswordInstruction(Object email) {
    return 'Nhập mã 6 chữ số được gửi tới $email và mật khẩu mới của bạn.';
  }

  @override
  String get emailVerificationCodeSent =>
      'Mã xác minh đã được gửi đến email của bạn!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => 'Đang tải xuống tài nguyên trò chơi...';

  @override
  String get gameLauncherReady => 'Công cụ đã sẵn sàng';

  @override
  String get gameLauncherRequired => 'Yêu cầu tài nguyên trò chơi';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'TẢI XUỐNG TÀI NGUYÊN (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'BẮT ĐẦU TRÒ CHƠI';

  @override
  String get gameLauncherResetBtn => 'Đặt lại tài nguyên';

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
  String get gameGameOverTitle => 'TRÒ CHƠI KẾT THÚC';

  @override
  String get gameStatScore => 'Điểm số';

  @override
  String get gameStatDistance => 'Khoảng cách';

  @override
  String get gameStatCoins => 'Tiền xu';

  @override
  String get gameStatCatoshiEarned => 'Catoshi nhận được';

  @override
  String get gamePlayAgain => 'CHƠI LẠI';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'THOÁT';

  @override
  String get gamePausedTitle => 'ĐÃ TẠM DỪNG';

  @override
  String get gameResume => 'TIẾP TỤC';

  @override
  String get gameQuit => 'THOÁT';

  @override
  String get updateTitle => 'Có bản cập nhật mới';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get updateUrlError => 'Không thể mở URL cập nhật';

  @override
  String balancePayoutTo(Object address) {
    return 'Đến: $address';
  }

  @override
  String get boostersSubtitle =>
      'Tăng tốc độ khai thác và kéo dài phiên của bạn!';

  @override
  String get commonVersion => 'Phiên bản';

  @override
  String get commonUser => 'Người dùng';

  @override
  String get profileVerifiedTooltip =>
      'Đã xác minh. Nhấn để mở khóa và chỉnh sửa.';

  @override
  String walletAddressLabel(Object address) {
    return 'Địa chỉ: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'Lỗi tạo: $error';
  }

  @override
  String get walletDeleteWallet => 'Xóa ví';

  @override
  String get commonGenerate => 'Tạo';

  @override
  String get badgeWeeklyTop => 'Hạng nhất tuần';

  @override
  String get badgeMonthlyTop => 'Hạng nhất tháng';

  @override
  String get badgeAllTimeTop => 'Hạng nhất mọi thời đại';

  @override
  String get badgeVerified => 'Người dùng đã xác minh';

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
    return 'Một phiên bản mới ($version) đã sẵn sàng.';
  }

  @override
  String get updateMandatory =>
      'Bản cập nhật này là bắt buộc để tiếp tục sử dụng ứng dụng.';

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
  String get languageGroupInternational => 'Quốc tế';

  @override
  String get languageGroupIndian => 'Ấn Độ';
}
