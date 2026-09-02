import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';

/// Re-fetch status and block opening a game when the server says it is not playable.
Future<bool> ensureGamePlayAllowed(
  BuildContext context, {
  required String gameType,
}) async {
  final gp = Provider.of<GameProvider>(context, listen: false);
  await gp.fetchStatus();
  if (!context.mounted) return false;
  final st = gp.statusMap[gameType];
  if (gameType == 'MINER' && st == null) {
    return true;
  }
  if (gameType == 'TILE_SWAP' && st == null) {
    return true;
  }
  if (st == null || !st.canPlay) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            st == null
                ? 'Could not verify game limits. Check your connection and try again.'
                : 'Play limit reached or cooldown active. Try again later.',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
    return false;
  }
  return true;
}
