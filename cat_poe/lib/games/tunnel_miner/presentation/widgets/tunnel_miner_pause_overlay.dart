import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TunnelMinerPauseOverlay extends StatelessWidget {
  const TunnelMinerPauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            color: const Color(0xFF1A1A2E),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.gamePausedTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onResume,
                    child: Text(l.gameResume),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onQuit,
                    child: Text(l.gameQuit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
