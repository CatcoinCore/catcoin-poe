import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import '../game/runner_game.dart';

/// Game Over overlay — shows results and submit/play-again actions.
class GameOverOverlay extends StatelessWidget {
  final RunnerGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final eco = game.economyManager;
    final l = AppLocalizations.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF9800), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.gameGameOverTitle,
                style: const TextStyle(
                  color: Color(0xFFFF5722),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),

              // Stats grid
              _StatRow(label: l.gameStatScore, value: '${eco.score}', icon: Icons.star),
              const SizedBox(height: 8),
              _StatRow(label: l.gameStatDistance, value: '${eco.distanceMeters}m', icon: Icons.straighten),
              const SizedBox(height: 8),
              _StatRow(label: l.gameStatCoins, value: '${eco.coinsCollected}', icon: Icons.monetization_on),
              const Divider(color: Colors.white24, height: 24),
              _StatRow(
                label: l.gameStatCatoshiEarned,
                value: '${eco.catoshiEarned}',
                icon: Icons.currency_bitcoin,
                highlight: true,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPlayAgain,
                      icon: const Icon(Icons.replay),
                      label: Text(l.gamePlayAgain),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onExit,
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(l.gameExit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFFFD700) : Colors.white70;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


