import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/runner_game.dart';

/// World theme enum â€” transitions by distance
enum WorldTheme { cryptoCity, neonBlockchain, miningCaverns, moonBase }

/// Theme data: sky gradient colors, ground colors, detail builders
class ThemeData {
  final List<Color> skyColors;
  final Color groundSurface;
  final Color groundDirt;
  final Color groundTuft;
  final Color mountainColor;

  const ThemeData({
    required this.skyColors,
    required this.groundSurface,
    required this.groundDirt,
    required this.groundTuft,
    required this.mountainColor,
  });
}

/// Theme definitions
const Map<WorldTheme, ThemeData> themeMap = {
  WorldTheme.cryptoCity: ThemeData(
    skyColors: [Color(0xFF0D1B2A), Color(0xFF1B3A4B), Color(0xFF2A5C6B)],
    groundSurface: Color(0xFF2E7D32),
    groundDirt: Color(0xFF5D4037),
    groundTuft: Color(0xFF43A047),
    mountainColor: Color(0xFF1A2332),
  ),
  WorldTheme.neonBlockchain: ThemeData(
    skyColors: [Color(0xFF1A0033), Color(0xFF4A148C), Color(0xFF7B1FA2)],
    groundSurface: Color(0xFF006064),
    groundDirt: Color(0xFF004D40),
    groundTuft: Color(0xFF00BCD4),
    mountainColor: Color(0xFF311B92),
  ),
  WorldTheme.miningCaverns: ThemeData(
    skyColors: [Color(0xFF1A1209), Color(0xFF3E2723), Color(0xFF1B1B1B)],
    groundSurface: Color(0xFF616161),
    groundDirt: Color(0xFF424242),
    groundTuft: Color(0xFF9E9E9E),
    mountainColor: Color(0xFF2C2C1A),
  ),
  WorldTheme.moonBase: ThemeData(
    skyColors: [Color(0xFF000011), Color(0xFF0D1B2A), Color(0xFF1A237E)],
    groundSurface: Color(0xFF9E9E9E),
    groundDirt: Color(0xFF757575),
    groundTuft: Color(0xFFBDBDBD),
    mountainColor: Color(0xFF1A1A2E),
  ),
};

/// Determines the world theme based on distance in meters
WorldTheme themeForDistance(int distanceMeters) {
  if (distanceMeters < 500) return WorldTheme.cryptoCity;
  if (distanceMeters < 1500) return WorldTheme.neonBlockchain;
  if (distanceMeters < 2500) return WorldTheme.miningCaverns;
  return WorldTheme.moonBase;
}

/// Multi-layer parallax background that transitions between world themes.
class GameBackground extends PositionComponent with HasGameReference<RunnerGame> {
  WorldTheme _currentTheme = WorldTheme.cryptoCity;
  late RectangleComponent _skyRect;
  final List<PositionComponent> _details = [];
  final List<PositionComponent> _stars = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final td = themeMap[_currentTheme]!;

    // Sky gradient
    _skyRect = RectangleComponent(
      size: Vector2(RunnerGame.worldWidth, RunnerGame.worldHeight),
      position: Vector2.zero(),
      paint: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: td.skyColors,
        ).createShader(Rect.fromLTWH(0, 0, RunnerGame.worldWidth, RunnerGame.worldHeight)),
    );
    add(_skyRect);

    // Stars (always visible, brighter in later themes)
    for (int i = 0; i < 50; i++) {
      final x = (i * 37.7) % RunnerGame.worldWidth;
      final y = (i * 23.3) % (RunnerGame.worldHeight * 0.5);
      final r = (i % 3 == 0) ? 1.5 : 1.0;
      final star = CircleComponent(
        radius: r,
        position: Vector2(x, y),
        paint: Paint()..color = Colors.white.withValues(alpha: 0.2 + (i % 5) * 0.08),
      );
      add(star);
      _stars.add(star);
    }

    // Build initial theme details
    _buildThemeDetails(td);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final newTheme = themeForDistance(game.economyManager.distanceMeters);
    if (newTheme != _currentTheme) {
      _transitionTo(newTheme);
    }
    
    // Parallax scrolling
    final speed = game.scrollSpeed;
    
    for (final star in _stars) {
      star.position.x -= speed * 0.05 * dt;
      if (star.position.x + star.size.x < 0) {
        star.position.x += RunnerGame.worldWidth;
      }
    }
    
    for (final detail in _details) {
      detail.position.x -= speed * 0.2 * dt;
      if (detail.position.x + detail.size.x < 0) {
        detail.position.x += RunnerGame.worldWidth + 100; // Adding buffer to prevent popping
      }
    }
  }

  void _transitionTo(WorldTheme newTheme) {
    _currentTheme = newTheme;
    final td = themeMap[newTheme]!;

    // Update sky gradient
    _skyRect.paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: td.skyColors,
      ).createShader(Rect.fromLTWH(0, 0, RunnerGame.worldWidth, RunnerGame.worldHeight));

    // Remove old details & rebuild
    for (final d in _details) {
      d.removeFromParent();
    }
    _details.clear();
    _buildThemeDetails(td);
  }

  void _buildThemeDetails(ThemeData td) {
    switch (_currentTheme) {
      case WorldTheme.cryptoCity:
        _addBuildings(td);
        break;
      case WorldTheme.neonBlockchain:
        _addCircuitPatterns(td);
        break;
      case WorldTheme.miningCaverns:
        _addCaveDetails(td);
        break;
      case WorldTheme.moonBase:
        _addMoonDetails(td);
        break;
    }
  }

  void _addBuildings(ThemeData td) {
    // Crypto city skyline â€” neon-outlined buildings
    final buildings = [
      [60.0, 200.0, 50.0, 170.0],
      [150.0, 230.0, 70.0, 140.0],
      [280.0, 180.0, 45.0, 190.0],
      [380.0, 250.0, 60.0, 120.0],
      [500.0, 210.0, 55.0, 160.0],
      [620.0, 240.0, 65.0, 130.0],
      [730.0, 190.0, 50.0, 180.0],
    ];
    for (final b in buildings) {
      final bldg = RectangleComponent(
        size: Vector2(b[2], b[3]),
        position: Vector2(b[0], b[1]),
        paint: Paint()..color = td.mountainColor.withValues(alpha: 0.6),
      );
      add(bldg);
      _details.add(bldg);

      // Window lights
      for (double wy = 8; wy < b[3] - 10; wy += 18) {
        for (double wx = 6; wx < b[2] - 6; wx += 14) {
          final win = RectangleComponent(
            size: Vector2(4, 5),
            position: Vector2(b[0] + wx, b[1] + wy),
            paint: Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.4),
          );
          add(win);
          _details.add(win);
        }
      }
    }
  }

  void _addCircuitPatterns(ThemeData td) {
    // Neon hex blocks
    for (int i = 0; i < 8; i++) {
      final x = (i * 107.0) % RunnerGame.worldWidth;
      final y = 180.0 + (i * 31) % 120;
      final block = RectangleComponent(
        size: Vector2(30 + (i % 3) * 15.0, 25 + (i % 2) * 20.0),
        position: Vector2(x, y),
        paint: Paint()..color = const Color(0xFF7C4DFF).withValues(alpha: 0.3),
      );
      add(block);
      _details.add(block);

      // Neon outline glow
      final glow = RectangleComponent(
        size: Vector2(34 + (i % 3) * 15.0, 29 + (i % 2) * 20.0),
        position: Vector2(x - 2, y - 2),
        paint: Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.15),
      );
      add(glow);
      _details.add(glow);
    }

    // Circuit lines
    for (int i = 0; i < 12; i++) {
      final line = RectangleComponent(
        size: Vector2(60 + (i * 17) % 40, 2),
        position: Vector2((i * 73.0) % RunnerGame.worldWidth, 280 + (i * 13) % 80),
        paint: Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.2),
      );
      add(line);
      _details.add(line);
    }
  }

  void _addCaveDetails(ThemeData td) {
    // Stalactites hanging from top
    for (int i = 0; i < 10; i++) {
      final x = (i * 83.0) % RunnerGame.worldWidth;
      final h = 30.0 + (i * 17) % 50;
      final stal = RectangleComponent(
        size: Vector2(8 + (i % 3) * 4.0, h),
        position: Vector2(x, 0),
        paint: Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.6),
      );
      add(stal);
      _details.add(stal);
    }

    // Gem crystals
    for (int i = 0; i < 6; i++) {
      final colors = [
        const Color(0xFF4CAF50), const Color(0xFF2196F3),
        const Color(0xFFE91E63), const Color(0xFFFF9800),
        const Color(0xFF9C27B0), const Color(0xFF00BCD4),
      ];
      final crystal = RectangleComponent(
        size: Vector2(6, 12),
        position: Vector2((i * 137.0) % RunnerGame.worldWidth, 260 + (i * 29) % 60),
        paint: Paint()..color = colors[i].withValues(alpha: 0.5),
      );
      add(crystal);
      _details.add(crystal);
    }
  }

  void _addMoonDetails(ThemeData td) {
    // Craters
    for (int i = 0; i < 6; i++) {
      final crater = CircleComponent(
        radius: 12 + (i * 7) % 15,
        position: Vector2((i * 143.0) % RunnerGame.worldWidth, 300 + (i * 23) % 60),
        paint: Paint()..color = const Color(0xFF616161).withValues(alpha: 0.3),
      );
      add(crater);
      _details.add(crater);
    }

    // Earth in the distance
    final earth = CircleComponent(
      radius: 20,
      position: Vector2(650, 60),
      paint: Paint()..color = const Color(0xFF2196F3).withValues(alpha: 0.6),
    );
    add(earth);
    _details.add(earth);

    // Earth continent
    final continent = RectangleComponent(
      size: Vector2(14, 10),
      position: Vector2(646, 55),
      paint: Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.5),
    );
    add(continent);
    _details.add(continent);
  }
}


