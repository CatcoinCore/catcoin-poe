import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminVersionControlScreen extends StatefulWidget {
  const AdminVersionControlScreen({super.key});

  @override
  State<AdminVersionControlScreen> createState() =>
      _AdminVersionControlScreenState();
}

class _AdminVersionControlScreenState extends State<AdminVersionControlScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _latestVersionAndroidController;
  late TextEditingController _minVersionAndroidController;
  late TextEditingController _updateUrlAndroidController;

  late TextEditingController _latestVersionIOSController;
  late TextEditingController _minVersionIOSController;
  late TextEditingController _updateUrlIOSController;

  late TextEditingController _latestVersionWindowsController;
  late TextEditingController _minVersionWindowsController;
  late TextEditingController _updateUrlWindowsController;

  @override
  void initState() {
    super.initState();
    _latestVersionAndroidController = TextEditingController();
    _minVersionAndroidController = TextEditingController();
    _updateUrlAndroidController = TextEditingController();

    _latestVersionIOSController = TextEditingController();
    _minVersionIOSController = TextEditingController();
    _updateUrlIOSController = TextEditingController();

    _latestVersionWindowsController = TextEditingController();
    _minVersionWindowsController = TextEditingController();
    _updateUrlWindowsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  void _loadConfig() {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null) {
      _latestVersionAndroidController.text = config.latestVersionAndroid;
      _minVersionAndroidController.text = config.minVersionAndroid;
      _updateUrlAndroidController.text = config.updateUrlAndroid;

      _latestVersionIOSController.text = config.latestVersionIOS;
      _minVersionIOSController.text = config.minVersionIOS;
      _updateUrlIOSController.text = config.updateUrlIOS;

      _latestVersionWindowsController.text = config.latestVersionWindows;
      _minVersionWindowsController.text = config.minVersionWindows;
      _updateUrlWindowsController.text = config.updateUrlWindows;
    }
  }

  @override
  void dispose() {
    _latestVersionAndroidController.dispose();
    _minVersionAndroidController.dispose();
    _updateUrlAndroidController.dispose();
    _latestVersionIOSController.dispose();
    _minVersionIOSController.dispose();
    _updateUrlIOSController.dispose();
    _latestVersionWindowsController.dispose();
    _minVersionWindowsController.dispose();
    _updateUrlWindowsController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final currentConfig = provider.config;
    if (currentConfig == null) return;

    // Use copyWith to update only version fields
    final newConfig = currentConfig.copyWith(
      latestVersionAndroid: _latestVersionAndroidController.text,
      minVersionAndroid: _minVersionAndroidController.text,
      updateUrlAndroid: _updateUrlAndroidController.text,
      latestVersionIOS: _latestVersionIOSController.text,
      minVersionIOS: _minVersionIOSController.text,
      updateUrlIOS: _updateUrlIOSController.text,
      latestVersionWindows: _latestVersionWindowsController.text,
      minVersionWindows: _minVersionWindowsController.text,
      updateUrlWindows: _updateUrlWindowsController.text,
    );

    await provider.updateConfig(newConfig);

    if (mounted && provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Version settings updated!'),
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
      appBar: AppBar(title: const Text('Version Control')),
      body: provider.isLoading && provider.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Android'),
                    _buildVersionRow(_latestVersionAndroidController,
                        _minVersionAndroidController),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _updateUrlAndroidController,
                      decoration: const InputDecoration(
                          labelText: 'Update URL (Android)',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('iOS'),
                    _buildVersionRow(
                        _latestVersionIOSController, _minVersionIOSController),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _updateUrlIOSController,
                      decoration: const InputDecoration(
                          labelText: 'Update URL (iOS)',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Windows'),
                    _buildVersionRow(_latestVersionWindowsController,
                        _minVersionWindowsController),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _updateUrlWindowsController,
                      decoration: const InputDecoration(
                          labelText: 'Update URL (Windows)',
                          border: OutlineInputBorder()),
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
                            : const Text('SAVE VERSIONS',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVersionRow(
      TextEditingController latestCtrl, TextEditingController minCtrl) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: latestCtrl,
            decoration: const InputDecoration(
                labelText: 'Latest Version', border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: minCtrl,
            decoration: const InputDecoration(
                labelText: 'Min Version', border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }
}


