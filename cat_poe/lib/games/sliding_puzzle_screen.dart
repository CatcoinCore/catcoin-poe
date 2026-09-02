import 'dart:async';

import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/game_provider.dart';
import '../providers/mining_provider.dart';
import '../utils/game_screen_capture_guard.dart';
import '../utils/game_reward_feedback.dart';
import '../utils/game_session_gate.dart';
import '../games/runner/systems/asset_pack_service.dart';
import '../services/ad_service.dart';
import '../services/game_sfx_service.dart';
import 'collage_resume_storage.dart';

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen>
    with GameScreenCaptureGuard {
  static const int size = 4; // 4x4 grid
  late List<int> tiles;
  int emptyIndex = 15;
  bool isGameOver = false;
  bool isSubmitting = false;
  bool _collageWinBusy = false;
  bool isScrambled = false;
  bool _rewardSubmitted = false;
  ui.Image? _image;
  int _imageIndex = 1;
  bool _isCheckingAssets = true;

  @override
  void dispose() {
    unawaited(_persistCollage());
    super.dispose();
  }

  CollageSavedGame _captureCollageSavedGame() {
    return CollageSavedGame(
      schemaVersion: CollageSavedGame.currentSchema,
      tiles: List<int>.from(tiles),
      emptyIndex: emptyIndex,
      isGameOver: isGameOver,
      isScrambled: isScrambled,
      imageIndex: _imageIndex,
      rewardSubmitted: _rewardSubmitted,
    );
  }

  Future<void> _persistCollage() async {
    try {
      await CollageGameStorage.save(_captureCollageSavedGame());
    } catch (_) {}
  }

  void _schedulePersistCollage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_persistCollage());
    });
  }

  Future<void> _confirmExitCollage() async {
    await _persistCollage();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.gameCollageExitTitle),
        content: Text(l.gameCollageExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.gameTwenty48Stay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.gameTwenty48Leave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _bootstrapCollageAfterAssetsReady() async {
    CollageSavedGame? restored = await CollageGameStorage.load();
    if (!mounted) return;
    if (restored != null && restored.validate()) {
      setState(() {
        tiles = List.from(restored.tiles);
        emptyIndex = restored.emptyIndex;
        isGameOver = restored.isGameOver;
        isScrambled = restored.isScrambled;
        _imageIndex = restored.imageIndex;
        _rewardSubmitted = restored.rewardSubmitted;
      });
    } else if (restored != null) {
      await CollageGameStorage.clear();
    }
    await _loadImage();
    if (!mounted) return;
    final ok = restored != null && restored.validate();
    if (ok && isScrambled) {
      await _startSession();
    }
    if (mounted &&
        ok &&
        isGameOver &&
        _checkWin() &&
        !_rewardSubmitted &&
        isScrambled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_completeCollageWin());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _imageIndex = Random().nextInt(10) + 1;
    _resetTiles();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAssets());
  }

  Future<void> _checkAssets() async {
    final assetService = Provider.of<MiniGameAssetService>(context, listen: false);
    await assetService.checkAssets();
    if (assetService.isReady) {
      await _bootstrapCollageAfterAssetsReady();
    }
    if (mounted) {
      AdService().loadInterstitialAd(context);
      setState(() {
        _isCheckingAssets = false;
      });
    }
  }

  void _resetTiles() {
    tiles = List.generate(size * size, (index) => index);
    emptyIndex = 15;
    isGameOver = false;
    isScrambled = false;
    _rewardSubmitted = false;
  }

  Future<void> _loadImage() async {
    final assetService = Provider.of<MiniGameAssetService>(context, listen: false);
    final String localPath = assetService.getAssetPath('cat_$_imageIndex.png');
    final File file = File(localPath);
    
    if (!await file.exists()) {
      debugPrint('Asset not found at: $localPath');
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    
    if (mounted) {
      setState(() {
        _image = fi.image;
      });
    }
  }

  Future<void> _scramble() async {
    if (!await ensureGamePlayAllowed(context, gameType: 'COLLAGE')) return;
    final random = Random();
    for (int i = tiles.length - 2; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = tiles[i];
      tiles[i] = tiles[j];
      tiles[j] = temp;
    }

    emptyIndex = tiles.indexOf(15);
    setState(() {
      isScrambled = true;
      isGameOver = false;
    });
    await _startSession();
    _schedulePersistCollage();
  }

  Future<void> _startSession() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.startSession();
  }

  void _moveTile(int index) {
    if (isGameOver || !isScrambled) return;

    int row = index ~/ size;
    int col = index % size;
    int emptyRow = emptyIndex ~/ size;
    int emptyCol = emptyIndex % size;

    if ((row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1)) {
      var won = false;
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 15;
        emptyIndex = index;

        if (_checkWin()) {
          isGameOver = true;
          won = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_completeCollageWin());
          });
        }
      });
      GameSfxService.instance.play(GameSfx.slide, volume: 0.42);
      if (won) {
        GameSfxService.instance.play(GameSfx.win, volume: 0.74);
      }
      _schedulePersistCollage();
    }
  }

  bool _checkWin() {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != i) return false;
    }
    return true;
  }

  Future<void> _completeCollageWin() async {
    if (_collageWinBusy) return;
    _collageWinBusy = true;
    try {
      await AdService().showRewardGateAd(context, gameType: 'COLLAGE');
      if (!mounted) return;
      await _submitResult();
    } finally {
      _collageWinBusy = false;
    }
  }

  void _showCollageRewardDialog(int catoshi, GameBoostAward? boost) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
        title: Text(l10n.gameYouWin, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.gamePuzzleSuccess(catoshi.toString()),
                textAlign: TextAlign.center,
              ),
              if (boost != null) ...gameBoostBonusSection(ctx, l10n, boost),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResult() async {
    setState(() {
      isSubmitting = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final success = await gameProvider.submitScore(
      score: 1,
      coinsCollected: 50,
      gameType: "COLLAGE",
    );

    if (success && mounted) {
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
      setState(() {
        _rewardSubmitted = true;
      });
      _schedulePersistCollage();
      final reward = gameProvider.lastReward ?? 50;
      final boost = gameProvider.lastGameBoostAward;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCollageRewardDialog(reward, boost);
      });
    } else if (mounted && gameProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gameProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExitCollage());
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l.gamesCollageTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<MiniGameAssetService>(
          builder: (context, assetService, child) {
            if (_isCheckingAssets || assetService.isDownloading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.orange),
                    const SizedBox(height: 20),
                    Text(
                      assetService.isDownloading ? "Downloading game images..." : l.commonLoading,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                    ),
                    if (assetService.isDownloading)
                       Padding(
                         padding: const EdgeInsets.all(20.0),
                         child: LinearProgressIndicator(value: assetService.progress, color: Colors.orange),
                       ),
                  ],
                ),
              );
            }

            if (!assetService.isReady) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_for_offline, color: Colors.orange, size: 60),
                    const SizedBox(height: 20),
                    Text("Game images are required to play.", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text("Download size: ${assetService.totalSizeDisplay}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        await assetService.downloadAssets();
                        if (assetService.isReady) {
                          await _bootstrapCollageAfterAssetsReady();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: const Text("Download & Start"),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)],
                    ),
                    child: Text(
                      l.gameWinReward('50'),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      isScrambled ? l.gamesCollageDesc : "Study the image, then click Start to scramble!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (_image == null)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ))
                  else
                    _buildPuzzleGrid(),
                  const SizedBox(height: 20),
                  if (isScrambled && _image != null)
                    _buildOriginalImagePreview(l),
                  const SizedBox(height: 40),
                  if (!isScrambled && !isGameOver)
                    ElevatedButton.icon(
                      onPressed: _scramble,
                      icon: const Icon(Icons.shuffle),
                      label: const Text("Scramble & Start", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  if (isGameOver)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageIndex = Random().nextInt(10) + 1;
                          _image = null;
                          _resetTiles();
                          _loadImage();
                        });
                        _schedulePersistCollage();
                      },
                      icon: const Icon(Icons.replay),
                      label: Text(l.gamePlayAgain, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  if (isSubmitting)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOriginalImagePreview(AppLocalizations l) {
    return Column(
      children: [
        Text(
          "Reference Image",
          style: TextStyle(color: Colors.white70.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: RawImage(
              image: _image,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleGrid() {
    return Container(
      width: 320,
      height: 320,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: GridView.builder(
        itemCount: 16,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          int tileValue = tiles[index];
          // Hide empty slot only when scrambled
          if (isScrambled && tileValue == 15) return Container(); 

          return GestureDetector(
            onTap: () => _moveTile(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: TilePainter(_image!, tileValue, size),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TilePainter extends CustomPainter {
  final ui.Image image;
  final int tileValue;
  final int size;

  TilePainter(this.image, this.tileValue, this.size);

  @override
  void paint(Canvas canvas, Size paintSize) {
    int row = tileValue ~/ size;
    int col = tileValue % size;

    double tileWidth = image.width / size;
    double tileHeight = image.height / size;

    Rect src = Rect.fromLTWH(col * tileWidth, row * tileHeight, tileWidth, tileHeight);
    Rect dst = Rect.fromLTWH(0, 0, paintSize.width, paintSize.height);

    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.tileValue != tileValue;
  }
}
