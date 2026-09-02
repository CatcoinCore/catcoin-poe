import 'package:flutter/material.dart';
import '../game/runner_game.dart';

/// HUD overlay â€” shows coins, score, distance, and active powerup status.
class GameHud extends StatelessWidget {
  final RunnerGame game;
  final VoidCallback onPause;

  const GameHud({super.key, required this.game, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _GameTicker(game),
      builder: (context, _) {
        final eco = game.economyManager;
        final pwr = game.powerupSystem;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar: coins/score, distance, pause
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Coins + Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '${eco.coinsCollected}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score: ${eco.score}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),

                    // Center: Distance
                    Text(
                      '${eco.distanceMeters}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),

                    // Right: Pause button
                    IconButton(
                      onPressed: onPause,
                      icon: const Icon(Icons.pause_circle_filled, color: Colors.white70, size: 32),
                    ),
                  ],
                ),

                // Turbo Meter
                if (!pwr.isTurboActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFF00E5FF), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pwr.turboMeter,
                            backgroundColor: Colors.white24,
                            color: pwr.canActivateTurbo ? Colors.yellow : const Color(0xFF00E5FF), // Cyan, turns yellow when full
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pwr.turboMeter * 100).toInt()}%',
                        style: TextStyle(
                          color: pwr.canActivateTurbo ? Colors.yellow : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Manual Turbo Activation Button
                if (pwr.canActivateTurbo) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      pwr.activateTurbo();
                    },
                    icon: const Icon(Icons.bolt, color: Colors.black, size: 24),
                    label: const Text(
                      'ACTIVATE TURBO!',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      elevation: 8,
                      shadowColor: Colors.yellowAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],

                // Active powerups bar
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (pwr.isTurboActive)
                      _PowerupBadge(
                        icon: Icons.flash_on,
                        label: 'TURBO ${pwr.turboRemaining.toStringAsFixed(1)}s',
                        color: const Color(0xFF00E5FF),
                      ),
                    if (pwr.isMagnetActive) ...[
                      if (pwr.isTurboActive) const SizedBox(width: 8),
                      _PowerupBadge(
                        icon: Icons.attractions,
                        label: 'MAGNET ${pwr.magnetRemaining.toStringAsFixed(1)}s',
                        color: const Color(0xFFFFD600),
                      ),
                    ],
                    if (pwr.hasShield) ...[
                      if (pwr.isTurboActive || pwr.isMagnetActive) const SizedBox(width: 8),
                      const _PowerupBadge(
                        icon: Icons.shield,
                        label: 'SHIELD',
                        color: Color(0xFF42A5F5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small badge showing an active powerup with icon, label, and color.
class _PowerupBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PowerupBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A Listenable that ticks with the game loop for HUD updates.
class _GameTicker extends ChangeNotifier {
  final RunnerGame game;
  _GameTicker(this.game) {
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
      if (game.state == GameState.playing) {
        _tick();
      }
    });
  }
}


