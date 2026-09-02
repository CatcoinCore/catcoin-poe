import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../data/tunnel_miner_models.dart';
import '../../game/catcoin_tunnel_miner_game.dart';

class TunnelMinerHud extends StatelessWidget {
  const TunnelMinerHud({
    super.key,
    required this.game,
    required this.onPause,
  });

  final CatcoinTunnelMinerGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: game.hudRevision,
      builder: (context, _, __) {
        final s = game.mine.stats;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HudChip(
                        icon: Icons.vertical_align_bottom,
                        label: l.tunnelMinerHudDepth,
                        value: '${s.maxDepth}',
                      ),
                    ),
                    Expanded(
                      child: _HudChip(
                        icon: Icons.bolt,
                        label: l.tunnelMinerHudEnergy,
                        value: '${s.energy}/${s.energyMax}',
                      ),
                    ),
                    Expanded(
                      child: _HudChip(
                        icon: Icons.monetization_on,
                        label: l.tunnelMinerHudShards,
                        value: '${s.shards}',
                      ),
                    ),
                    IconButton(
                      onPressed: onPause,
                      icon:
                          const Icon(Icons.pause_circle_filled, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _HudChip(
                        icon: Icons.star,
                        label: l.gameStatScore,
                        value: '${s.score}',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: Icons.arrow_back,
                      onPressed: game.mine.phase == TunnelRunPhase.playing
                          ? game.mine.tryMoveLeft
                          : null,
                    ),
                    _ControlButton(
                      icon: Icons.arrow_downward,
                      label: l.tunnelMinerDigHint,
                      onPressed: game.mine.phase == TunnelRunPhase.playing
                          ? game.mine.tryDig
                          : null,
                    ),
                    _ControlButton(
                      icon: Icons.arrow_forward,
                      onPressed: game.mine.phase == TunnelRunPhase.playing
                          ? game.mine.tryMoveRight
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.amber.shade200),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              if (label != null)
                Text(
                  label!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
