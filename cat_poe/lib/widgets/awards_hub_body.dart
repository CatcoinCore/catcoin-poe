import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/leaderboard_entry.dart';
import '../models/user_badge.dart';
import '../services/api_service.dart';
import '../utils/user_badge_ui.dart';

class AwardsHubBody extends StatefulWidget {
  const AwardsHubBody({super.key});

  @override
  AwardsHubBodyState createState() => AwardsHubBodyState();
}

class AwardsHubBodyState extends State<AwardsHubBody>
    with SingleTickerProviderStateMixin {
  List<UserBadge> _badges = [];
  List<LeaderboardEntry> _global = [];
  List<LeaderboardEntry> _regional = [];
  List<({String gameType, List<LeaderboardEntry> leaders})> _games = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  late final List<DateTime> _periodOptions;
  int _selectedIndex = 0;

  DateTime get _selectedPeriod => _periodOptions[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _periodOptions = _buildPeriodOptions();
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> reload() => _fetchData();

  static List<DateTime> _buildPeriodOptions() {
    final now = DateTime.now().toUtc();
    final firstThisMonth = DateTime.utc(now.year, now.month, 1);
    final lastCompletedMonth = DateTime.utc(
      firstThisMonth.month == 1 ? firstThisMonth.year - 1 : firstThisMonth.year,
      firstThisMonth.month == 1 ? 12 : firstThisMonth.month - 1,
      1,
    );
    return List<DateTime>.generate(18, (i) {
      final m = lastCompletedMonth.month - i;
      final y = lastCompletedMonth.year + ((m - 1) ~/ 12);
      final normalizedMonth = ((m - 1) % 12 + 12) % 12 + 1;
      return DateTime.utc(y, normalizedMonth, 1);
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final period = _selectedPeriod;
      final badgesFuture = ApiService().getMyBadges();
      final summaryFuture = ApiService().getPreviousMonthSummary(
        year: period.year,
        month: period.month,
      );
      final results = await Future.wait<dynamic>([badgesFuture, summaryFuture]);
      if (!mounted) return;

      final badgesData = results[0] as List<dynamic>;
      final summary = results[1] as Map<String, dynamic>;
      List<LeaderboardEntry> parseLeaders(dynamic raw) {
        if (raw is! List) return [];
        return raw
            .map((e) =>
                LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final gamesRaw = summary['games'] as List<dynamic>? ?? [];
      final games = <({String gameType, List<LeaderboardEntry> leaders})>[];
      for (final g in gamesRaw) {
        final m = Map<String, dynamic>.from(g as Map);
        games.add(
          (
            gameType: (m['game_type'] as String? ?? ''),
            leaders: parseLeaders(m['leaders']),
          ),
        );
      }

      setState(() {
        _badges = badgesData
            .map((e) => UserBadge.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _global = parseLeaders(summary['global_leaders']);
        _regional = parseLeaders(summary['regional_leaders']);
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l.rewardsError(_error ?? ''),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: Text(l.commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedIndex,
                              dropdownColor: Colors.indigo.shade800,
                              decoration: InputDecoration(
                                labelText: l.awardsMonthlyChampions,
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              items: List<DropdownMenuItem<int>>.generate(
                                _periodOptions.length,
                                (i) => DropdownMenuItem<int>(
                                  value: i,
                                  child: Text(
                                    DateFormat.yMMMM(Localizations.localeOf(context).toString())
                                        .format(_periodOptions[i]),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val == null || val == _selectedIndex) return;
                                setState(() => _selectedIndex = val);
                                _fetchData();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.amber,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.amber,
                      tabs: const [
                        Tab(text: 'Global'),
                        Tab(text: 'Regional'),
                        Tab(text: 'Games'),
                        Tab(text: 'Personal'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _leadersTab(_global, scoreIsCatoshi: true, l: l),
                          _leadersTab(_regional, scoreIsCatoshi: true, l: l),
                          _gamesTab(l),
                          _personalTab(l),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _leadersTab(
    List<LeaderboardEntry> entries, {
    required bool scoreIsCatoshi,
    required AppLocalizations l,
  }) {
    if (entries.isEmpty) return _emptyPrev(l);
    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: _fetchData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (_, i) =>
            _buildWinnerTile(entries[i], scoreIsCatoshi: scoreIsCatoshi, l: l),
      ),
    );
  }

  Widget _gamesTab(AppLocalizations l) {
    final visibleGames = _games.where((g) => g.leaders.isNotEmpty).toList();
    if (visibleGames.isEmpty) return _emptyPrev(l);
    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: _fetchData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          for (final g in visibleGames) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Text(
                userGameTitle(l, g.gameType),
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final leader in g.leaders)
              _buildWinnerTile(leader, scoreIsCatoshi: false, l: l),
          ],
        ],
      ),
    );
  }

  Widget _personalTab(AppLocalizations l) {
    if (_badges.isEmpty) {
      return Center(
        child: Text(
          l.awardsNoAwards,
          style: const TextStyle(color: Colors.white60),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: _fetchData,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) => _buildBadgeCard(context, _badges[index]),
      ),
    );
  }

  Widget _emptyPrev(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          l.leaderboardComingSoon,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, UserBadge badge) {
    final l = AppLocalizations.of(context);
    final color = userBadgeColor(badge.badgeType);
    return Card(
      elevation: 6,
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showUserBadgeDetailSheet(context, badge),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(userBadgeIcon(badge.badgeType), size: 52, color: color),
              const SizedBox(height: 10),
              Text(
                userBadgeTitle(l, badge.badgeType),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMd().format(badge.awardedAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerTile(
    LeaderboardEntry winner, {
    required bool scoreIsCatoshi,
    required AppLocalizations l,
  }) {
    final medal = winner.rank == 1 ? '🥇' : (winner.rank == 2 ? '🥈' : '🥉');
    final medalColor = winner.rank == 1
        ? Colors.amber
        : (winner.rank == 2 ? Colors.blueGrey.shade200 : Colors.orange.shade700);
    final scoreLabel = scoreIsCatoshi
        ? '${_formatScore(winner.balance)} ${l.dashboardCatoshi}'
        : '${_formatScore(winner.balance)} Score';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: medalColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Text(medal, style: const TextStyle(fontSize: 24)),
        title: Text(
          winner.displayName?.isNotEmpty == true ? winner.displayName! : winner.username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${winner.country} • $scoreLabel',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: Icon(Icons.verified, color: medalColor, size: 20),
      ),
    );
  }

  String _formatScore(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}
