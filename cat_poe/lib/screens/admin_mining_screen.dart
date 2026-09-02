import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/api_locale.dart';

class AdminMiningScreen extends StatefulWidget {
  const AdminMiningScreen({super.key});

  @override
  State<AdminMiningScreen> createState() => _AdminMiningScreenState();
}

class _AdminMiningScreenState extends State<AdminMiningScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _baseDurationController;
  late TextEditingController _maxDurationController;
  late TextEditingController _extensionSlotsController;
  late TextEditingController _manualCatPriceUsdtController;
  late TextEditingController _coingeckoCoinIdController;
  late TextEditingController _catoshiYieldController;
  late TextEditingController _referralBoostPercentageController;
  late TextEditingController _maxActiveReferrersController;
  late TextEditingController _referralMilestoneBonusCatoshiController;
  late TextEditingController _gameBoostConfigController;
  late TextEditingController _bonusAmountController;
  late TextEditingController _bonusCountController;
  bool _useManualCatPrice = false;
  String? _tempLeaderboardSortBy;
  bool _isGeneratingBonus = false;

  @override
  void initState() {
    super.initState();
    _baseDurationController = TextEditingController();
    _maxDurationController = TextEditingController();
    _extensionSlotsController = TextEditingController();
    _manualCatPriceUsdtController = TextEditingController();
    _coingeckoCoinIdController = TextEditingController();
    _catoshiYieldController = TextEditingController();
    _referralBoostPercentageController = TextEditingController();
    _maxActiveReferrersController = TextEditingController();
    _referralMilestoneBonusCatoshiController =
        TextEditingController(text: '10000000');
    _gameBoostConfigController = TextEditingController();
    _bonusAmountController = TextEditingController(text: '50000');
    _bonusCountController = TextEditingController(text: '10');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          .fetchConfig(languageCode: apiLanguageCodeFromContext(context))
          .then((_) {
        if (mounted) _loadConfig();
      });
    });
  }

  void _loadConfig() {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null) {
      setState(() {
        _tempLeaderboardSortBy = config.leaderboardSortBy;
        _useManualCatPrice = config.useManualCatPrice;
        _baseDurationController.text =
            config.baseMiningDurationMinutes.toString();
        _maxDurationController.text =
            config.maxMiningDurationMinutes.toString();
        _maxDurationController.text =
            config.maxMiningDurationMinutes.toString();
        _extensionSlotsController.text = config.timeExtensionSlots;
        _manualCatPriceUsdtController.text =
            config.manualCatPriceUsdt.toString();
        _coingeckoCoinIdController.text = config.coingeckoCoinId;
        _catoshiYieldController.text = config.catoshiYieldPercentage.toString();
        _referralBoostPercentageController.text =
            config.referralBoostPercentage.toString();
        _maxActiveReferrersController.text =
            config.maxActiveReferrers.toString();
        _referralMilestoneBonusCatoshiController.text =
            config.referralMilestoneBonusCatoshi.toString();
        _gameBoostConfigController.text = config.gameBoostConfig;
      });
    }
  }

  @override
  void dispose() {
    _baseDurationController.dispose();
    _maxDurationController.dispose();
    _extensionSlotsController.dispose();
    _manualCatPriceUsdtController.dispose();
    _coingeckoCoinIdController.dispose();
    _catoshiYieldController.dispose();
    _referralBoostPercentageController.dispose();
    _maxActiveReferrersController.dispose();
    _referralMilestoneBonusCatoshiController.dispose();
    _gameBoostConfigController.dispose();
    _bonusAmountController.dispose();
    _bonusCountController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final currentConfig = provider.config;
    if (currentConfig == null) return;

    try {
      final newConfig = currentConfig.copyWith(
      baseMiningDurationMinutes: int.tryParse(_baseDurationController.text) ??
            currentConfig.baseMiningDurationMinutes,
      maxMiningDurationMinutes: int.tryParse(_maxDurationController.text) ??
            currentConfig.maxMiningDurationMinutes,
        timeExtensionSlots: _extensionSlotsController.text,
        useManualCatPrice: _useManualCatPrice,
        manualCatPriceUsdt: int.tryParse(_manualCatPriceUsdtController.text) ??
            currentConfig.manualCatPriceUsdt,
        coingeckoCoinId: _coingeckoCoinIdController.text,
        catoshiYieldPercentage:
            double.tryParse(_catoshiYieldController.text) ??
                currentConfig.catoshiYieldPercentage,
        referralBoostPercentage:
            double.tryParse(_referralBoostPercentageController.text) ??
                currentConfig.referralBoostPercentage,
        maxActiveReferrers: int.tryParse(_maxActiveReferrersController.text) ??
            currentConfig.maxActiveReferrers,
        referralMilestoneBonusCatoshi:
            int.tryParse(_referralMilestoneBonusCatoshiController.text) ??
                currentConfig.referralMilestoneBonusCatoshi,
        leaderboardSortBy: _tempLeaderboardSortBy,
        gameBoostConfig: _gameBoostConfigController.text,
      );

      await provider.updateConfig(newConfig);

      if (mounted && provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mining settings updated!'),
              backgroundColor: Colors.green),
        );
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateBonusCodes() async {
    final amount = double.tryParse(_bonusAmountController.text);
    final count = int.tryParse(_bonusCountController.text) ?? 1;

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    setState(() => _isGeneratingBonus = true);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    try {
      final List response = await adminProvider.generateBonusCodes(amount, count);

      if (mounted) {
        final List codes = response.map((e) => e['code']).toList();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Generated Bonus Codes'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: codes.length,
                itemBuilder: (context, i) => ListTile(
                  title: SelectableText(codes[i]),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingBonus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mining & Referrals')),
      body: provider.isLoading && provider.config == null
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                // If config just became available and we haven't loaded it, load it now
                if (adminProvider.config != null &&
                    _baseDurationController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadConfig();
                  });
                }

                return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mining Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catoshiYieldController,
                      decoration: const InputDecoration(
                          labelText: 'Base catoshi Yield Percentage',
                          border: OutlineInputBorder(),
                          helperText: 'Default: 100.0%'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _baseDurationController,
                            decoration: const InputDecoration(
                                labelText: 'Base Duration (min)',
                                border: OutlineInputBorder(),
                                helperText: 'Default: 480 (8h)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxDurationController,
                            decoration: const InputDecoration(
                                labelText: 'Max Duration (min)',
                                border: OutlineInputBorder(),
                                helperText: 'Default: 1440 (24h)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _extensionSlotsController,
                      decoration: const InputDecoration(
                        labelText: 'Extension Slots (JSON)',
                        border: OutlineInputBorder(),
                        hintText: '[120, 180, 240]',
                        helperText: 'Default: [120, 180, 240, 300, 360]',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    const Text('Referral Boosters',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _referralBoostPercentageController,
                            decoration: const InputDecoration(
                                labelText: 'Boost per Referral (%)',
                                border: OutlineInputBorder(),
                                helperText: 'Default: 10.0%'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxActiveReferrersController,
                            decoration: const InputDecoration(
                                labelText: 'Max Active Referrers',
                                border: OutlineInputBorder(),
                                helperText: 'Default: 10'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referralMilestoneBonusCatoshiController,
                      decoration: const InputDecoration(
                        labelText: 'Referral milestone bonus (catoshi)',
                        border: OutlineInputBorder(),
                        helperText:
                            'One-time reward per qualifying invite. Applies to new referral links only.',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Whole number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text('Dynamic Token Reward Price',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coingeckoCoinIdController,
                      decoration: const InputDecoration(
                          labelText: 'CoinGecko Token ID',
                          border: OutlineInputBorder(),
                          helperText: 'e.g. catcoins'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Use Manual USD Price Override'),
                      subtitle:
                          const Text('Bypass CoinGecko real-time lookups.'),
                      value: _useManualCatPrice,
                      onChanged: (bool value) {
                        setState(() {
                          _useManualCatPrice = value;
                        });
                      },
                    ),
                    if (_useManualCatPrice)
                      TextFormField(
                        controller: _manualCatPriceUsdtController,
                        decoration: const InputDecoration(
                            labelText: 'CAT Price (Micro-USDT)',
                            border: OutlineInputBorder(),
                            helperText: 'e.g. 50000 = \$0.05'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    const SizedBox(height: 32),
                    const Text('Leaderboard Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _tempLeaderboardSortBy ??
                          adminProvider.config?.leaderboardSortBy ??
                          'BALANCE',
                      decoration: const InputDecoration(
                        labelText: 'Leaderboard Ranking Basis',
                        border: OutlineInputBorder(),
                        helperText:
                            'BALANCE: Current holdings. TOTAL_EARNINGS: Lifetime accumulated rewards.',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'BALANCE', child: Text('Current Balance')),
                        DropdownMenuItem(
                            value: 'TOTAL_EARNINGS',
                            child: Text('Total Earnings (Lifetime)')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          // We use local state or just update the provider config in copyWith
                          // Given the current pattern in _saveConfig:
                          // final newConfig = currentConfig.copyWith(leaderboardSortBy: newValue);
                          // But we need a way to track this change before Save is pressed.
                          // Actually, this screen doesn't seem to have a local state for most things except bools.
                          // It uses controllers for text. I'll just use a local variable.
                        }
                        setState(() {
                          _tempLeaderboardSortBy = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text('Game Boost Configurations (JSON)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gameBoostConfigController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Speed & Duration Matrix',
                        border: OutlineInputBorder(),
                        helperText: 'e.g. {"20": [60, 120], "15": [60, 120, 180]}',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text('Admin: Generate Special Bonus Codes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bonusAmountController,
                            decoration: const InputDecoration(
                                labelText: 'Amount (Catoshi)',
                                border: OutlineInputBorder(),
                                helperText: 'e.g. 50000'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _bonusCountController,
                            decoration: const InputDecoration(
                                labelText: 'Count',
                                border: OutlineInputBorder(),
                                helperText: 'Quantity to generate'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingBonus ? null : _generateBonusCodes,
                        icon: _isGeneratingBonus 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.generating_tokens),
                        label: const Text('GENERATE UNIQUE CODES'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
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
                            : const Text('SAVE MINING SETTINGS',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}


