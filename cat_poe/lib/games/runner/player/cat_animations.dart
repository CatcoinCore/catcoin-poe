import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'cat_state_machine.dart';
import '../systems/asset_pack_service.dart';

/// Handles the visual representation (animations) for each CatState.
class CatAnimations {
  static Future<Map<CatState, SpriteAnimation>> loadAnimations(
    FlameGame game,
    AssetPackService assetService,
  ) async {
    final Map<CatState, SpriteAnimation> anims = {};

    Future<SpriteAnimation> loadAnim(String p, {double stepTime = 0.2}) async {
      final localPath = assetService.getAssetPath('game/$p');
      final file = File(localPath);
      
      Image img;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        img = await game.images.fromBase64(p, base64Encode(bytes));
      } else {
        // Fallback to bundled assets during development/migration
        img = await game.images.load('../game/$p');
      }

      final amount = (img.width / 256).floor();
      return SpriteAnimation.fromFrameData(
        img,
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2(256.0, 256.0),
        ),
      );
    }

    try {
      anims[CatState.run] = await loadAnim('new_cat_run.png', stepTime: 0.15);
      anims[CatState.idle] = await loadAnim('cat_idle.png', stepTime: 0.1);
      anims[CatState.jump] = await loadAnim('new_cat_run.png', stepTime: 0.08);
      anims[CatState.doubleJump] = await loadAnim('new_cat_run.png', stepTime: 0.08);
      anims[CatState.fall] = await loadAnim('new_cat_run.png', stepTime: 0.08);
      anims[CatState.land] = await loadAnim('new_cat_run.png', stepTime: 0.08);
      anims[CatState.turbo] = await loadAnim('cat_turbo.png', stepTime: 0.04);
      anims[CatState.damage] = await loadAnim('cat_damage.png', stepTime: 0.1);
      anims[CatState.victory] = await loadAnim('cat_victory.png', stepTime: 0.1);
    } catch (e) {
      debugPrint('Error loading game assets: $e');
    }
    
    return anims;
  }
}

