import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/mining_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_gear.dart';
import '../widgets/mining_session_ring_painter.dart';
import '../services/ad_service.dart';
import '../providers/mission_provider.dart';
import '../widgets/boosters_card.dart';
import 'balance_detail_screen.dart';
import 'rewards_screen.dart';
import '../providers/game_provider.dart';
import '../models/admin_config.dart';
import '../utils/time_boost_badge_count.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/markdown_safety.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Locale? _lastFetchedAdminLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = Provider.of<LocaleProvider>(context).locale;
    if (_lastFetchedAdminLocale == loc) return;
    _lastFetchedAdminLocale = loc;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.fetchConfig(languageCode: loc.languageCode);
      if (!mounted || adminProvider.config == null) return;
      _checkAndShowPopup(adminProvider.config!);
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
      Provider.of<GameProvider>(context, listen: false).fetchStatus();
      AdService().loadRewardedAd(context);
    });
  }

  void _checkAndShowPopup(AdminConfig config) async {
    final msg = config.globalPushMessage;
    if (msg == null || msg.trim().isEmpty) return;

    final hash = msg.hashCode.toString();
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_announcement_$hash') ?? false;

    if (!seen && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: MarkdownBody(
              data: msg,
              onTapLink: safeOnTapMarkdownLink,
              imageBuilder: safeMarkdownImageBuilder,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                prefs.setBool('seen_announcement_$hash', true);
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/catcoin_logo.png',
                width: 32, height: 32),
            const SizedBox(width: 8),
            Text(l.commonAppName),
          ],
        ),
        actions: [
          const AdminGear(),
        ],
      ),
      body: Consumer2<MiningProvider, AdminProvider>(
          builder: (context, miningProvider, adminProvider, child) {
        if (miningProvider.isLoading && miningProvider.stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            AbsorbPointer(
              absorbing: !miningProvider.isMining,
              child: RefreshIndicator(
                onRefresh: () async {
                  await miningProvider.fetchStats();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Welcome Message
                    Text(
                      l.dashboardWelcome(authProvider.user?.displayName ??
                          authProvider.user?.username ??
                          'User'),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (miningProvider.error != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        child: Text(miningProvider.error!,
                            style: const TextStyle(color: Colors.red)),
                      ),


                    // Balance Card
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BalanceDetailScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        clipBehavior:
                            Clip.antiAlias, // Ensure watermark doesn't overflow
                        child: Stack(
                          children: [
                            // Watermark
                            Positioned.fill(
                              child: Center(
                                child: Opacity(
                                  opacity: 0.1,
                                  child: Image.asset(
                                    'assets/images/catcoin_logo.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                // Ensure content is centered
                                child: Column(
                                  children: [
                                    Text(l.dashboardTotalBalance,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(
                                      miningProvider.stats?.balance
                                              .toStringAsFixed(0) ??
                                          "0",
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l.dashboardCatoshi,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mining Card with Session Ring
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Watermark
                          Positioned.fill(
                            child: Center(
                              child: Opacity(
                                opacity: 0.15,
                                child: Image.asset(
                                  'assets/images/catcoin_logo.png',
                                  width: 400,
                                  height: 400,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  // Calculate percentages for rings
                                  Builder(
                                    builder: (context) {
                                      double sessionDurationPercentage = 0.0;
                                      double elapsedPercentage = 0.0;

                                      final capMinutes = adminProvider
                                              .config
                                              ?.maxMiningDurationMinutes ??
                                          1440;
                                      final baseRing = findBaseActiveSession(
                                          miningProvider.stats
                                                  ?.activeSessions ??
                                              []);
                                      if (miningProvider.isMining &&
                                          baseRing != null) {
                                        final now = DateTime.now().toUtc();
                                        final totalSessionDuration = baseRing
                                            .endTime
                                            .difference(baseRing.startTime);
                                        final sessionMins =
                                            miningSessionDurationMinutes(
                                          baseRing.startTime,
                                          baseRing.endTime,
                                        );
                                        sessionDurationPercentage =
                                            (sessionMins / capMinutes)
                                                .clamp(0.0, 1.0);

                                        final totalSecs = totalSessionDuration
                                            .inSeconds
                                            .clamp(1, 1 << 30);
                                        final elapsed = now.difference(
                                            baseRing.startTime.toUtc());
                                        elapsedPercentage = (elapsed.inSeconds /
                                                totalSecs)
                                            .clamp(0.0, 1.0);
                                      }

                                      return SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: CustomPaint(
                                          painter: MiningSessionRingPainter(
                                            sessionDurationPercentage:
                                                sessionDurationPercentage,
                                            elapsedPercentage:
                                                elapsedPercentage,
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (miningProvider
                                                    .isMining) ...[
                                                  // Earned Catoshis (larger, on top, orange)
                                                  if (miningProvider
                                                          .stats
                                                          ?.activeSessions
                                                          .isNotEmpty ==
                                                      true) ...[
                                                    Text(
                                                      miningProvider
                                                          .stats!
                                                          .activeSessions
                                                          .fold<double>(0.0, (sum, s) => sum + s.totalEarned)
                                                          .toStringAsFixed(0),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.orange),
                                                    ),

                                                    Text(
                                                      l.dashboardCatoshi,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.orange),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  // Time remaining (smaller, below)
                                                  Text(
                                                    _formatDuration(
                                                        miningProvider
                                                            .timeLeft),
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontFamily:
                                                            'monospace'),
                                                  ),
                                                ] else ...[
                                                  Text(
                                                    l.dashboardNotMining,
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    "TAP TO START",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      letterSpacing: 1.2,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (miningProvider.isMining &&
                                      miningProvider.stats?.activeSessions
                                              .isNotEmpty ==
                                          true) ...[
                                    Column(
                                      children: [
                                        Text(
                                            l.dashboardRewardRate((miningProvider.stats!.activeSessions.fold<double>(0.0, (sum, s) => sum + (s.rewardY / s.rewardT)).round()).toString()),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Builder(
                                          builder: (context) {
                                            final capMin = adminProvider
                                                    .config
                                                    ?.maxMiningDurationMinutes ??
                                                1440;
                                            final baseDur =
                                                findBaseActiveSession(
                                                    miningProvider
                                                        .stats!
                                                        .activeSessions);
                                            if (baseDur == null) {
                                              return const SizedBox.shrink();
                                            }
                                            final currentMins =
                                                miningSessionDurationMinutes(
                                              baseDur.startTime,
                                              baseDur.endTime,
                                            );
                                            final currentHrs =
                                                currentMins / 60.0;
                                            final maxHrs = capMin / 60.0;

                                            return Text(
                                              l.dashboardCurrentDuration(
                                                currentHrs.toStringAsFixed(1),
                                                maxHrs.toStringAsFixed(1),
                                              ),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Builder(
                                          builder: (context) {
                                            double totalBoostPct = miningProvider.stats?.referralBoostPercentage ?? 0.0;
                                            for (var session in miningProvider.stats!.activeSessions) {
                                              if (session.sessionType == 'GAME_BOOST') {
                                                totalBoostPct += session.yieldPercentage;
                                              }
                                            }
                                            
                                            if (totalBoostPct <= 0) return const SizedBox.shrink();
                                            
                                            final perRef = adminProvider
                                                    .config
                                                    ?.referralBoostPercentage
                                                    .toStringAsFixed(0) ??
                                                '?';
                                            final capRefs = adminProvider
                                                    .config?.maxActiveReferrers
                                                    .toString() ??
                                                '?';
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.bolt,
                                                          color: Colors
                                                              .green.shade700,
                                                          size: 18),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "+${totalBoostPct.toStringAsFixed(0)}% Speed Boost",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .green.shade700,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: Text(
                                                      'Referral share: up to $capRefs slots at +$perRef% each; only referrals with an active mining session count.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Boosters Card navigating to dedicated screen
                    Consumer2<AdminProvider, AuthProvider>(
                      builder: (context, adminProvider, authProvider, _) {
                        return _DashboardBoostersCardWithBadge(
                          miningProvider: miningProvider,
                          adminConfig: adminProvider.config,
                          maxMiningDurationMinutes:
                              adminProvider.config?.maxMiningDurationMinutes ??
                                  1440,
                          userId: authProvider.user?.id,
                          boostLocalPrefsRevision:
                              miningProvider.boostLocalPrefsRevision,
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const _DashboardRewardsCard(),

                    const SizedBox(height: 16),
                    // Game Card was moved to the new Games screen tab.
                    ],
                  ),
                ),
              ),
              if (!miningProvider.isMining)
                _buildMiningOverlay(context, miningProvider),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleStartMining(
      BuildContext context, MiningProvider miningProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final config = adminProvider.config;

    if (config?.adRequiredForMiningStart == true) {
      AdService().showRewardedAd(
        context,
        userId: authProvider.user?.id ?? '',
        onReward: () async {
          await miningProvider.startMining();
          if (miningProvider.error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(miningProvider.error!),
                  backgroundColor: Colors.red),
            );
          }
        },
        onFailure: (errorMessage) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } else {
      await miningProvider.startMining();
      if (miningProvider.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(miningProvider.error!),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildMiningOverlay(
      BuildContext context, MiningProvider miningProvider) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_clock,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.dashboardNotMining,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Your mining session has ended. To unlock and view your balance, boosters, and play games, you must start a new session.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: miningProvider.isLoading
                              ? null
                              : () =>
                                  _handleStartMining(context, miningProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: miningProvider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : _PulsingButton(
                                  active: true,
                                  child: Text(
                                    l.dashboardStartMining,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardRewardsCard extends StatelessWidget {
  const _DashboardRewardsCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<MissionProvider>(
      builder: (context, missionProvider, _) {
        final unclaimedCount = missionProvider.missions
            .where((m) => !m.isCompleted && m.status != 'PENDING')
            .length;
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RewardsScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade700,
                    Colors.deepPurple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      if (unclaimedCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unclaimedCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.navRewards,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.rewardsAllMissions,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBoostersCardWithBadge extends StatefulWidget {
  final MiningProvider miningProvider;
  final AdminConfig? adminConfig;
  final int maxMiningDurationMinutes;
  final String? userId;
  final int boostLocalPrefsRevision;

  const _DashboardBoostersCardWithBadge({
    required this.miningProvider,
    required this.adminConfig,
    required this.maxMiningDurationMinutes,
    required this.userId,
    required this.boostLocalPrefsRevision,
  });

  @override
  State<_DashboardBoostersCardWithBadge> createState() =>
      _DashboardBoostersCardWithBadgeState();
}

class _DashboardBoostersCardWithBadgeState
    extends State<_DashboardBoostersCardWithBadge> {
  int _availableTimeBoosts = 0;

  @override
  void initState() {
    super.initState();
    _reloadTimeBoostCount();
  }

  @override
  void didUpdateWidget(covariant _DashboardBoostersCardWithBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSid = _activeSessionKey(oldWidget.miningProvider);
    final newSid = _activeSessionKey(widget.miningProvider);
    if (oldSid != newSid ||
        !identical(
            oldWidget.miningProvider.stats, widget.miningProvider.stats) ||
        oldWidget.adminConfig?.timeExtensionSlots !=
            widget.adminConfig?.timeExtensionSlots ||
        oldWidget.userId != widget.userId ||
        oldWidget.boostLocalPrefsRevision !=
            widget.boostLocalPrefsRevision ||
        oldWidget.maxMiningDurationMinutes !=
            widget.maxMiningDurationMinutes) {
      _reloadTimeBoostCount();
    }
  }

  String? _activeSessionKey(MiningProvider p) {
    final base = findBaseActiveSession(p.stats?.activeSessions ?? []);
    return base?.id;
  }

  Future<void> _reloadTimeBoostCount() async {
    final uid = widget.userId;
    final sessions = widget.miningProvider.stats?.activeSessions;
    if (uid == null || sessions == null || sessions.isEmpty) {
      if (mounted) setState(() => _availableTimeBoosts = 0);
      return;
    }

    final base = findBaseActiveSession(sessions);
    if (base == null) {
      if (mounted) setState(() => _availableTimeBoosts = 0);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final slots = await resolveTimeBoostSlots(
      baseSession: base,
      prefs: prefs,
      config: widget.adminConfig,
      userId: uid,
    );
    if (!mounted) return;

    final currentMins =
        miningSessionDurationMinutes(base.startTime, base.endTime);
    final count = countAvailableTimeBoosts(
      slots: slots,
      currentDurationMinutes: currentMins,
      maxDurationMinutes: widget.maxMiningDurationMinutes,
    );
    setState(() => _availableTimeBoosts = count);
  }

  @override
  Widget build(BuildContext context) {
    int boostersCount = 0;

    // 1. Available Time Boosts (Extensions for current session)
    boostersCount += _availableTimeBoosts;

    final stats = widget.miningProvider.stats;
    if (stats != null) {
      // 2. Available Referral Boosts (Active referrals able to speed up current session)
      boostersCount += stats.availableReferrals
          .where((r) => r.isActive && r.canBoost)
          .length;
    }

    // 3. Available Game Boosts (Inventory items)
    // We count these always so the user sees their "unused" inventory even if not mining.
    boostersCount += widget.miningProvider.availableGameBoosts.length;

    return BoostersCard(
      badgeCount: boostersCount > 0 ? boostersCount : null,
      onAfterBoostersClosed: _reloadTimeBoostCount,
    );
  }
}

class _PulsingButton extends StatefulWidget {
  final Widget child;
  final bool active;

  const _PulsingButton({required this.child, this.active = true});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PulsingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}


