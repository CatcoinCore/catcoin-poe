import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _androidAdUnitIdController;
  late TextEditingController _iosAdUnitIdController;
  late TextEditingController _appAdsContentController;

  bool _adMiningStart = true;
  bool _adSpeedBoost = true;
  bool _adTimeBoost = true;
  bool _gameAdsEnabled = false;

  @override
  void initState() {
    super.initState();
    _androidAdUnitIdController = TextEditingController();
    _iosAdUnitIdController = TextEditingController();
    _appAdsContentController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  void _loadConfig() {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null) {
      _androidAdUnitIdController.text = config.androidAdUnitId ?? '';
      _iosAdUnitIdController.text = config.iosAdUnitId ?? '';
      _appAdsContentController.text = config.appAdsContent ?? '';

      setState(() {
        _adMiningStart = config.adRequiredForMiningStart;
        _adSpeedBoost = config.adRequiredForSpeedBoost;
        _adTimeBoost = config.adRequiredForTimeBoost;
        _gameAdsEnabled = config.gameAdsEnabled;
      });
    }
  }

  @override
  void dispose() {
    _androidAdUnitIdController.dispose();
    _iosAdUnitIdController.dispose();
    _appAdsContentController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final currentConfig = provider.config;
    if (currentConfig == null) return;

    final newConfig = currentConfig.copyWith(
      androidAdUnitId: _androidAdUnitIdController.text,
      iosAdUnitId: _iosAdUnitIdController.text,
      appAdsContent: _appAdsContentController.text,
      adRequiredForMiningStart: _adMiningStart,
      adRequiredForSpeedBoost: _adSpeedBoost,
      adRequiredForTimeBoost: _adTimeBoost,
      gameAdsEnabled: _gameAdsEnabled,
    );

    await provider.updateConfig(newConfig);

    if (mounted && provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ad settings updated!'),
            backgroundColor: Colors.green),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ads Configuration')),
      body: provider.isLoading && provider.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ad Requirements',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: const Text('Ad for Mining Start'),
                      value: _adMiningStart,
                      onChanged: (val) => setState(() => _adMiningStart = val),
                    ),
                    SwitchListTile(
                      title: const Text('Ad for Speed Boost'),
                      value: _adSpeedBoost,
                      onChanged: (val) => setState(() => _adSpeedBoost = val),
                    ),
                    SwitchListTile(
                      title: const Text('Ad for Time Boost'),
                      value: _adTimeBoost,
                      onChanged: (val) => setState(() => _adTimeBoost = val),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Game Ads'),
                      subtitle: const Text('Show ads during gameplay or game-over screens'),
                      value: _gameAdsEnabled,
                      onChanged: (val) => setState(() => _gameAdsEnabled = val),
                    ),
                    const SizedBox(height: 32),
                    const Text('Ad Unit IDs',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _androidAdUnitIdController,
                      decoration: const InputDecoration(
                        labelText: 'Android Ad Unit ID',
                        border: OutlineInputBorder(),
                        hintText: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iosAdUnitIdController,
                      decoration: const InputDecoration(
                        labelText: 'iOS Ad Unit ID',
                        border: OutlineInputBorder(),
                        hintText: 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy',
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('app-ads.txt Content',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _appAdsContentController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'app-ads.txt',
                        border: OutlineInputBorder(),
                        hintText: 'google.com, pub-xxxxxxxxxxxxxxxx, DIRECT',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('SAVE AD SETTINGS',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


