import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../utils/game_screen_capture_guard.dart';
import '../systems/asset_pack_service.dart';
import 'game_screen.dart';

/// Pre-game screen that ensures all game assets are downloaded before launching
/// the main Flame engine. Matches the Blueprint "on-demand downloadable module" requirement.
class GameLauncherScreen extends StatefulWidget {
  const GameLauncherScreen({super.key});

  @override
  State<GameLauncherScreen> createState() => _GameLauncherScreenState();
}

class _GameLauncherScreenState extends State<GameLauncherScreen>
    with GameScreenCaptureGuard {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndDownload();
    });
  }

  Future<void> _checkAndDownload() async {
    final assetService = Provider.of<RunnerAssetService>(context, listen: false);
    await assetService.checkAssets();
    
    if (!assetService.isReady) {
      await assetService.downloadAssets();
    }
    
    // Once ready, just refresh UI to show start button.
    // We removed auto-navigation here in favor of a manual Start button.
    if (mounted && assetService.isReady) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Match game background
      body: Center(
        child: Consumer<RunnerAssetService>(
          builder: (context, assetService, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CatCoin Logo or Mascot Placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.pets, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  l.gameLauncherTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  assetService.isDownloading 
                    ? l.gameLauncherDownloading 
                    : (assetService.isReady ? l.gameLauncherReady : l.gameLauncherRequired),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (assetService.isDownloading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: assetService.progress,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFFFF9800),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(assetService.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ] else if (!assetService.isReady) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () => assetService.downloadAssets(),
                    icon: const Icon(Icons.download),
                    label: Text(l.gameLauncherDownloadBtn(assetService.totalSizeDisplay)),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    child: Text(l.gameLauncherStartBtn, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => assetService.clearLocalAssets(),
                    child: Text(l.gameLauncherResetBtn, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

