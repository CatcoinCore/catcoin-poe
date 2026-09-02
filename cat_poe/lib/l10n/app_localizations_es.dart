// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Catcoin';

  @override
  String get navHome => 'Inicio';

  @override
  String get navUpdates => 'Updates';

  @override
  String get navGames => 'Juegos';

  @override
  String get navLeaders => 'Líderes';

  @override
  String get navWallet => 'Billetera';

  @override
  String get navRewards => 'Recompensas';

  @override
  String get navProfile => 'Perfil';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonError => 'Error';

  @override
  String get commonAppName => 'Catcoin';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonNone => 'Ninguno';

  @override
  String get commonGallery => 'Galería';

  @override
  String get commonCamera => 'Cámara';

  @override
  String get commonRemovePhoto => 'Eliminar foto';

  @override
  String get commonRequired => 'Requerido';

  @override
  String get commonUnlockEdit => 'Desbloquear y editar';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginEmailOrUsername => 'Correo o nombre de usuario';

  @override
  String get loginEmailHint => 'tu.correo@example.com o 900123456';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginUseEmailForVerification =>
      'Por favor inicia sesión con tu correo para completar la verificación.';

  @override
  String get signupTitle => 'Registrarse';

  @override
  String get signupEmail => 'Correo';

  @override
  String get signupEmailHint => 'tu.correo@example.com';

  @override
  String get signupPassword => 'Contraseña';

  @override
  String get signupConfirmPassword => 'Confirmar contraseña';

  @override
  String get signupReferralCode => 'Código de referido (Opcional)';

  @override
  String get signupReferralCodeHint =>
      'Ingresa tu código de referido si tienes uno';

  @override
  String get signupReferralFromInviteTitle => 'Invite link applied';

  @override
  String signupReferralFromInviteBody(String code) {
    return 'Referral code $code will be used when you create your account. You do not need to type it.';
  }

  @override
  String get signupReferralChangeCode => 'Use a different code';

  @override
  String get signupButton => 'Registrarse';

  @override
  String get forgotPasswordTitle => 'Olvidé mi contraseña';

  @override
  String get forgotPasswordEmail => 'Correo';

  @override
  String get forgotPasswordSendCode => 'Enviar código de restablecimiento';

  @override
  String get forgotPasswordBackToLogin => 'Volver al inicio de sesión';

  @override
  String get emailVerificationTitle => 'Verificación de correo';

  @override
  String get emailVerificationInstruction => 'Ingresa el código enviado a';

  @override
  String get emailVerificationCode => 'Código de verificación';

  @override
  String get emailVerificationVerify => 'Verificar';

  @override
  String get emailVerificationResend => 'Reenviar código';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get resetPasswordNewPassword => 'Nueva contraseña';

  @override
  String get resetPasswordConfirm => 'Confirmar nueva contraseña';

  @override
  String get resetPasswordButton => 'Restablecer contraseña';

  @override
  String get profileSetupTitle => 'Configurar Perfil';

  @override
  String get splashLoading => 'Cargando...';

  @override
  String get dashboardTotalBalance => 'Balance total';

  @override
  String get dashboardCatoshi => 'catoshi';

  @override
  String get dashboardCatoshiLabel => 'Catoshi';

  @override
  String get dashboardNotMining => 'Sin minería';

  @override
  String get dashboardStartMining => 'INICIAR MINERÍA';

  @override
  String dashboardRewardRate(Object rate) {
    return 'Tasa de recompensa: $rate Catoshi/seg';
  }

  @override
  String dashboardCurrentDuration(Object hours, Object maxHours) {
    return 'Duración actual: ${hours}h / ${maxHours}h máx';
  }

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get boostersTitle => 'Potenciadores';

  @override
  String get boostersCardTitle => 'Potenciadores';

  @override
  String get boostersCardDescription =>
      '¡Aumenta tu velocidad de minado y extiende tus sesiones!';

  @override
  String get boostersOpenScreen => 'Ver potenciadores';

  @override
  String get leaderboardTitle => 'Tabla de líderes';

  @override
  String get leaderboardTopMiners => 'Mejores mineros';

  @override
  String get leaderboardRank => 'Posición';

  @override
  String get leaderboardUser => 'Usuario';

  @override
  String get leaderboardBalance => 'Balance';

  @override
  String get leaderboardYou => 'Tú';

  @override
  String get leaderboardGlobal => 'Global';

  @override
  String get leaderboardRegional => 'Regional';

  @override
  String get leaderboardGames => 'Juegos';

  @override
  String get leaderboardAwards => 'Premios';

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
  String get leaderboardChallengers => 'Desafiantes';

  @override
  String get leaderboardNoGlobal => 'No se encontraron mineros globales.';

  @override
  String get leaderboardNoRegional => 'No se encontraron mineros regionales.';

  @override
  String get leaderboardComingSoon => 'Próximamente — ¡compite en mini-juegos!';

  @override
  String get leaderboardNoAwards => 'Aún no hay premios';

  @override
  String get leaderboardKeepMining => '¡Sigue minando para llegar al podio!';

  @override
  String get walletTitle => 'Billetera';

  @override
  String get walletAddress => 'Dirección de billetera';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletCopy => 'Copiar';

  @override
  String get walletCopied => '¡Copiado!';

  @override
  String get walletSend => 'Enviar';

  @override
  String get walletReceive => 'Recibir';

  @override
  String get walletTransactions => 'Transacciones';

  @override
  String get walletNoTransactions => 'Sin transacciones aún';

  @override
  String get walletConnectWallet => 'Conectar billetera';

  @override
  String get walletDisconnect => 'Desconectar';

  @override
  String get walletSolanaAddress => 'Dirección Solana';

  @override
  String get walletEnterAddress => 'Ingresa dirección Solana';

  @override
  String get walletSaveAddress => 'Guardar dirección';

  @override
  String get walletAddressSaved => '¡Dirección guardada!';

  @override
  String get walletInvalidAddress => 'Dirección Solana inválida';

  @override
  String get walletMyWallets => 'Mis billeteras';

  @override
  String get walletAddExisting => 'Agregar dirección existente';

  @override
  String get walletCatcoinAddress => 'Dirección Catcoin';

  @override
  String get walletPasteHint => 'Pega la dirección aquí';

  @override
  String get walletSetPrimary => 'Establecer como principal';

  @override
  String get walletInvalidAddressComplex =>
      'Dirección inválida. Debe ser una dirección BEP20 (0x...), Solana o Catcoin (comienza con 9) válida.';

  @override
  String get walletRecoverTitle => 'Recuperar billetera';

  @override
  String get walletRecoverInstruction =>
      'Ingresa tu frase secreta de 24 palabras para recuperar tu billetera.';

  @override
  String get walletSecretPhrase => 'Frase secreta';

  @override
  String get walletSecretPhraseHint => 'palabra1 palabra2 ... palabra24';

  @override
  String get walletInvalidPhrase =>
      'Frase inválida. Debe tener exactamente 24 palabras.';

  @override
  String get walletDeleteTitle => 'Eliminar billetera';

  @override
  String walletDeleteConfirmMessage(String address) {
    return '¿Estás seguro de que deseas eliminar la billetera $address? Esta acción no se puede deshacer si no tienes la clave privada/frase.';
  }

  @override
  String get walletDeletedSuccess => 'Billetera eliminada con éxito';

  @override
  String get walletAddedSuccess => 'Billetera agregada con éxito';

  @override
  String get walletGenerateTitle => 'Generar nueva billetera';

  @override
  String get walletBackupTitle => '¡Éxito! Respalda tu billetera';

  @override
  String get walletBackupWarning =>
      'IMPORTANTE: Anota estas 24 palabras en orden y guárdalas en un lugar seguro. ¡No puedes recuperar tus fondos sin ellas!';

  @override
  String get walletGenerateInstruction =>
      'Esto creará una nueva billetera Catcoin para ti. ¡Asegúrate de respaldar tu frase secreta inmediatamente después de la creación!';

  @override
  String get walletGenerating => 'Generando claves...';

  @override
  String get walletBackedUp => 'He realizado el respaldo';

  @override
  String get walletRecoverFromPhrase => 'Recuperar desde frase';

  @override
  String get walletSetDefault => 'Establecer por defecto';

  @override
  String get walletSettingPrimary => 'Configurando billetera como principal...';

  @override
  String get walletPrimary => 'Principal';

  @override
  String get walletSourceGenerated => 'Generada';

  @override
  String get walletSourceRecovered => 'Recuperada';

  @override
  String get walletSourceManual => 'Dirección manual';

  @override
  String walletDaysHeld(String days) {
    return 'Días retenidos: $days';
  }

  @override
  String get walletCalculating => 'Calculando...';

  @override
  String get rewardsTitle => 'Recompensas';

  @override
  String get rewardsClaim => 'Reclamar';

  @override
  String get rewardsClaimed => 'Reclamado';

  @override
  String get rewardsAvailable => 'Disponible';

  @override
  String get rewardsNoRewards => 'Sin recompensas disponibles';

  @override
  String get rewardsSocialTasks => 'Tareas sociales';

  @override
  String get rewardsXTasks => 'Tareas de X';

  @override
  String get rewardsTelegramTasks => 'Telegram';

  @override
  String get rewardsDiscordTasks => 'Discord';

  @override
  String get rewardsAllMissions => 'Todas las misiones';

  @override
  String get rewardsNoMissions => 'No hay misiones activas disponibles.';

  @override
  String rewardsError(String error) {
    return 'Error: $error';
  }

  @override
  String get gamesTitle => 'Juegos';

  @override
  String get gamesPlay => 'Jugar';

  @override
  String get gamesRunner => 'Gato corredor';

  @override
  String get gamesRunnerDescription => '¡Corre, salta y recoge monedas!';

  @override
  String get gamesNoGames => 'Sin juegos disponibles';

  @override
  String get referralTitle => 'Mis referidos';

  @override
  String get referralCode => 'Tu código de referido';

  @override
  String get referralCopyCode => 'Copiar código';

  @override
  String get referralShareLink => 'Compartir enlace';

  @override
  String get referralActiveReferrals => 'Referidos activos';

  @override
  String get referralNoReferrals => 'Sin referidos aún';

  @override
  String get referralBoost => 'Impulsar';

  @override
  String get referralBoosted => 'Impulsado';

  @override
  String get referralInviteFriends => 'Invitar amigos';

  @override
  String get balanceDetailTitle => 'Detalles del balance';

  @override
  String get payoutHistoryTitle => 'Historial de pagos';

  @override
  String get payoutHistoryNone => 'Sin historial de pagos';

  @override
  String get awardsTitle => 'Premios';

  @override
  String get socialMissionsTitle => 'Misiones sociales';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileAccountDetails => 'Detalles de la cuenta';

  @override
  String get profileReferredBy => 'Referido por';

  @override
  String get profileMyReferrals => 'Mis referidos';

  @override
  String get profileSocialProfiles => 'Redes sociales para verificación';

  @override
  String get profileDiscord => 'Nombre de usuario Discord';

  @override
  String get profileTelegram => 'ID de Telegram (numérico)';

  @override
  String get profileTelegramHint => 'ej. 123456789';

  @override
  String get profileX => 'Usuario de X (Twitter)';

  @override
  String get profileFacebook => 'Enlace/ID de Facebook';

  @override
  String get profileWhatsapp => 'Número de WhatsApp';

  @override
  String get profileSaveSocialIds => 'Guardar IDs sociales';

  @override
  String get profileUpdatedSuccess => '¡Perfil actualizado con éxito!';

  @override
  String get profileSettings => 'Configuración';

  @override
  String get profileAppearance => 'Apariencia';

  @override
  String get profileThemeSystem => 'Sistema';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get profilePayoutHistory => 'Historial de pagos';

  @override
  String get profileChangePassword => 'Cambiar contraseña';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileLogout => 'CERRAR SESIÓN';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileDiscordHint => 'Ingresa tu nombre de usuario Discord';

  @override
  String get profileVerified =>
      'Verificado. Toca 🔒 para editar (revoca recompensa).';

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
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get changePasswordCurrent => 'Contraseña actual';

  @override
  String get changePasswordNew => 'Nueva contraseña';

  @override
  String get changePasswordConfirm => 'Confirmar nueva contraseña';

  @override
  String get changePasswordMin6 => 'Mín. 6 caracteres';

  @override
  String get changePasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get changePasswordSuccess => '¡Contraseña cambiada con éxito!';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountMessage =>
      'Esta acción es permanente y no se puede deshacer.\n\nTodo tu progreso de minería, balance y referidos se perderán para siempre.';

  @override
  String get deleteAccountConfirm => 'ELIMINAR PERMANENTEMENTE';

  @override
  String deleteAccountFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String resetSocialTitle(String platform) {
    return '¿Editar ID de $platform?';
  }

  @override
  String get resetSocialMessage =>
      'Cambiar un ID social verificado revocará la recompensa de 100,000 Catoshi hasta que el nuevo ID sea verificado.\n\n¿Estás seguro de continuar?';

  @override
  String get resetSocialUnlocked => 'ID desbloqueado para editar.';

  @override
  String resetSocialFailed(String error) {
    return 'Error al desbloquear: $error';
  }

  @override
  String get languageSelectTitle => 'Seleccionar idioma';

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
  String get telegramHelpTitle => 'Cómo encontrar tu ID de Telegram';

  @override
  String get telegramHelpStep1 => 'Abre Telegram y busca @userinfobot';

  @override
  String get telegramHelpStep2 => 'Inicia un chat con el bot';

  @override
  String get telegramHelpStep3 =>
      'El bot responderá con tu ID de usuario numérico';

  @override
  String get missionComplete => 'Completar';

  @override
  String get missionCompleted => 'Completado';

  @override
  String get missionClaim => 'Reclamar';

  @override
  String get missionClaimed => 'Reclamado';

  @override
  String get missionGo => 'Ir';

  @override
  String failedPickImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get awardsNoAwards => 'Aún no has ganado ningún premio.';

  @override
  String get awardsKeepMining =>
      '¡Sigue minando y subiendo en la clasificación!';

  @override
  String get balanceSummary => 'Resumen';

  @override
  String get balanceEarnings => 'Ganancias';

  @override
  String get balancePayouts => 'Pagos';

  @override
  String get balanceLoadError => 'Error al cargar detalles de balance.';

  @override
  String get balanceWithdrawSoon =>
      '¡Atento! — ¡los retiros se activarán pronto!';

  @override
  String get balanceTotal => 'Balance Total';

  @override
  String get balanceNotWithdrawable => 'No retirable';

  @override
  String get balanceBreakdown => 'Desglose de Ganancias';

  @override
  String get balanceMining => 'Ganancias de Minería';

  @override
  String get balanceReferral => 'Ganancias por Referidos';

  @override
  String get balanceMission => 'Ganancias por Misiones';

  @override
  String get balanceGame => 'Ganancias de Juegos';

  @override
  String get balanceWithdraw => 'Retirar';

  @override
  String get balanceWithdrawSubmitted => '¡Solicitud de retiro enviada!';

  @override
  String get balanceNoHistory => 'Sin historial de ganancias.';

  @override
  String get balanceNoPayouts => 'Sin historial de pagos.';

  @override
  String get boostersActiveModifiers => 'Modificadores Activos';

  @override
  String boostersCurrentReferralBonus(Object bonus) {
    return 'Bono de Referido Actual: +$bonus%';
  }

  @override
  String get boostersAvailableModifiers => 'Modificadores Disponibles';

  @override
  String get boostersApplyExtensions =>
      'Aplica extensiones de tiempo y activa bonos de referidos para tu sesión de minería actual.';

  @override
  String get boostersStartMiningPrompt =>
      '¡Empieza a minar en el tablero para desbloquear modificadores!';

  @override
  String get boostersNoBoosters => 'No hay potenciadores disponibles ahora.';

  @override
  String boostersTimeBoostTitle(Object hours) {
    return 'Bono de Tiempo ${hours}h';
  }

  @override
  String boostersCooldown(Object duration) {
    return 'Enfriamiento: $duration';
  }

  @override
  String get boostersSessionMaxed => 'Sesión al máximo de 24h.';

  @override
  String boostersExtendBy(Object hours) {
    return 'Extender sesión ${hours}h (Capacidad Máx)';
  }

  @override
  String boostersExtendBySimple(Object hours) {
    return 'Extender sesión ${hours}h';
  }

  @override
  String get boostersApply => 'Aplicar';

  @override
  String boostersReferralBoosting(Object boost) {
    return '¡Aumentando tu velocidad! (Activo) (+$boost%)';
  }

  @override
  String get boostersReferralMaxed => 'Capacidad de referidos al máximo.';

  @override
  String boostersReferralActiveMiner(Object boost) {
    return '¡Minero activo! Aplica para un bono de +$boost%.';
  }

  @override
  String get boostersActive => 'Activo';

  @override
  String get boostersErrorMustMine => '¡Debes empezar a minar primero!';

  @override
  String get boostersEnergyPotionConsumed => '¡Poción de energía consumida!';

  @override
  String boostersErrorFailedToExtend(Object error) {
    return 'Error al extender sesión: $error';
  }

  @override
  String get boostersReferralActivated => '¡Potenciador de referido activado!';

  @override
  String get gamesRunnerTitle => 'Cat Runner';

  @override
  String get gamesRunnerDesc => '¡Corre, salta y gana catoshi!';

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
  String get gamesComingSoon => 'Próximamente...';

  @override
  String get referralsTitle => 'Referidos';

  @override
  String get referralsInvitedBy => 'Invitado por';

  @override
  String get referralsNoOneYet => 'Nadie aún';

  @override
  String get referralsYourCode => 'Tu código de referido';

  @override
  String get referralsCopied => 'Copiado al portapapeles';

  @override
  String referralsShareMessage(Object code) {
    return '¡Únete a Catcoin PoE! Usa mi código $code para obtener un bono.\n\nEnlace: https://poe.catcoin.in/invite/$code';
  }

  @override
  String get referralsTotal => 'Total';

  @override
  String get referralsActiveCount => 'Activos';

  @override
  String get referralsBoostPercentage => '% de Bono';

  @override
  String get referralsYourReferrals => 'Tus Referidos';

  @override
  String get referralsNoReferrals => 'No referrals yet';

  @override
  String get referralsSharePrompt =>
      'Share your referral code to earn bonuses!';

  @override
  String get referralsActiveLast24h => 'Activo (Ult. 24h)';

  @override
  String get referralsInactive => 'Inactivo';

  @override
  String get referralsEnterInviterCode => 'Ingresar código de invitador';

  @override
  String get referralsInviterCodeInstruction =>
      'Si fuiste invitado por alguien, ingresa su código aquí para vincular tu cuenta.';

  @override
  String get referralsInviterCodeLabel => 'Código de Referido';

  @override
  String get referralsInviterCodeUpdated => '¡Código actualizado con éxito!';

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
  String get referralMilestoneBonusTitle => 'Bonus por hitos de referidos';

  @override
  String referralMilestoneBonusSubtitle(Object amount) {
    return 'Recompensa única de $amount catoshi por invitación';
  }

  @override
  String get referralBonusRewardAmountNote =>
      'Este importe lo configura el servidor y los administradores pueden actualizarlo.';

  @override
  String get referralBonusDetailAppTitle => 'Bonus de referido';

  @override
  String get referralBonusStatusHeading => 'Estado del bonus de referido';

  @override
  String referralBonusRewardForReferrer(Object amount) {
    return 'Bonus para ti (referente): $amount catoshi';
  }

  @override
  String referralBonusRewardCredited(Object amount) {
    return 'Recompensa ya acreditada ($amount catoshi).';
  }

  @override
  String referralBonusConditionsProgress(Object met) {
    return '$met de 3 condiciones cumplidas';
  }

  @override
  String referralBonusListAmount(Object amount) {
    return 'Bonus de referido: $amount catoshi';
  }

  @override
  String referralBonusDatesLine(Object joined, Object referred) {
    return 'Se unió $joined · Referido $referred';
  }

  @override
  String get referralBonusConditionMinedDays => 'Días de minería';

  @override
  String get referralBonusConditionMiningReward =>
      'Recompensa de minería (BASE)';

  @override
  String get referralBonusConditionGameReward => 'Recompensas de juegos';

  @override
  String get referralBonusStatePending => 'Condiciones pendientes';

  @override
  String get referralBonusStateEligible => 'Elegible para la recompensa';

  @override
  String get referralBonusStateRewarded => 'Recompensa acreditada';

  @override
  String get referralBonusStateUnderReview => 'En revisión del administrador';

  @override
  String get referralBonusStateRejected => 'Rechazado';

  @override
  String get profileSetupSkip => 'Saltar';

  @override
  String get profileSetupGallery => 'Galería';

  @override
  String get profileSetupCamera => 'Cámara';

  @override
  String profileSetupFailedImage(Object error) {
    return 'Error al elegir imagen: $error';
  }

  @override
  String get profileSetupDisplayNameLabel => 'Nombre (Opcional)';

  @override
  String get profileSetupDisplayNameHint => '¿Cómo te llamas?';

  @override
  String get profileSetupSaveContinue => 'Guardar y Continuar';

  @override
  String profileSetupFailedSave(Object error) {
    return 'Error al guardar perfil: $error';
  }

  @override
  String socialNoMissions(Object title) {
    return 'No hay $title disponibles en este momento.';
  }

  @override
  String get payoutHistoryScreenTitle => 'Historial de pagos';

  @override
  String get payoutNoHistory => 'No se encontró historial de pagos.';

  @override
  String get payoutViewTx => 'Ver TX';

  @override
  String payoutAddressTo(Object address) {
    return 'Para: $address';
  }

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get missionVerifyTitle => 'Verificación requerida';

  @override
  String get missionVerifyDiscord =>
      'Ingrese su nombre de usuario de Discord para que podamos verificar que se unió:';

  @override
  String get missionVerifyTelegram => 'Ingrese su ID numérico de Telegram:';

  @override
  String get missionVerifyGeneric =>
      'Ingrese su nombre de usuario/identificador para verificar:';

  @override
  String get missionHintDiscord => 'Ingresar nombre de usuario de Discord';

  @override
  String get missionHintTelegram => 'Ingresar ID numérico';

  @override
  String get missionHintGeneric => 'Ingresar nombre de usuario/identificador';

  @override
  String get missionHelpGetId => '¿Cómo obtener el ID?';

  @override
  String get missionSaveContinue => 'Guardar y continuar';

  @override
  String get missionVerificationStarted =>
      '¡Verificación iniciada! Por favor completa la tarea.';

  @override
  String missionClaimedSuccess(Object amount) {
    return '¡Reclamado $amount Catoshi!';
  }

  @override
  String missionFailed(Object error) {
    return 'Falló: $error';
  }

  @override
  String get missionExpired => 'Expirado';

  @override
  String missionExpiresInDays(Object days) {
    return 'Expira en $days días';
  }

  @override
  String missionExpiresInHours(Object hours) {
    return 'Expira en $hours horas';
  }

  @override
  String missionReward(Object amount) {
    return '+$amount Catoshi';
  }

  @override
  String get missionStatusVerifying => 'Verificando...';

  @override
  String get missionBtnClaim => 'Reclamar';

  @override
  String get telegramHelpInstructions =>
      '1. Abre Telegram.\n2. Busca @userinfobot (o escanea el QR a continuación).\n3. Haz clic en Iniciar (o envía /start).\n4. Responderá con tus datos. Busca \"Id\".\n5. Copia ese número y pégalo aquí.';

  @override
  String get telegramHelpBtnOpen => 'Abrir @userinfobot';

  @override
  String get telegramHelpQrLabel => 'O escanea el código QR:';

  @override
  String get telegramHelpQrError =>
      'Código QR no encontrado.\n(Agrega assets/images/telegram_qr.png)';

  @override
  String get resetPasswordSuccess =>
      'Contraseña restablecida con éxito. Por favor inicia sesión.';

  @override
  String get resetPasswordFailed => 'Error al restablecer la contraseña';

  @override
  String resetPasswordInstruction(Object email) {
    return 'Ingrese el código de 6 dígitos enviado a $email y su nueva contraseña.';
  }

  @override
  String get emailVerificationCodeSent =>
      '¡Código de verificación enviado a tu correo electrónico!';

  @override
  String get gameLauncherTitle => 'Cat Runner';

  @override
  String get gameLauncherDownloading => 'Descargando recursos del juego...';

  @override
  String get gameLauncherReady => 'Motor listo';

  @override
  String get gameLauncherRequired => 'Recursos del juego requeridos';

  @override
  String gameLauncherDownloadBtn(Object size) {
    return 'DESCARGAR RECURSOS (~$size)';
  }

  @override
  String get gameLauncherStartBtn => 'INICIAR JUEGO';

  @override
  String get gameLauncherResetBtn => 'Restablecer recursos';

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
  String get gameGameOverTitle => 'JUEGO TERMINADO';

  @override
  String get gameStatScore => 'Puntuación';

  @override
  String get gameStatDistance => 'Distancia';

  @override
  String get gameStatCoins => 'Monedas';

  @override
  String get gameStatCatoshiEarned => 'Catoshi ganado';

  @override
  String get gamePlayAgain => 'JUGAR DE NUEVO';

  @override
  String gameCooldownComeBack(Object time) {
    return 'Come back in $time';
  }

  @override
  String get gameCooldownLimitReached =>
      'Play limit reached. Please wait before playing again.';

  @override
  String get gameExit => 'SALIR';

  @override
  String get gamePausedTitle => 'PAUSADO';

  @override
  String get gameResume => 'REANUDAR';

  @override
  String get gameQuit => 'SALIR';

  @override
  String get updateTitle => 'Actualización disponible';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updateUrlError => 'No se pudo abrir la URL de actualización';

  @override
  String balancePayoutTo(Object address) {
    return 'Para: $address';
  }

  @override
  String get boostersSubtitle =>
      '¡Supercarga tu velocidad de minería y extiende las sesiones!';

  @override
  String get commonVersion => 'Versión';

  @override
  String get commonUser => 'Usuario';

  @override
  String get profileVerifiedTooltip =>
      'Verificado. Toque para desbloquear y editar.';

  @override
  String walletAddressLabel(Object address) {
    return 'Dirección: $address';
  }

  @override
  String walletGenerationError(Object error) {
    return 'Error de generación: $error';
  }

  @override
  String get walletDeleteWallet => 'Eliminar billetera';

  @override
  String get commonGenerate => 'Generar';

  @override
  String get badgeWeeklyTop => 'Top Semanal';

  @override
  String get badgeMonthlyTop => 'Top Mensual';

  @override
  String get badgeAllTimeTop => 'Top Histórico';

  @override
  String get badgeVerified => 'Usuario Verificado';

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
    return 'Una nueva versión ($version) está disponible.';
  }

  @override
  String get updateMandatory =>
      'Esta actualización es obligatoria para continuar usando la aplicación.';

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
  String get languageGroupInternational => 'Internacional';

  @override
  String get languageGroupIndian => 'India';
}
