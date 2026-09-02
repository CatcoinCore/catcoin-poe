import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _coinExplorerApiKeyController;
  bool _enableWalletHoldingDays = true;
  bool _globalWithdrawalEnabled = true;
  bool _obscureCoinExplorerApiKey = true;

  @override
  void initState() {
    super.initState();
    _coinExplorerApiKeyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.fetchFullAdminConfig();
      if (mounted) _loadConfig();
    });
  }

  void _loadConfig() {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null) {
      _coinExplorerApiKeyController.text = config.coinExplorerApiKey ?? '';
      setState(() {
        _enableWalletHoldingDays = config.enableWalletHoldingDays;
        _globalWithdrawalEnabled = config.globalWithdrawalEnabled;
      });
    }
  }

  @override
  void dispose() {
    _coinExplorerApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final currentConfig = provider.config;
    if (currentConfig == null) return;

    final newConfig = currentConfig.copyWith(
      coinExplorerApiKey: _coinExplorerApiKeyController.text.isEmpty
          ? null
          : _coinExplorerApiKeyController.text,
      enableWalletHoldingDays: _enableWalletHoldingDays,
      globalWithdrawalEnabled: _globalWithdrawalEnabled,
    );

    await provider.updateConfig(newConfig);

    if (mounted && provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wallet settings updated!'),
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
      appBar: AppBar(title: const Text('Wallet Configuration')),
      body: provider.isLoading && provider.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Withdrawal Controls',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: const Text('GLOBAL WITHDRAWALS ENABLED'),
                      subtitle: const Text('Completely enable/disable all withdrawals for all users'),
                      value: _globalWithdrawalEnabled,
                      onChanged: (val) =>
                          setState(() => _globalWithdrawalEnabled = val),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Wallet Features',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: const Text('Enable "Days Held" Feature'),
                      value: _enableWalletHoldingDays,
                      onChanged: (val) =>
                          setState(() => _enableWalletHoldingDays = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coinExplorerApiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Coin Explorer API Key',
                        border: const OutlineInputBorder(),
                        hintText: 'Required for history',
                        suffixIcon: IconButton(
                          tooltip: _obscureCoinExplorerApiKey ? 'Show' : 'Hide',
                          icon: Icon(_obscureCoinExplorerApiKey
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                              _obscureCoinExplorerApiKey =
                                  !_obscureCoinExplorerApiKey),
                        ),
                      ),
                      obscureText: _obscureCoinExplorerApiKey,
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
                            : const Text('SAVE WALLET SETTINGS',
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


