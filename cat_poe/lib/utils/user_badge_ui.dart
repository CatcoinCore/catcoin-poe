import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cat_poe/l10n/app_localizations.dart';

import '../models/user_badge.dart';

IconData userBadgeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'weekly_top':
      return Icons.star;
    case 'monthly_top':
    case 'monthly_global_podium':
    case 'monthly_regional_podium':
      return Icons.emoji_events;
    case 'monthly_game_podium':
      return Icons.sports_esports;
    case 'all_time_top':
      return Icons.diamond;
    default:
      return Icons.verified;
  }
}

Color userBadgeColor(String type) {
  switch (type.toLowerCase()) {
    case 'weekly_top':
      return Colors.blue;
    case 'monthly_top':
      return Colors.purple;
    case 'monthly_global_podium':
      return const Color(0xFFFFD700);
    case 'monthly_regional_podium':
      return Colors.cyan.shade400;
    case 'monthly_game_podium':
      return Colors.deepOrangeAccent;
    case 'all_time_top':
      return Colors.amber;
    default:
      return Colors.green;
  }
}

String userBadgeTitle(AppLocalizations l, String type) {
  switch (type.toLowerCase()) {
    case 'weekly_top':
      return l.badgeWeeklyTop;
    case 'monthly_top':
      return l.badgeMonthlyTop;
    case 'monthly_global_podium':
      return l.badgeMonthlyGlobalPodium;
    case 'monthly_regional_podium':
      return l.badgeMonthlyRegionalPodium;
    case 'monthly_game_podium':
      return l.badgeMonthlyGamePodium;
    case 'all_time_top':
      return l.badgeAllTimeTop;
    default:
      if (type.contains('_')) {
        return type
            .split('_')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
      }
      return l.badgeVerified;
  }
}

String userGameTitle(AppLocalizations l, String gameType) {
  switch (gameType.toUpperCase()) {
    case 'RUNNER':
      return l.gamesRunnerTitle;
    case 'TICTACTOE':
      return l.gamesTictactoeTitle;
    case 'SUDOKU':
      return l.gamesSudokuTitle;
    case 'COLLAGE':
      return l.gamesCollageTitle;
    default:
      return gameType;
  }
}

String? _formattedAwardMonth(BuildContext context, UserBadge badge) {
  if (badge.periodYear == null || badge.periodMonth == null) return null;
  final locale = Localizations.localeOf(context).toString();
  try {
    return DateFormat.yMMMM(locale).format(DateTime(badge.periodYear!, badge.periodMonth!));
  } catch (_) {
    return DateFormat.yMMMM().format(DateTime(badge.periodYear!, badge.periodMonth!));
  }
}

/// Bottom sheet: month, award type, and how it was achieved (from server [description] when present).
void showUserBadgeDetailSheet(BuildContext context, UserBadge badge) {
  final l = AppLocalizations.of(context);
  final monthStr = _formattedAwardMonth(context, badge);
  final typeLabel = userBadgeTitle(l, badge.badgeType);
  final howText = (badge.description != null && badge.description!.trim().isNotEmpty)
      ? badge.description!
      : l.awardDetailHowFallback;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(userBadgeIcon(badge.badgeType), size: 40, color: userBadgeColor(badge.badgeType)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l.awardDetailTitle,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (monthStr != null) ...[
                  Text(l.awardDetailMonthLabel, style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(monthStr, style: Theme.of(ctx).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],
                Text(l.awardDetailTypeLabel, style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(typeLabel, style: Theme.of(ctx).textTheme.bodyLarge),
                if (badge.podiumRank != null && badge.awardScope != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.awardDetailRankScope(
                      badge.podiumRank!,
                      _scopeLabel(l, badge.awardScope!),
                    ),
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.secondary),
                  ),
                ],
                if (badge.regionCode != null && badge.regionCode!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l.awardDetailRegion(badge.regionCode!), style: Theme.of(ctx).textTheme.bodyMedium),
                ],
                if (badge.gameType != null && badge.gameType!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.awardDetailGame(userGameTitle(l, badge.gameType!)),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                Text(l.awardDetailHowLabel, style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(howText, style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(badge.awardedAt.toLocal()),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).hintColor),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l.awardDetailClose),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _scopeLabel(AppLocalizations l, String scope) {
  switch (scope.toUpperCase()) {
    case 'GLOBAL':
      return l.awardDetailScopeGlobal;
    case 'REGIONAL':
      return l.awardDetailScopeRegional;
    case 'GAME':
      return l.awardDetailScopeGame;
    default:
      return scope;
  }
}
