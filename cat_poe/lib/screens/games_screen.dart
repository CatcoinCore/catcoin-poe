import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'leaderboard_screen.dart';
import '../games/arrow_screen.dart';
import '../games/runner/ui/game_launcher_screen.dart';
import '../games/tic_tac_toe_screen.dart';
import '../games/sudoku_screen.dart';
import '../games/sliding_puzzle_screen.dart';
import '../games/tunnel_miner/presentation/tunnel_miner_screen.dart';
import '../games/twenty48_screen.dart';
import '../games/tile_swap/tile_swap_screen.dart';
import '../games/runner/systems/asset_pack_service.dart';
import '../providers/admin_provider.dart';
import '../providers/game_provider.dart';
import '../utils/games_screen_eligibility.dart';
import '../widgets/admin_gear.dart';

/// Screen listing all available games within the application.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).fetchStatus();
      final mini = Provider.of<MiniGameAssetService>(context, listen: false);
      unawaited(_prefetchMiniAssets(mini));
    });
  }

  Future<void> _prefetchMiniAssets(MiniGameAssetService mini) async {
    await mini.checkAssets();
    if (!mounted) return;
    if (!mini.isReady) {
      await mini.downloadAssets();
    }
  }

  int _playsRemaining(GameStatusItem? status) {
    final maxG = status?.maxGames;
    if (maxG == null) return 0;
    final left = maxG - (status?.playCount ?? 0);
    return left < 0 ? 0 : left;
  }

  String _getRemainingTime(DateTime? until) {
    if (until == null) return '';
    final diff = until.difference(DateTime.now());
    if (diff.isNegative) return '';

    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.gamesTitle),
        actions: [
          const AdminGear(),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          final config = adminProvider.config;
          final statusMap = gameProvider.statusMap;

          return RefreshIndicator(
            onRefresh: () => gameProvider.fetchStatus(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (isGameRowOnGamesScreenVisible(config, 'RUNNER')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesRunnerTitle,
                    description: l.gamesRunnerDesc,
                    reward: l.gameWinReward('Up to 500'),
                    icon: Icons.videogame_asset,
                    colors: [
                      Colors.orange.shade700,
                      Colors.deepOrange.shade600
                    ],
                    status: statusMap['RUNNER'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameLauncherScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'RUNNER',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'MINER')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesTunnelMinerTitle,
                    description: l.gamesTunnelMinerDesc,
                    reward: l.gameWinReward(
                        statusMap['MINER']?.reward?.toString() ?? '75'),
                    icon: Icons.landscape,
                    colors: [
                      Colors.brown.shade700,
                      Colors.deepOrange.shade900,
                    ],
                    status: statusMap['MINER'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TunnelMinerScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'MINER',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'TICTACTOE')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesTictactoeTitle,
                    description: l.gamesTictactoeDesc,
                    reward: l.gameWinReward(
                        statusMap['TICTACTOE']?.reward?.toString() ?? '10'),
                    icon: Icons.grid_3x3,
                    colors: [Colors.blue.shade700, Colors.indigo.shade600],
                    status: statusMap['TICTACTOE'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TicTacToeScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'TICTACTOE',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'SUDOKU')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesSudokuTitle,
                    description: l.gamesSudokuDesc,
                    reward: l.gameWinReward(
                        statusMap['SUDOKU']?.reward?.toString() ?? '100'),
                    icon: Icons.apps,
                    colors: [
                      Colors.purple.shade700,
                      Colors.deepPurple.shade600
                    ],
                    status: statusMap['SUDOKU'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SudokuScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'SUDOKU',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'COLLAGE')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesCollageTitle,
                    description: l.gamesCollageDesc,
                    reward: l.gameWinReward(
                        statusMap['COLLAGE']?.reward?.toString() ?? '50'),
                    icon: Icons.extension,
                    colors: [Colors.green.shade700, Colors.teal.shade600],
                    status: statusMap['COLLAGE'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SlidingPuzzleScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'COLLAGE',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'ARROW')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesArrowTitle,
                    description: l.gamesArrowDesc,
                    reward: l.gameWinReward(
                        statusMap['ARROW']?.reward?.toString() ?? '30'),
                    icon: Icons.swipe,
                    colors: [
                      Colors.lightBlue.shade700,
                      Colors.cyan.shade700,
                    ],
                    status: statusMap['ARROW'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArrowScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'ARROW',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'TWENTY48')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesTwenty48Title,
                    description: l.gamesTwenty48Desc,
                    reward: l.gameWinReward(
                        statusMap['TWENTY48']?.reward?.toString() ?? '75'),
                    icon: Icons.grid_view,
                    colors: [
                      Colors.deepOrange.shade700,
                      Colors.orange.shade800,
                    ],
                    status: statusMap['TWENTY48'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Twenty48Screen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'TWENTY48',
                  ),
                  const SizedBox(height: 16),
                ],
                if (isGameRowOnGamesScreenVisible(config, 'TILE_SWAP')) ...[
                  _buildGameCard(
                    context,
                    title: l.gamesTileSwapTitle,
                    description: l.gamesTileSwapDesc,
                    reward: l.gameWinReward(
                        statusMap['TILE_SWAP']?.reward?.toString() ?? '25'),
                    icon: Icons.swap_horiz,
                    colors: [
                      Colors.teal.shade700,
                      Colors.cyan.shade800,
                    ],
                    status: statusMap['TILE_SWAP'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TileSwapScreen(),
                        ),
                      ).then((_) => gameProvider.fetchStatus());
                    },
                    gameType: 'TILE_SWAP',
                  ),
                ],
                if (config != null && !anyGameRowOnGamesScreenVisible(config))
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        l.gamesNoGames,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required String reward,
    required IconData icon,
    required List<Color> colors,
    required GameStatusItem? status,
    required VoidCallback? onTap,
    required String gameType,
  }) {
    final canPlay = gameCanOpenOnGamesScreen(
      status,
      gameType,
      hasLaunchAction: onTap != null,
    );
    final playsLeft = _playsRemaining(status);
    final cooldownText = _getRemainingTime(status?.cooldownUntil);

    return Opacity(
      opacity: canPlay ? 1.0 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: canPlay ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canPlay
                    ? colors
                    : [Colors.grey.shade600, Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    if (status != null && status.maxGames != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '$playsLeft Left',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_events,
                                color: Colors.white, size: 28),
                            tooltip: "Leaderboard",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaderboardScreen(
                                    initialIndex: 2, // Games Tab
                                    initialGameType: gameType,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (reward.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: canPlay ? Colors.amber : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              reward,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (!canPlay && cooldownText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.timer,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Ready in $cooldownText',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (canPlay && onTap != null)
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 48,
                  )
                else if (!canPlay && onTap != null)
                  const Icon(
                    Icons.lock_clock,
                    color: Colors.white54,
                    size: 48,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
