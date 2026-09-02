import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import '../providers/mining_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../services/ad_service.dart';
import '../models/referral_info.dart';
import '../models/user_game_boost.dart';
import '../models/active_session.dart';
import '../models/time_boost_slot.dart';
import '../utils/time_boost_badge_count.dart';

class BoostersScreen extends StatefulWidget {
  const BoostersScreen({super.key});

  @override
  State<BoostersScreen> createState() => _BoostersScreenState();
}

class _BoostersScreenState extends State<BoostersScreen> {
  List<TimeBoostSlot> _timeBoostSlots = [];
  final Map<int, DateTime> _timeCooldowns = {};
  Timer? _timer;
  String? _currentSessionId;

  final TextEditingController _bonusCodeController = TextEditingController();
  bool _isRedeemingBonus = false;
  final Set<String> _loadingIds = {};

  // --- AnimatedList plumbing ---
  // We render the booster list through an [AnimatedList] so that the
  // re-sort triggered by activating a booster (available → unavailable
  // flips it from top to bottom) plays a smooth slide/fade rather than
  // teleporting.  [_renderedItems] mirrors the list the [AnimatedList] is
  // currently displaying; [_buildSortedBoosterList] produces the freshly
  // sorted desired list each build and we diff the two by stable key
  // (see [_BoosterListItem.key]).
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<_BoosterListItem> _renderedItems = [];
  static const Duration _reorderDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _refreshBoosts();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool needRefresh = false;
      final nowUtc = DateTime.now().toUtc();
      for (var entry in _timeCooldowns.entries) {
        if (!entry.value.toUtc().isAfter(nowUtc)) {
          needRefresh = true;
          break;
        }
      }
      if (needRefresh) {
        _refreshBoosts();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bonusCodeController.dispose();
    super.dispose();
  }

  Future<void> _refreshBoosts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    // 1. Wait for essential data to be ready to avoid 'guest' or 'default' race conditions
    if (authProvider.user == null || adminProvider.config == null) {
      return; 
    }

    final userId = authProvider.user!.id;

    // 2. Determine current session ID
    // CRITICAL: Only update _currentSessionId if we have stats. 
    // If stats are still loading, don't clear the boosters yet to avoid "ghost" refreshes.
    if (miningProvider.stats != null &&
        miningProvider.stats!.activeSessions.isNotEmpty == true) {
      final baseForId =
          findBaseActiveSession(miningProvider.stats!.activeSessions);
      if (baseForId == null) {
        if (miningProvider.isLoading) {
          return;
        }
        _currentSessionId = null;
        _timeBoostSlots = [];
        _timeCooldowns.clear();
        if (mounted) setState(() {});
        return;
      }
      _currentSessionId = baseForId.id.toString();
    } else if (miningProvider.isLoading) {
      // Still fetching stats, don't clear anything yet
      return;
    } else {
      // Definitely not mining or session ended
      _currentSessionId = null;
      _timeBoostSlots = [];
      _timeCooldowns.clear();
      if (mounted) setState(() {});
      return;
    }

    // 3. Load session time boosts + cooldowns (server-backed; legacy prefs fallback)
    final base = findBaseActiveSession(miningProvider.stats!.activeSessions);
    final slots = await resolveTimeBoostSlots(
      baseSession: base,
      prefs: prefs,
      config: adminProvider.config,
      userId: userId,
    );
    _timeBoostSlots = slots;
    _timeCooldowns.clear();
    final nowUtc = DateTime.now().toUtc();
    for (final s in slots) {
      final cd = s.cooldownUntil;
      if (cd != null && cd.isAfter(nowUtc)) {
        _timeCooldowns[s.hours] = cd;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _applyTimeBoost(int hours) async {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    final String loadingId = 'time_$hours';
    if (_loadingIds.contains(loadingId)) return;
    setState(() => _loadingIds.add(loadingId));

    Future<void> runExtension() async {
      final l = AppLocalizations.of(context);
      try {
        await miningProvider.extendSession(hours);
        if (miningProvider.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(miningProvider.error!),
                backgroundColor: Colors.red),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l.boostersEnergyPotionConsumed),
                backgroundColor: Colors.green),
          );

          await _refreshBoosts();
          miningProvider.notifyBoostLocalPrefsChanged();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l.boostersErrorFailedToExtend(e.toString())),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loadingIds.remove(loadingId));
      }
    }

    if (adminProvider.config?.adRequiredForTimeBoost == true) {
      AdService().showRewardedAd(
        context,
        userId: authProvider.user?.id ?? '',
        onReward: runExtension,
        onFailure: (errorMessage) {
          if (mounted) {
            setState(() => _loadingIds.remove(loadingId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        },
      );
    } else {
      await runExtension();
    }
  }

  Future<void> _activateReferralBoost(String referralId) async {
    final String loadingId = 'referral_$referralId';
    if (_loadingIds.contains(loadingId)) return;
    setState(() => _loadingIds.add(loadingId));

    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final l = AppLocalizations.of(context);
    try {
      await miningProvider.activateBoost(referralId);
      if (miningProvider.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.boostersReferralActivated),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingIds.remove(loadingId);
        });
      }
    }
  }

  Future<void> _handleActivateGameBoost(UserGameBoost boost) async {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final l = AppLocalizations.of(context);

    if (!miningProvider.isMining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.boostersErrorMustMine),
            backgroundColor: Colors.red),
      );
      return;
    }
    
    final String loadingId = 'game_${boost.id}';
    if (_loadingIds.contains(loadingId)) return;
    setState(() => _loadingIds.add(loadingId));
    
    try {
      await miningProvider.activateGameBoost(boost.id);
      if (miningProvider.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.boostersGameBoostSuccess),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.boostersGameBoostError(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingIds.remove(loadingId));
      }
    }
  }

  Future<void> _redeemSpecialBonus() async {
    final code = _bonusCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isRedeemingBonus = true);
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    
    try {
      await miningProvider.redeemSpecialBonus(code);
      if (mounted) {
        _bonusCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Special bonus redeemed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Invalid bonus code') 
              ? 'Invalid bonus code' 
              : 'Failed to redeem bonus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeemingBonus = false);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Unified Item Class to help sort Referral and Time Boosts
  List<_BoosterListItem> _buildSortedBoosterList() {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    int currentDurationMinutes = 0;
    final baseSession =
        findBaseActiveSession(miningProvider.stats?.activeSessions ?? []);
    if (miningProvider.isMining && baseSession != null) {
      currentDurationMinutes = miningSessionDurationMinutes(
        baseSession.startTime,
        baseSession.endTime,
      );
    }
    final capMinutes =
        adminProvider.config?.maxMiningDurationMinutes ?? 1440;
    final totalReferralsAllowed = adminProvider.config?.maxActiveReferrers ?? 5;

    // Count active referrals
    int currentlyActiveReferrals = 0;
    final List<ReferralInfo> availableReferrals =
        miningProvider.stats?.availableReferrals ?? [];
    for (var ref in availableReferrals) {
      if (!ref.isActive) continue;
      if (ref.activeBoostSessionId != null) currentlyActiveReferrals++;
    }

    final bool isReferralCapReached =
        currentlyActiveReferrals >= totalReferralsAllowed;
    final double referralBoostPercentage =
        adminProvider.config?.referralBoostPercentage.toDouble() ?? 5.0;

    List<_BoosterListItem> items = [];

    // 1. Map Time Boosts
    for (final slot in _timeBoostSlots) {
      final hours = slot.hours;
      final isOnCooldown = _timeCooldowns.containsKey(hours);
      final fullyMaxedOut = currentDurationMinutes >= capMinutes;
      final inactive = !slot.active;
      final isUnavailable =
          isOnCooldown || fullyMaxedOut || inactive;

      items.add(_BoosterListItem(
        type: BoosterType.time,
        hours: hours,
        isUnavailable: isUnavailable,
        widget: _buildTimeCard(
            hours,
            isOnCooldown,
            fullyMaxedOut,
            inactive,
            currentDurationMinutes,
            capMinutes),
      ));
    }

    // 2. Map Referral Boosts (referrals with an active BASE mining session — matches server)
    for (var ref in availableReferrals) {
      if (!ref.isActive) continue;

      final isAlreadyActivated = ref.activeBoostSessionId != null;
      final bool cantActivateMore = !isAlreadyActivated && isReferralCapReached;
      final bool isUnavailable = isAlreadyActivated || cantActivateMore;

      items.add(_BoosterListItem(
        type: BoosterType.referral,
        referral: ref,
        isUnavailable: isUnavailable,
        widget: _buildReferralCard(
            ref, isAlreadyActivated, cantActivateMore, referralBoostPercentage),
      ));
    }
    
    // 3. Map Game Boosts (Inventory)
    for (var boost in miningProvider.availableGameBoosts) {
      items.add(_BoosterListItem(
        type: BoosterType.game,
        gameBoost: boost,
        isUnavailable: false,
        widget: _buildGameBoostCard(boost),
      ));
    }

    // 4. Map Active Game Sessions (to keep them visible while active)
    if (miningProvider.stats != null) {
      for (var session in miningProvider.stats!.activeSessions) {
        if (session.sessionType == 'GAME_BOOST') {
          // Reconstruct a temporary UserGameBoost for the UI
          final activeBoost = UserGameBoost(
            id: session.id,
            userId: '', // Not needed for UI
            percentage: session.yieldPercentage,
            durationMinutes: session.endTime.difference(session.startTime).inMinutes,
            isUsed: true,
            earnedAt: session.startTime,
          );
          
          items.add(_BoosterListItem(
            type: BoosterType.game,
            gameBoost: activeBoost,
            isUnavailable: true,
            widget: _buildGameBoostCard(activeBoost, activeSession: session),
          ));
        }
      }
    }

    // 5. Sort: Active/Available on top, then Unavailable on bottom
    items.sort((a, b) {
      if (!a.isUnavailable && b.isUnavailable) return -1;
      if (a.isUnavailable && !b.isUnavailable) return 1;
      // If both available/unavailable, just keep them roughly ordered by type
      return a.type.index.compareTo(b.type.index);
    });

    return items;
  }

  Widget _buildTimeCard(int hours, bool isOnCooldown, bool fullyMaxedOut,
      bool inactive, int currentDurationMinutes, int capMinutes) {
    Duration remaining = Duration.zero;
    if (isOnCooldown && _timeCooldowns[hours] != null) {
      remaining = _timeCooldowns[hours]!.difference(DateTime.now());
    }

    final int addMinutes = hours * 60;
    final int theoreticalMaxMins = currentDurationMinutes + addMinutes;
    final bool needsCapping = theoreticalMaxMins > capMinutes;
    final double effectiveHoursToAdd = needsCapping
        ? max(0.0, (capMinutes - currentDurationMinutes) / 60.0)
        : hours.toDouble();

    final bool canUse = !isOnCooldown && !fullyMaxedOut && !inactive;
    final String loadingId = 'time_$hours';
    final bool isLoading = _loadingIds.contains(loadingId);

    final l = AppLocalizations.of(context);
    String subtitleText;
    if (isOnCooldown && remaining.inSeconds > 0) {
      subtitleText = l.boostersCooldown(_formatDuration(remaining));
    } else if (inactive && !fullyMaxedOut) {
      subtitleText =
          'Not needed — smaller boost already covers remaining session time.';
    } else if (fullyMaxedOut) {
      subtitleText = l.boostersSessionMaxed;
    } else if (needsCapping) {
      subtitleText = l.boostersExtendBy(effectiveHoursToAdd.toStringAsFixed(1));
    } else {
      subtitleText = l.boostersExtendBySimple(hours.toString());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: (isOnCooldown || fullyMaxedOut || inactive) ? 1 : 3,
      color: (isOnCooldown || fullyMaxedOut || inactive)
          ? Colors.grey.shade200
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (isOnCooldown || fullyMaxedOut || inactive)
              ? Colors.grey
              : Colors.orangeAccent,
          child: const Icon(Icons.timer, color: Colors.white),
        ),
        title: Text(l.boostersTimeBoostTitle(hours.toString()),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (isOnCooldown || fullyMaxedOut || inactive)
                    ? Colors.grey.shade700
                    : Colors.black87)),
        subtitle: Text(subtitleText,
            style: TextStyle(
                color: (isOnCooldown || fullyMaxedOut || inactive)
                    ? Colors.redAccent
                    : (needsCapping ? Colors.orange.shade800 : Colors.grey))),
        trailing: ElevatedButton(
          onPressed: (canUse && !isLoading) ? () => _applyTimeBoost(hours) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: isLoading ? Colors.deepPurple.shade300 : Colors.grey.shade400,
          ),
          child: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(l.boostersApply),
        ),
      ),
    );
  }

  Widget _buildReferralCard(ReferralInfo ref, bool isAlreadyActivated,
      bool cantActivateMore, double boostPct) {
    final displayName = ref.referralDisplayName?.isNotEmpty == true
        ? ref.referralDisplayName!
        : ref.referralUsername;

    final l = AppLocalizations.of(context);
    String subtitleText;
    if (isAlreadyActivated) {
      subtitleText = l.boostersReferralBoosting(boostPct.toStringAsFixed(1));
    } else if (cantActivateMore) {
      subtitleText = l.boostersReferralMaxed;
    } else {
      subtitleText = l.boostersReferralActiveMiner(boostPct.toStringAsFixed(1));
    }

    final String loadingId = 'referral_${ref.referralId}';
    final bool isLoading = _loadingIds.contains(loadingId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: (isAlreadyActivated || cantActivateMore) ? 1 : 3,
      color: (isAlreadyActivated || cantActivateMore)
          ? Colors.grey.shade100
          : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isAlreadyActivated
                  ? Colors.green.shade200
                  : Colors.transparent)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAlreadyActivated
              ? Colors.green
              : (cantActivateMore ? Colors.grey : Colors.blueAccent),
          child: const Icon(Icons.people, color: Colors.white),
        ),
        title: Text(displayName,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(subtitleText,
            style: TextStyle(
                color: isAlreadyActivated
                    ? Colors.green.shade700
                    : Colors.grey.shade600)),
        trailing: ElevatedButton(
          onPressed: (!isAlreadyActivated &&
                  !cantActivateMore &&
                  !isLoading)
              ? () => _activateReferralBoost(ref.referralId)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isAlreadyActivated ? Colors.green : Colors.blueAccent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: isAlreadyActivated
                ? Colors.green.shade300
                : (isLoading ? Colors.blueAccent.shade200 : Colors.grey.shade400),
          ),
          child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isAlreadyActivated ? l.boostersActive : l.boostersApply),
        ),
      ),
    );
  }

  Widget _buildGameBoostCard(UserGameBoost boost, {ActiveSession? activeSession}) {
    final l = AppLocalizations.of(context);
    final bool isActive = activeSession != null;
    
    Duration remaining = Duration.zero;
    if (isActive) {
      remaining = activeSession.endTime.difference(DateTime.now());
    }

    final String loadingId = 'game_${boost.id}';
    final bool isLoading = _loadingIds.contains(loadingId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 1 : 3,
      color: isActive ? Colors.green.shade50 : Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isActive ? Colors.green.shade200 : Colors.purple.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.purple,
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
        title: Text(
          l.boostersGameBoostTitle(boost.percentage.toStringAsFixed(0)),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.boostersGameBoostDuration((boost.durationMinutes ~/ 60).toString(), (boost.durationMinutes % 60).toString()),
              style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.purple.shade700),
            ),
            if (isActive && remaining.inSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Remaining: ${_formatDuration(remaining)}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: (isActive || isLoading) ? null : () => _handleActivateGameBoost(boost),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.green : Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: isActive ? Colors.green.shade300 : (isLoading ? Colors.purple.shade300 : Colors.grey.shade400),
          ),
          child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isActive ? l.boostersActive : l.boostersActivate),
        ),
      ),
    );
  }

  /// Wraps a booster tile with the slide+fade transition used by [AnimatedList].
  Widget _animatedTile(Animation<double> anim, Widget child) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }

  /// Diff [newItems] (this build's desired order) against [_renderedItems]
  /// (what [AnimatedList] currently shows) and play insert/remove animations
  /// for any structural change.  Items present in both lists at differing
  /// positions are treated as remove-then-reinsert so that a flipping
  /// available→unavailable booster visibly slides down to the bottom group.
  void _syncRenderedItems(List<_BoosterListItem> newItems) {
    final listState = _listKey.currentState;
    if (listState == null) return;

    final newKeys = newItems.map((e) => e.key).toList();

    // 1) Remove items no longer present.  Iterate from the end so indices
    // stay valid as we mutate [_renderedItems].
    for (int i = _renderedItems.length - 1; i >= 0; i--) {
      final item = _renderedItems[i];
      if (!newKeys.contains(item.key)) {
        final removed = _renderedItems.removeAt(i);
        listState.removeItem(
          i,
          (ctx, anim) => _animatedTile(anim, removed.widget),
          duration: _reorderDuration,
        );
      }
    }

    // 2) Walk the desired order; reposition or insert as needed.  Items
    // already in the right slot just get their cached widget refreshed.
    for (int i = 0; i < newItems.length; i++) {
      final target = newItems[i];
      if (i < _renderedItems.length && _renderedItems[i].key == target.key) {
        _renderedItems[i] = target; // refresh widget ref in-place
        continue;
      }
      final existingIdx =
          _renderedItems.indexWhere((x) => x.key == target.key);
      if (existingIdx >= 0) {
        final old = _renderedItems.removeAt(existingIdx);
        listState.removeItem(
          existingIdx,
          (ctx, anim) => _animatedTile(anim, old.widget),
          duration: _reorderDuration,
        );
      }
      _renderedItems.insert(i, target);
      listState.insertItem(i, duration: _reorderDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final miningProvider = Provider.of<MiningProvider>(context);

    final baseLive =
        findBaseActiveSession(miningProvider.stats?.activeSessions ?? []);
    final String? liveSessionId =
        (miningProvider.isMining && baseLive != null) ? baseLive.id : null;

    if (liveSessionId != _currentSessionId) {
      Future.microtask(() => _refreshBoosts());
    }

    final sortedListItems = _buildSortedBoosterList();

    // Fast-path: when order is unchanged (e.g. cooldown timer tick), refresh
    // the cached widget refs in place so card contents update without
    // scheduling any AnimatedList work.  Structural changes go through
    // [_syncRenderedItems] post-frame.
    final newKeys = sortedListItems.map((e) => e.key).toList();
    final oldKeys = _renderedItems.map((e) => e.key).toList();
    if (listEquals(newKeys, oldKeys)) {
      for (int i = 0; i < sortedListItems.length; i++) {
        _renderedItems[i] = sortedListItems[i];
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncRenderedItems(sortedListItems);
      });
    }

    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.boostersTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.boostersAvailableModifiers,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.boostersApplyExtensions,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
      
                  if (!miningProvider.isMining)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                          child: Text(
                        l.boostersStartMiningPrompt,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                            fontSize: 16),
                        textAlign: TextAlign.center,
                      )),
                    )
                  else ...[
                    if (sortedListItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                            child: Text(
                          l.boostersNoBoosters,
                          style: const TextStyle(color: Colors.grey),
                        )),
                      )
                    else
                      AnimatedList(
                        key: _listKey,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        initialItemCount: _renderedItems.length,
                        itemBuilder: (ctx, i, anim) {
                          if (i >= _renderedItems.length) {
                            return const SizedBox.shrink();
                          }
                          return _animatedTile(anim, _renderedItems[i].widget);
                        },
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Fixed Bottom Special Bonus Redemption Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Special Bonus',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Enter your unique 24-character code to claim your reward.',
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bonusCodeController,
                          decoration: InputDecoration(
                            hintText: '24-character code',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isRedeemingBonus ? null : _redeemSpecialBonus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isRedeemingBonus 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('REDEEM'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum BoosterType { time, referral, game }

class _BoosterListItem {
  final BoosterType type;
  final bool isUnavailable;
  final Widget widget;
  // Metadata for distinct mapping if needed
  final int? hours;
  final ReferralInfo? referral;
  final UserGameBoost? gameBoost;

  _BoosterListItem({
    required this.type,
    required this.isUnavailable,
    required this.widget,
    this.hours,
    this.referral,
    this.gameBoost,
  });

  /// Stable identity across rebuilds — used by [AnimatedList] diffing in
  /// [_BoostersScreenState] to detect reorders vs. fresh inserts.
  String get key {
    switch (type) {
      case BoosterType.time:
        return 'time_${hours ?? 0}';
      case BoosterType.referral:
        return 'referral_${referral?.referralId ?? ""}';
      case BoosterType.game:
        return 'game_${gameBoost?.id ?? ""}';
    }
  }
}


