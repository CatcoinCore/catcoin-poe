import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mission.dart';
import '../providers/mission_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'telegram_help_dialog.dart';

class MissionCard extends StatefulWidget {
  final Mission mission;

  const MissionCard({super.key, required this.mission});

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  bool _isClaiming = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _getIconWidget(BuildContext context, String? iconName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (iconName?.toLowerCase()) {
      case 'discord':
        return const Icon(Icons.discord, size: 32, color: Color(0xFF5865F2));
      case 'twitter':
      case 'x':
        return Icon(Icons.close,
            size: 32, color: isDark ? Colors.white : Colors.black); // Approximate X logo
      case 'telegram':
        return const Icon(Icons.send, size: 32, color: Color(0xFF0088cc));
      case 'facebook':
        return const Icon(Icons.facebook, size: 32, color: Color(0xFF1877F2));
      case 'youtube':
        return const Icon(Icons.play_arrow, size: 32, color: Color(0xFFFF0000));
      default:
        return Icon(iconName == 'discord' ? Icons.videogame_asset : Icons.star,
            size: 32, color: Colors.orange);
    }
  }

  Future<void> _handleClaim() async {
    setState(() {
      _isClaiming = true;
    });

    final provider = context.read<MissionProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final mission = widget.mission;

    try {
      if (!mounted) return;
      final l = AppLocalizations.of(context);

      String? verificationProof;

      // 1. Check Profile for existing ID
      String? savedId;
      String socialType = mission.icon?.toLowerCase() ?? '';

      // Determine if it requires async verification
      bool isAsyncVerify = socialType.contains('discord') ||
          socialType.contains('telegram') ||
          socialType.contains('x') ||
          socialType.contains('twitter');

      if (user != null) {
        if (socialType.contains('discord')) {
          savedId = user.discordId;
        } else if (socialType.contains('telegram')) {
          savedId = user.telegramId;
        } else if (socialType.contains('x') || socialType.contains('twitter')) {
          savedId = user.xId;
        } else if (socialType.contains('facebook')) {
          savedId = user.facebookId;
        } else if (socialType.contains('whatsapp')) {
          savedId = user.whatsappId;
        }
      }

      verificationProof = savedId;

      // 2. If ID/Username missing for Social missions, prompt to Enter & Save
      if ((mission.type == 'SOCIAL' || isAsyncVerify) &&
          (savedId == null || savedId.isEmpty)) {
        final isDiscord = socialType.contains('discord');
        final isTelegram = socialType.contains('telegram');
        final hint = isDiscord
            ? l.missionHintDiscord
            : (isTelegram ? l.missionHintTelegram : l.missionHintGeneric);

        String? inputId = await showDialog<String>(
          context: context,
          builder: (ctx) {
            String input = '';
            return AlertDialog(
              title: Text(l.missionVerifyTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isDiscord
                      ? l.missionVerifyDiscord
                      : (isTelegram
                          ? l.missionVerifyTelegram
                          : l.missionVerifyGeneric)),
                  if (isTelegram)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: ctx,
                            builder: (context) => const TelegramHelpDialog(),
                          );
                        },
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: Text(l.missionHelpGetId,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  // Use a deferred-focus wrapper instead of `autofocus: true`
                  // so the IME's showSoftInput() is called AFTER the dialog
                  // window is laid out — autofocus inside an AlertDialog can
                  // ANR the main thread waiting on a Binder transact to the
                  // InputMethodManager (see ANR trace 2026-05-26).
                  _DeferredFocusTextField(
                    keyboardType:
                        isTelegram ? TextInputType.number : TextInputType.text,
                    inputFormatters: isTelegram
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(hintText: hint),
                    onChanged: (v) => input = v,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.commonCancel)),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, input),
                    child: Text(l.missionSaveContinue)),
              ],
            );
          },
        );

        // If cancelled, stop
        if (inputId == null || inputId.isEmpty) {
          setState(() {
            _isClaiming = false;
          });
          return;
        }

        // Save to profile
        verificationProof = inputId;
        Map<String, dynamic> update = {};
        if (socialType.contains('discord')) {
          update['discord_id'] = inputId;
        } else if (socialType.contains('telegram')) {
          update['telegram_id'] = inputId;
        } else if (socialType.contains('x') || socialType.contains('twitter')) {
          update['x_id'] = inputId;
        }

        if (update.isNotEmpty) {
          try {
            await authProvider.updateProfile(update);
          } on SocialIdChangeRequiresConfirmationException catch (e) {
            if (!mounted) return;
            final loc = AppLocalizations.of(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(loc.profileSocialChangeTitle),
                content: Text(e.message.isNotEmpty
                    ? e.message
                    : loc.profileSocialChangeBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(loc.commonCancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(loc.profileSocialChangeConfirm),
                  ),
                ],
              ),
            );
            if (ok == true && mounted) {
              final withConfirm = Map<String, dynamic>.from(update);
              withConfirm['confirm_social_reward_revocation'] = true;
              try {
                await authProvider.updateProfile(withConfirm);
              } catch (_) {
                // Continue mission flow even if second save fails
              }
            }
          } catch (e) {
            // Continue even if save fails locally
          }
        }
      }

      // 3. Claim (starts background verification)
      await provider.completeMission(mission.code,
          verificationData: verificationProof ?? "manual_claim");

      // 4. Launch Link (AFTER initating claim so they go verify)
      if (mission.link != null) {
        _launchURL(mission.link!);
      }

      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAsyncVerify
                ? l.missionVerificationStarted
                : l.missionClaimedSuccess(mission.rewardAmount.toStringAsFixed(0))),
            backgroundColor: isAsyncVerify ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.missionFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getIconWidget(context, widget.mission.icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mission.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.mission.description != null)
                        Text(
                          widget.mission.description!,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey[600],
                          ),
                        ),
                      if (widget.mission.expiresAt != null) ...[
                        const SizedBox(height: 4),
                        Builder(builder: (context) {
                          final diff = widget.mission.expiresAt!
                              .difference(DateTime.now());
                          if (diff.isNegative) {
                            return Text(l.missionExpired,
                                style:
                                    const TextStyle(color: Colors.red, fontSize: 12));
                          }
                          final days = diff.inDays;
                          final hours = diff.inHours % 24;
                          return Text(
                            days > 0
                                ? l.missionExpiresInDays(days.toString())
                                : l.missionExpiresInHours(hours.toString()),
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.missionReward(widget.mission.rewardAmount.toStringAsFixed(0)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (widget.mission.status == 'COMPLETED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l.missionClaimed,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (widget.mission.status == 'PENDING')
                  Chip(
                    label: Text(l.missionStatusVerifying),
                    backgroundColor: Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  )
                else
                  ElevatedButton(
                    onPressed: _isClaiming ? null : _handleClaim,
                    child: _isClaiming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l.missionBtnClaim),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A [TextField] that requests focus via a post-frame callback instead of the
/// stock `autofocus: true`, which fires its `showSoftInput` IME call before
/// the host window (especially an [AlertDialog]) is fully attached. That race
/// has been observed to ANR the main thread waiting on the Binder transact to
/// the system InputMethodManager.
///
/// Drop-in replacement for `TextField(autofocus: true, ...)` inside dialogs.
class _DeferredFocusTextField extends StatefulWidget {
  const _DeferredFocusTextField({
    required this.keyboardType,
    required this.inputFormatters,
    required this.decoration,
    required this.onChanged,
  });

  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;

  @override
  State<_DeferredFocusTextField> createState() =>
      _DeferredFocusTextFieldState();
}

class _DeferredFocusTextFieldState extends State<_DeferredFocusTextField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}

