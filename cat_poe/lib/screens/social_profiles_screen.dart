import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/telegram_help_dialog.dart';

class SocialProfilesScreen extends StatefulWidget {
  const SocialProfilesScreen({super.key});

  @override
  State<SocialProfilesScreen> createState() => _SocialProfilesScreenState();
}

class _SocialProfilesScreenState extends State<SocialProfilesScreen> {
  final TextEditingController _discordController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _discordController.text = user.discordId ?? '';
        _telegramController.text = user.telegramId ?? '';
        _xController.text = user.xId ?? '';
        _facebookController.text = user.facebookId ?? '';
        _whatsappController.text = user.whatsappId ?? '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _discordController.dispose();
    _telegramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveSocialIds(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations l, {
    required bool confirmRevocation,
  }) async {
    final body = <String, dynamic>{
      'discord_id': _discordController.text.isEmpty
          ? null
          : _discordController.text,
      'telegram_id': _telegramController.text.isEmpty
          ? null
          : _telegramController.text,
      'x_id': _xController.text.isEmpty ? null : _xController.text,
      'facebook_id': _facebookController.text.isEmpty
          ? null
          : _facebookController.text,
      'whatsapp_id': _whatsappController.text.isEmpty
          ? null
          : _whatsappController.text,
    };
    if (confirmRevocation) {
      body['confirm_social_reward_revocation'] = true;
    }
    try {
      await authProvider.updateProfile(body);
      if (context.mounted) {
        await authProvider.fetchUserProfile();
        if (!context.mounted) return;
        final u = authProvider.user;
        if (u != null) {
          _discordController.text = u.discordId ?? '';
          _telegramController.text = u.telegramId ?? '';
          _xController.text = u.xId ?? '';
          _facebookController.text = u.facebookId ?? '';
          _whatsappController.text = u.whatsappId ?? '';
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profileUpdatedSuccess)),
        );
      }
    } on SocialIdChangeRequiresConfirmationException catch (e) {
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.profileSocialChangeTitle),
          content: Text(e.message.isNotEmpty
              ? e.message
              : l.profileSocialChangeBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text(l.profileSocialChangeConfirm),
            ),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        await _saveSocialIds(context, authProvider, l,
            confirmRevocation: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.commonError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSocialField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
    bool isNumeric = false,
    String? helperText,
    VoidCallback? onTap,
    bool isVerified = false,
    bool isLocked = false,
    String? platformId,
    AuthProvider? authProvider,
    BuildContext? fieldContext,
  }) {
    final l = AppLocalizations.of(context);
    final readOnly = isVerified && !isLocked;
    final verifiedEditable = isVerified && isLocked;
    return TextField(
      controller: controller,
      onTap: (!isVerified || verifiedEditable) ? onTap : null,
      readOnly: readOnly,
      style: TextStyle(color: isVerified ? Colors.grey : null),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isVerified ? Colors.green : null),
        suffixIcon: isVerified
            ? IconButton(
                icon: const Icon(Icons.lock, color: Colors.green),
                tooltip: l.profileVerifiedTooltip,
                onPressed: () {
                  if (fieldContext != null &&
                      authProvider != null &&
                      platformId != null) {
                    _showResetConfirmation(
                        fieldContext, platformId, authProvider);
                  }
                },
              )
            : null,
        labelText: label,
        hintText: hint,
        helperText: verifiedEditable
            ? l.profileVerifiedLockedHint
            : (isVerified ? l.profileVerified : helperText),
        helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  void _showResetConfirmation(
      BuildContext context, String platformId, AuthProvider authProvider) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetSocialTitle(platformId.toUpperCase())),
        content: Text(l.resetSocialMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await authProvider.resetSocialId(platformId);
                if (context.mounted) {
                  final u = authProvider.user;
                  if (u != null) {
                    _discordController.text = u.discordId ?? '';
                    _telegramController.text = u.telegramId ?? '';
                    _xController.text = u.xId ?? '';
                    _facebookController.text = u.facebookId ?? '';
                    _whatsappController.text = u.whatsappId ?? '';
                    setState(() {});
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.resetSocialUnlocked)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l.resetSocialFailed(e.toString())),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l.commonUnlockEdit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileSocialProfiles),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSocialField(
                    l.profileDiscord,
                    _discordController,
                    Icons.discord,
                    hint: l.profileDiscordHint,
                    isVerified: user?.discordIdVerified ?? false,
                    isLocked: user?.discordIdLocked ?? false,
                    platformId: 'discord',
                    authProvider: authProvider,
                    fieldContext: context,
                  ),
                  const SizedBox(height: 10),
                  _buildSocialField(
                    l.profileTelegram,
                    _telegramController,
                    Icons.send,
                    hint: l.profileTelegramHint,
                    isNumeric: true,
                    isVerified: user?.telegramIdVerified ?? false,
                    isLocked: user?.telegramIdLocked ?? false,
                    platformId: 'telegram',
                    authProvider: authProvider,
                    fieldContext: context,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const TelegramHelpDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSocialField(
                    l.profileX,
                    _xController,
                    Icons.close,
                    isVerified: user?.xIdVerified ?? false,
                    isLocked: user?.xIdLocked ?? false,
                    platformId: 'x',
                    authProvider: authProvider,
                    fieldContext: context,
                  ),
                  const SizedBox(height: 10),
                  _buildSocialField(
                    l.profileFacebook,
                    _facebookController,
                    Icons.facebook,
                    isVerified: user?.facebookIdVerified ?? false,
                    isLocked: user?.facebookIdLocked ?? false,
                    platformId: 'facebook',
                    authProvider: authProvider,
                    fieldContext: context,
                  ),
                  const SizedBox(height: 10),
                  _buildSocialField(
                    l.profileWhatsapp,
                    _whatsappController,
                    Icons.phone,
                    isVerified: user?.whatsappIdVerified ?? false,
                    isLocked: user?.whatsappIdLocked ?? false,
                    platformId: 'whatsapp',
                    authProvider: authProvider,
                    fieldContext: context,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              await _saveSocialIds(
                                context,
                                authProvider,
                                l,
                                confirmRevocation: false,
                              );
                            },
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l.profileSaveSocialIds),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
