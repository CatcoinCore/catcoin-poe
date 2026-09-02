import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/api_locale.dart';

class AdminGamesScreen extends StatefulWidget {
  const AdminGamesScreen({super.key});

  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
  final Map<String, TextEditingController> _rewardControllers = {};
  final Map<String, TextEditingController> _maxGamesControllers = {};
  final Map<String, TextEditingController> _cooldownControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchConfig(
            languageCode: apiLanguageCodeFromContext(context));
    });
  }

  @override
  void dispose() {
    for (var c in _rewardControllers.values) {
      c.dispose();
    }
    for (var c in _maxGamesControllers.values) {
      c.dispose();
    }
    for (var c in _cooldownControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(String jsonStr) {
    try {
      final Map<String, dynamic> config = json.decode(jsonStr);
      for (var gameType in config.keys) {
        final gameData = config[gameType];
        if (gameData is Map) {
          _rewardControllers.putIfAbsent(
              gameType,
              () => TextEditingController(
                  text: gameData['reward']?.toString() ?? ''));
          _maxGamesControllers.putIfAbsent(
              gameType,
              () => TextEditingController(
                  text: gameData['max_games']?.toString() ?? ''));
          _cooldownControllers.putIfAbsent(
              gameType,
              () => TextEditingController(
                  text: gameData['cooldown_hours']?.toString() ?? ''));
        }
      }
    } catch (e) {
      // Ignore parse errors for controllers
    }
  }

  Future<void> _saveRewards(AdminProvider provider) async {
    final config = provider.config;
    if (config == null) return;

    try {
      final Map<String, dynamic> rewardMap = json.decode(config.gameRewardConfig);
      for (var gameType in rewardMap.keys) {
        if (_rewardControllers.containsKey(gameType)) {
          rewardMap[gameType]['reward'] =
              int.tryParse(_rewardControllers[gameType]!.text);
          rewardMap[gameType]['max_games'] =
              int.tryParse(_maxGamesControllers[gameType]!.text);
          rewardMap[gameType]['cooldown_hours'] =
              int.tryParse(_cooldownControllers[gameType]!.text);
        }
      }

      final newJson = json.encode(rewardMap);
      await provider.updateConfig(config.copyWith(gameRewardConfig: newJson));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game rewards updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update rewards: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Management')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.config == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final config = provider.config;
          if (config == null) {
            return const Center(child: Text('Failed to load configuration'));
          }

          _initializeControllers(config.gameRewardConfig);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Visibility Toggles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Cat Runner'),
                value: config.isRunnerGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isRunnerGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('CatCoin Miner'),
                value: config.isMinerGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isMinerGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('Tic Tac Toe'),
                value: config.isTictactoeGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isTictactoeGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('Sudoku'),
                value: config.isSudokuGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isSudokuGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('Image Collage'),
                value: config.isCollageGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isCollageGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('Arrow Game'),
                value: config.isArrowGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isArrowGameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('2048'),
                value: config.isTwenty48GameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isTwenty48GameVisible: val));
                },
              ),
              SwitchListTile(
                title: const Text('Tile Swap'),
                value: config.isTileSwapGameVisible,
                onChanged: (val) {
                  provider.updateConfig(
                      config.copyWith(isTileSwapGameVisible: val));
                },
              ),
              const Divider(height: 32),
              const Text(
                'Rewards & Limits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._rewardControllers.keys.map((game) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rewardControllers[game],
                                decoration: const InputDecoration(
                                    labelText: 'Reward',
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _maxGamesControllers[game],
                                decoration: const InputDecoration(
                                    labelText: 'Max Games',
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _cooldownControllers[game],
                                decoration: const InputDecoration(
                                    labelText: 'Cooldown (h)',
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ElevatedButton(
                onPressed: provider.isLoading ? null : () => _saveRewards(provider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Rewards Configuration'),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

