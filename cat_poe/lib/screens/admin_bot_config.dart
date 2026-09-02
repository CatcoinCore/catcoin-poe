import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminBotConfigScreen extends StatefulWidget {
  const AdminBotConfigScreen({super.key});

  @override
  State<AdminBotConfigScreen> createState() => _AdminBotConfigScreenState();
}

class _AdminBotConfigScreenState extends State<AdminBotConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _discordBotTokenController;
  late TextEditingController _discordGuildIdController;
  late TextEditingController _telegramBotTokenController;
  late TextEditingController _telegramChatIdController;

  late TextEditingController _xBearerTokenController;
  late TextEditingController _xCommunityUsernameController;
  // NEW X Handlers
  late TextEditingController _xConsumerKeyController;
  late TextEditingController _xConsumerSecretController;
  late TextEditingController _xAccessTokenController;
  late TextEditingController _xAccessTokenSecretController;
  late TextEditingController _xClientIdController;
  late TextEditingController _xClientSecretController;

  late TextEditingController _verificationBackoffDelaysController;
  late TextEditingController _gameRewardConfigController;

  bool _enableVerificationRelease = true;
  bool _enableVerificationDebug = true;

  bool _obscureDiscordBotToken = true;
  bool _obscureTelegramBotToken = true;
  bool _obscureXBearer = true;
  bool _obscureXConsumerKey = true;
  bool _obscureXConsumerSecret = true;
  bool _obscureXAccessToken = true;
  bool _obscureXAccessTokenSecret = true;
  bool _obscureXClientId = true;
  bool _obscureXClientSecret = true;

  InputDecoration _obscuredOutlineDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onVisibilityPressed,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        tooltip: obscure ? 'Show' : 'Hide',
        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        onPressed: onVisibilityPressed,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _discordBotTokenController = TextEditingController();
    _discordGuildIdController = TextEditingController();
    _telegramBotTokenController = TextEditingController();
    _telegramChatIdController = TextEditingController();

    _xBearerTokenController = TextEditingController();
    _xCommunityUsernameController = TextEditingController();
    _xConsumerKeyController = TextEditingController();
    _xConsumerSecretController = TextEditingController();
    _xAccessTokenController = TextEditingController();
    _xAccessTokenSecretController = TextEditingController();
    _xClientIdController = TextEditingController();
    _xClientSecretController = TextEditingController();

    _verificationBackoffDelaysController = TextEditingController();
    _gameRewardConfigController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.fetchFullAdminConfig();
      if (mounted) _loadConfig();
    });
  }

  void _loadConfig() {
    final config = Provider.of<AdminProvider>(context, listen: false).config;
    if (config != null) {
      _discordBotTokenController.text = config.discordBotToken ?? '';
      _discordGuildIdController.text = config.discordGuildId ?? '';
      _telegramBotTokenController.text = config.telegramBotToken ?? '';
      _telegramChatIdController.text = config.telegramChatId ?? '';

      _xBearerTokenController.text = config.xBearerToken ?? '';
      _xCommunityUsernameController.text = config.xCommunityUsername ?? '';
      _xConsumerKeyController.text = config.xConsumerKey ?? '';
      _xConsumerSecretController.text = config.xConsumerSecret ?? '';
      _xAccessTokenController.text = config.xAccessToken ?? '';
      _xAccessTokenSecretController.text = config.xAccessTokenSecret ?? '';
      _xClientIdController.text = config.xClientId ?? '';
      _xClientSecretController.text = config.xClientSecret ?? '';

      _verificationBackoffDelaysController.text =
          config.verificationBackoffDelays;
      _gameRewardConfigController.text = config.gameRewardConfig;

      setState(() {
        _enableVerificationRelease = config.enableVerificationRelease;
        _enableVerificationDebug = config.enableVerificationDebug;
      });
    }
  }

  @override
  void dispose() {
    _discordBotTokenController.dispose();
    _discordGuildIdController.dispose();
    _telegramBotTokenController.dispose();
    _telegramChatIdController.dispose();
    _xBearerTokenController.dispose();
    _xCommunityUsernameController.dispose();
    _xConsumerKeyController.dispose();
    _xConsumerSecretController.dispose();
    _xAccessTokenController.dispose();
    _xAccessTokenSecretController.dispose();
    _xClientIdController.dispose();
    _xClientSecretController.dispose();
    _verificationBackoffDelaysController.dispose();
    _gameRewardConfigController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final currentConfig = provider.config;
    if (currentConfig == null) return;

    final newConfig = currentConfig.copyWith(
      discordBotToken: _discordBotTokenController.text.isEmpty
          ? null
          : _discordBotTokenController.text,
      discordGuildId: _discordGuildIdController.text.isEmpty
          ? null
          : _discordGuildIdController.text,
      telegramBotToken: _telegramBotTokenController.text.isEmpty
          ? null
          : _telegramBotTokenController.text,
      telegramChatId: _telegramChatIdController.text.isEmpty
          ? null
          : _telegramChatIdController.text,
      xBearerToken: _xBearerTokenController.text.isEmpty
          ? null
          : _xBearerTokenController.text,
      xCommunityUsername: _xCommunityUsernameController.text.isEmpty
          ? null
          : _xCommunityUsernameController.text,
      xConsumerKey: _xConsumerKeyController.text.isEmpty
          ? null
          : _xConsumerKeyController.text,
      xConsumerSecret: _xConsumerSecretController.text.isEmpty
          ? null
          : _xConsumerSecretController.text,
      xAccessToken: _xAccessTokenController.text.isEmpty
          ? null
          : _xAccessTokenController.text,
      xAccessTokenSecret: _xAccessTokenSecretController.text.isEmpty
          ? null
          : _xAccessTokenSecretController.text,
      xClientId:
          _xClientIdController.text.isEmpty ? null : _xClientIdController.text,
      xClientSecret: _xClientSecretController.text.isEmpty
          ? null
          : _xClientSecretController.text,
      verificationBackoffDelays: _verificationBackoffDelaysController.text,
      gameRewardConfig: _gameRewardConfigController.text,
      enableVerificationRelease: _enableVerificationRelease,
      enableVerificationDebug: _enableVerificationDebug,
    );

    await provider.updateConfig(newConfig);

    if (mounted && provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bot settings updated!'),
            backgroundColor: Colors.green),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bot Configuration')),
      body: provider.isLoading && provider.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Discord'),
                    TextFormField(
                      controller: _discordBotTokenController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Bot Token',
                        obscure: _obscureDiscordBotToken,
                        onVisibilityPressed: () => setState(
                            () => _obscureDiscordBotToken = !_obscureDiscordBotToken),
                      ),
                      obscureText: _obscureDiscordBotToken,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discordGuildIdController,
                      decoration: const InputDecoration(
                        labelText: 'Guild ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Telegram'),
                    TextFormField(
                      controller: _telegramBotTokenController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Bot Token',
                        obscure: _obscureTelegramBotToken,
                        onVisibilityPressed: () => setState(() =>
                            _obscureTelegramBotToken = !_obscureTelegramBotToken),
                      ),
                      obscureText: _obscureTelegramBotToken,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telegramChatIdController,
                      decoration: const InputDecoration(
                        labelText: 'Chat ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('X (Twitter)'),
                    TextFormField(
                      controller: _xBearerTokenController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Bearer Token (App-Only Verification)',
                        obscure: _obscureXBearer,
                        onVisibilityPressed: () =>
                            setState(() => _obscureXBearer = !_obscureXBearer),
                      ),
                      obscureText: _obscureXBearer,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xCommunityUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Community Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('OAuth 1.0a (For Posting)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xConsumerKeyController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Consumer Key (API Key)',
                        obscure: _obscureXConsumerKey,
                        onVisibilityPressed: () => setState(() =>
                            _obscureXConsumerKey = !_obscureXConsumerKey),
                      ),
                      obscureText: _obscureXConsumerKey,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xConsumerSecretController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Consumer Secret (API Secret)',
                        obscure: _obscureXConsumerSecret,
                        onVisibilityPressed: () => setState(() =>
                            _obscureXConsumerSecret = !_obscureXConsumerSecret),
                      ),
                      obscureText: _obscureXConsumerSecret,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xAccessTokenController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Access Token',
                        obscure: _obscureXAccessToken,
                        onVisibilityPressed: () => setState(
                            () => _obscureXAccessToken = !_obscureXAccessToken),
                      ),
                      obscureText: _obscureXAccessToken,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xAccessTokenSecretController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Access Token Secret',
                        obscure: _obscureXAccessTokenSecret,
                        onVisibilityPressed: () => setState(() =>
                            _obscureXAccessTokenSecret =
                                !_obscureXAccessTokenSecret),
                      ),
                      obscureText: _obscureXAccessTokenSecret,
                    ),
                    const SizedBox(height: 16),
                    const Text('OAuth 2.0 (For Future Use)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xClientIdController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Client ID',
                        obscure: _obscureXClientId,
                        onVisibilityPressed: () => setState(
                            () => _obscureXClientId = !_obscureXClientId),
                      ),
                      obscureText: _obscureXClientId,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _xClientSecretController,
                      decoration: _obscuredOutlineDecoration(
                        label: 'Client Secret',
                        obscure: _obscureXClientSecret,
                        onVisibilityPressed: () => setState(() =>
                            _obscureXClientSecret = !_obscureXClientSecret),
                      ),
                      obscureText: _obscureXClientSecret,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Verification Settings'),
                    TextFormField(
                      controller: _verificationBackoffDelaysController,
                      decoration: const InputDecoration(
                        labelText: 'Backoff Delays (JSON)',
                        border: OutlineInputBorder(),
                        hintText: '[120, 180, ...]',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Enable Verification (Release)'),
                      value: _enableVerificationRelease,
                      onChanged: (val) =>
                          setState(() => _enableVerificationRelease = val),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Verification (Debug)'),
                      value: _enableVerificationDebug,
                      onChanged: (val) =>
                        setState(() => _enableVerificationDebug = val),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Game Rewards & Cooldowns'),
                    TextFormField(
                      controller: _gameRewardConfigController,
                      decoration: const InputDecoration(
                        labelText: 'Game Reward Config (JSON)',
                        border: OutlineInputBorder(),
                        hintText: '{"GAME_TYPE": {"reward": 10, ...}}',
                      ),
                      maxLines: 5,
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
                            : const Text('SAVE BOT SETTINGS',
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


