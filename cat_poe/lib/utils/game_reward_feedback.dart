import 'package:flutter/material.dart';

import 'package:cat_poe/l10n/app_localizations.dart';

import '../providers/game_provider.dart';

String formatBoostPercent(double p) {
  if (p == p.roundToDouble()) return p.toInt().toString();
  return p.toStringAsFixed(1);
}

/// Optional block describing an inventory game boost (earned after /game/submit).
List<Widget> gameBoostBonusSection(
  BuildContext context,
  AppLocalizations l10n,
  GameBoostAward boost,
) {
  final h = boost.durationMinutes ~/ 60;
  final m = boost.durationMinutes % 60;
  final scheme = Theme.of(context).colorScheme;
  final secondary = scheme.onSurfaceVariant;
  return [
    const SizedBox(height: 16),
    const Divider(),
    const SizedBox(height: 8),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bolt, color: Colors.amber.shade600, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.gameRewardBoostBonusTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.boostersGameBoostTitle(formatBoostPercent(boost.percentage)),
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.boostersGameBoostDuration(h.toString(), m.toString()),
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gameRewardBoostBonusBody(
                  formatBoostPercent(boost.percentage),
                  '${boost.durationMinutes}',
                ),
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ];
}
