import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../game/catcoin_tunnel_miner_game.dart';

class TunnelMinerIntroOverlay extends StatelessWidget {
  const TunnelMinerIntroOverlay({
    super.key,
    required this.game,
  });

  final CatcoinTunnelMinerGame game;

  static const _accent = Color(0xFFFF9800);
  static const _cardBg = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.landscape, color: _accent, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.tunnelMinerIntroTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.gamesTunnelMinerDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: l.tunnelMinerHowToPlayTitle,
                      child: Text(
                        l.tunnelMinerGoal,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.tunnelMinerDoHeading,
                      accent: Colors.green.shade700,
                      child: Text(
                        l.tunnelMinerDoBody,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.tunnelMinerDontHeading,
                      accent: Colors.red.shade700,
                      child: Text(
                        l.tunnelMinerDontBody,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l.tunnelMinerControlsHeading,
                      accent: Colors.blue.shade700,
                      child: Text(
                        l.tunnelMinerControlsBody,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.tunnelMinerIntroTap,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: game.notifyIntroDismissed,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(l.tunnelMinerStartButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.accent = const Color(0xFFFF9800),
  });

  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TunnelMinerIntroOverlay._cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent.withValues(alpha: 1),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
