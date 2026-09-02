import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/leaderboard_entry.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/admin_gear.dart';
import '../widgets/awards_hub_body.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import '../services/game_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialGameType;

  const LeaderboardScreen({
    super.key,
    this.initialIndex = 0,
    this.initialGameType,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<AwardsHubBodyState> _awardsHubKey =
      GlobalKey<AwardsHubBodyState>();

  // Global
  List<LeaderboardEntry> _globalMiners = [];
  bool _globalLoading = true;
  String? _globalError;

  // Regional
  List<LeaderboardEntry> _regionalMiners = [];
  bool _regionalLoading = true;
  String? _regionalError;

  // Games
  List<LeaderboardEntry> _gameLeaders = [];
  bool _gamesLoading = true;
  String? _gamesError;
  String _selectedGameType = 'RUNNER';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    if (widget.initialGameType != null) {
      _selectedGameType = widget.initialGameType!;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _handleTabChange();
      }
    });

    // Initial fetch based on starting tab
    _handleTabChange();
  }

  void _handleTabChange() {
    switch (_tabController.index) {
      case 0:
        if (_globalLoading || _globalMiners.isEmpty) _fetchGlobal();
        break;
      case 1:
        if (_regionalLoading || _regionalMiners.isEmpty) _fetchRegional();
        break;
      case 2:
        if (_gamesLoading || _gameLeaders.isEmpty) _fetchGameLeaders();
        break;
      case 3:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _awardsHubKey.currentState?.reload();
        });
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchGlobal() async {
    setState(() { _globalLoading = true; _globalError = null; });
    try {
      final data = await ApiService().getGlobalLeaderboard(limit: 10);
      if (mounted) setState(() { _globalMiners = data.map((e) => LeaderboardEntry.fromJson(e)).toList(); _globalLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _globalError = e.toString(); _globalLoading = false; });
    }
  }

  Future<void> _fetchRegional() async {
    setState(() { _regionalLoading = true; _regionalError = null; });
    try {
      final data = await ApiService().getRegionalLeaderboard(limit: 10);
      if (mounted) setState(() { _regionalMiners = data.map((e) => LeaderboardEntry.fromJson(e)).toList(); _regionalLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _regionalError = e.toString(); _regionalLoading = false; });
    }
  }

  Future<void> _fetchGameLeaders() async {
    setState(() { _gamesLoading = true; _gamesError = null; });
    try {
      final data = await GameService().getLeaderboard(_selectedGameType);
      final List<dynamic> leaders = data['leaders'] ?? [];
      if (mounted) {
        setState(() {
          _gameLeaders = leaders.map((e) {
            // Map GameLeaderboardEntry keys to LeaderboardEntry
            return LeaderboardEntry(
              id: e['id'],
              username: e['username'],
              displayName: e['display_name'],
              country: e['country'],
              balance: (e['score'] as num).toDouble(),
              rank: e['rank'],
            );
          }).toList();
          _gamesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _gamesError = e.toString(); _gamesLoading = false; });
    }
  }

  Widget _buildFlag(String? countryCode) {
    final code = (countryCode == null || countryCode.isEmpty || countryCode.length != 2)
        ? 'us'
        : countryCode.toLowerCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://flagcdn.com/w40/$code.png',
        width: 24,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Text('🌍', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  // ── Podium colors / icons for top 3
  static const _podiumColors = [Color(0xFFFFD700), Color(0xFFB0BEC5), Color(0xFFCD7F32)];
  static const _podiumIcons = ['🥇', '🥈', '🥉'];

  Widget _buildTop3Card(BuildContext context, LeaderboardEntry miner, bool isSelf, {String? scoreLabel}) {
    final l = AppLocalizations.of(context);
    final displayName = miner.displayName?.isNotEmpty == true ? miner.displayName! : miner.username;
    final medalColor = _podiumColors[miner.rank - 1];
    final medal = _podiumIcons[miner.rank - 1];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            medalColor.withValues(alpha: isSelf ? 0.35 : 0.2),
            medalColor.withValues(alpha: isSelf ? 0.1 : 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: medalColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: medalColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: medalColor.withValues(alpha: 0.3),
              child: Text(
                '#${miner.rank}',
                style: TextStyle(
                  color: miner.rank == 1 ? Colors.amber.shade800 : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(medal, style: const TextStyle(fontSize: 14)),
          ],
        ),
        title: Row(
          children: [
            _buildFlag(miner.country),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelf ? Colors.orange.shade800 : (isDark ? Colors.white : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(l.leaderboardYou, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        trailing: Text(
          '${_formatScore(miner.balance)} ${scoreLabel ?? l.dashboardCatoshi}',
          style: TextStyle(
            color: medalColor == const Color(0xFFFFD700) ? Colors.amber.shade700 : Colors.blueGrey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularCard(BuildContext context, LeaderboardEntry miner, bool isSelf, {String? scoreLabel}) {
    final l = AppLocalizations.of(context);
    final displayName = miner.displayName?.isNotEmpty == true ? miner.displayName! : miner.username;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelf 
            ? (isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50) 
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelf ? Border.all(color: Colors.orange.shade300, width: 1) : null,
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blueGrey.shade100,
          child: Text(
            '#${miner.rank}',
            style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Row(
          children: [
            _buildFlag(miner.country),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf)
              Text(l.leaderboardYou, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Text(
          '${_formatScore(miner.balance)} ${scoreLabel ?? l.dashboardCatoshi}',
          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  String _formatScore(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  Widget _buildLeaderboardList(
    BuildContext context, List<LeaderboardEntry> miners, bool loading, String? error,
    Future<void> Function() onRefresh, String emptyMessage,
    {String? scoreLabel}
  ) {
    final l = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh), label: Text(l.commonRetry)),
          ],
        ),
      );
    }
    if (miners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    final top3 = miners.where((m) => m.rank <= 3).toList();
    final rest = miners.where((m) => m.rank > 3).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // ── Top 3 Section
          if (top3.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          l.leaderboardTopMiners,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.amber.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...top3.map((m) => _buildTop3Card(context, m, m.id == authProvider.user?.id, scoreLabel: scoreLabel)),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // ── Divider + rest label
          if (rest.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            l.leaderboardChallengers,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...rest.map((m) => _buildRegularCard(context, m, m.id == authProvider.user?.id, scoreLabel: scoreLabel)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    final l = AppLocalizations.of(context);
    final games = [
      {'id': 'RUNNER', 'color': Colors.orange},
      {'id': 'TICTACTOE', 'color': Colors.blue},
      {'id': 'SUDOKU', 'color': Colors.purple},
      {'id': 'COLLAGE', 'color': Colors.green},
      {'id': 'ARROW', 'color': Colors.lightBlue},
      {'id': 'TWENTY48', 'color': Colors.deepOrange},
      {'id': 'TILE_SWAP', 'color': Colors.teal},
    ];
    
    return Column(
      children: [
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: games.map((game) {
                final gameId = game['id'] as String;
                final gameColor = game['color'] as Color;
                final isSelected = _selectedGameType == gameId;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Text(_gameName(gameId, l)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGameType = gameId;
                            _gamesLoading = true;
                          });
                          _fetchGameLeaders();
                        }
                      },
                      selectedColor: gameColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      elevation: isSelected ? 4 : 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? gameColor : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _buildLeaderboardList(
            context, 
            _gameLeaders, 
            _gamesLoading, 
            _gamesError, 
            _fetchGameLeaders, 
            'No leaders for this game yet.',
            scoreLabel: 'Score',
          ),
        ),
      ],
    );
  }

  String _gameName(String type, AppLocalizations l) {
    switch (type) {
      case 'RUNNER': return l.gamesRunnerTitle;
      case 'TICTACTOE': return l.gamesTictactoeTitle;
      case 'SUDOKU': return l.gamesSudokuTitle;
      case 'COLLAGE': return l.gamesCollageTitle;
      case 'ARROW': return l.gamesArrowTitle;
      case 'TWENTY48': return l.gamesTwenty48Title;
      case 'TILE_SWAP': return l.gamesTileSwapTitle;
      default: return type;
    }
  }

  Widget _buildAwardsTab() {
    return AwardsHubBody(key: _awardsHubKey);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.leaderboardTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const AdminGear(),
        ],
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.public, size: 18), text: l.leaderboardGlobal),
            Tab(icon: const Icon(Icons.flag, size: 18), text: l.leaderboardRegional),
            Tab(icon: const Icon(Icons.sports_esports, size: 18), text: l.leaderboardGames),
            Tab(icon: const Icon(Icons.workspace_premium, size: 18), text: l.leaderboardAwards),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(context, _globalMiners, _globalLoading, _globalError, _fetchGlobal, l.leaderboardNoGlobal),
          _buildLeaderboardList(context, _regionalMiners, _regionalLoading, _regionalError, _fetchRegional, l.leaderboardNoRegional),
          _buildGamesTab(),
          _buildAwardsTab(),
        ],
      ),
    );
  }
}

