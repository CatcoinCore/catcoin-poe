import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../data/tunnel_miner_models.dart';
import '../../game/catcoin_tunnel_miner_game.dart';

class TunnelMinerResultOverlay extends StatefulWidget {
  const TunnelMinerResultOverlay({
    super.key,
    required this.game,
    required this.onPlayAgain,
    required this.onExit,
  });

  final CatcoinTunnelMinerGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  State<TunnelMinerResultOverlay> createState() =>
      _TunnelMinerResultOverlayState();
}

class _TunnelMinerResultOverlayState extends State<TunnelMinerResultOverlay> {
  bool _mapReview = false;

  @override
  Widget build(BuildContext context) {
    if (_mapReview) {
      return _buildMapReview(context);
    }
    return _buildSummary(context);
  }

  Widget _buildSummary(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.game.mine.stats;
    final title = s.extracted
        ? l.tunnelMinerResultExtracted
        : l.gameGameOverTitle;
    final canReviewMap = !s.extracted;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.52),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: s.extracted ? Colors.greenAccent : const Color(0xFFFF9800),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      s.extracted ? Colors.greenAccent : const Color(0xFFFF5722),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _StatRow(
                label: l.gameStatScore,
                value: '${s.score}',
                icon: Icons.star,
              ),
              const SizedBox(height: 6),
              _StatRow(
                label: l.tunnelMinerHudDepth,
                value: '${s.maxDepth}',
                icon: Icons.vertical_align_bottom,
              ),
              const SizedBox(height: 6),
              _StatRow(
                label: l.tunnelMinerHudShards,
                value: '${s.shards}',
                icon: Icons.monetization_on,
              ),
              const SizedBox(height: 6),
              _StatRow(
                label: l.tunnelMinerResultReason,
                value: _reasonLabel(l, s.reason),
                icon: Icons.flag,
              ),
              if (canReviewMap) ...[
                const SizedBox(height: 12),
                Text(
                  l.tunnelMinerWhatHappened,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lossExplanation(l, s),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              if (canReviewMap)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _mapReview = true),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l.tunnelMinerReviewMap),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ),
              if (canReviewMap) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onPlayAgain,
                      icon: const Icon(Icons.replay),
                      label: Text(l.gamePlayAgain),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onExit,
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(l.gameExit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
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

  Widget _buildMapReview(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.game.mine.stats;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Material(
                color: const Color(0xEE1A1A2E),
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.tunnelMinerWhatHappened,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lossExplanation(l, s),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.tunnelMinerMapReviewHint,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => setState(() => _mapReview = false),
                        icon: const Icon(Icons.summarize_outlined),
                        label: Text(l.tunnelMinerBackToSummary),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _lossExplanation(AppLocalizations l, TunnelMinerRunStats s) {
    if (s.extracted) {
      return '';
    }
    switch (s.lossDetail) {
      case TunnelLossDetail.lava:
        return l.tunnelMinerLossExplainLava;
      case TunnelLossDetail.boulder:
        return l.tunnelMinerLossExplainBoulder;
      case TunnelLossDetail.energy:
        return l.tunnelMinerLossExplainEnergy;
      case TunnelLossDetail.none:
        return l.tunnelMinerLossExplainUnknown;
    }
  }

  String _reasonLabel(AppLocalizations l, TunnelEndReason r) {
    switch (r) {
      case TunnelEndReason.energy:
        return l.tunnelMinerReasonEnergy;
      case TunnelEndReason.hazard:
        return l.tunnelMinerReasonHazard;
      case TunnelEndReason.extracted:
        return l.tunnelMinerReasonExtracted;
      case TunnelEndReason.none:
        return '—';
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
