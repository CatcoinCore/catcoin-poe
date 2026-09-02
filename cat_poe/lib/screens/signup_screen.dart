import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/link_service.dart';
import '../services/pending_referral_storage.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  bool _isValid = false;
  bool _isLoading = false;
  /// When false and referral text is non-empty, show compact "applied" UI instead of the field.
  bool _referralFieldExpanded = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validate);
    _passwordController.addListener(_validate);
    _confirmPasswordController.addListener(_validate);

    unawaited(_hydrateReferralFromDisk());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mergeReferralFromLinkService();
      final linkService = Provider.of<LinkService>(context, listen: false);
      linkService.addListener(_onLinkChanged);
    });

    _checkInstallReferrer();
  }

  Future<void> _hydrateReferralFromDisk() async {
    final stored = await PendingReferralStorage.load();
    if (!mounted || stored == null || stored.isEmpty) return;
    if (_referralCodeController.text.trim().isEmpty) {
      setState(() {
        _referralCodeController.text = stored;
        _referralFieldExpanded = false;
      });
    }
  }

  Future<void> _applyReferralCode(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return;
    await PendingReferralStorage.save(code);
    if (!mounted) return;
    setState(() {
      _referralCodeController.text = code;
      _referralFieldExpanded = false;
    });
  }

  void _mergeReferralFromLinkService() {
    final linkService = Provider.of<LinkService>(context, listen: false);
    if (linkService.pendingReferralCode != null &&
        linkService.pendingReferralCode!.isNotEmpty) {
      unawaited(_applyReferralCode(linkService.pendingReferralCode!));
      linkService.consumeCode();
      return;
    }
    if (kIsWeb) {
      final fromUrl = parseInviteReferralCode(Uri.base);
      if (fromUrl != null && fromUrl.isNotEmpty) {
        unawaited(_applyReferralCode(fromUrl));
      }
    }
  }

  void _onLinkChanged() {
    final linkService = Provider.of<LinkService>(context, listen: false);
    if (linkService.pendingReferralCode != null && mounted) {
      unawaited(_applyReferralCode(linkService.pendingReferralCode!));
      linkService.consumeCode();
    }
  }

  Future<void> _checkInstallReferrer() async {
    try {
      String? codeFound;

      if (Platform.isAndroid) {
        try {
          final referrerInfo = await PlayInstallReferrer.installReferrer;
          final refString = referrerInfo.installReferrer ?? '';
          if (refString.contains('inv_')) {
            codeFound = refString.split('inv_').last.split('&').first;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Play Install Referrer error: $e');
        }
      }

      if ((codeFound == null || codeFound.isEmpty) && mounted) {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        final text = clipboardData?.text ?? '';
        if (text.contains('/invite/')) {
          codeFound = text
              .split('/invite/')
              .last
              .split(RegExp(r'\s+'))
              .first
              .split('?')
              .first
              .split('#')
              .first;
        }
      }

      if (mounted && codeFound != null && codeFound.isNotEmpty) {
        await _applyReferralCode(codeFound);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error reading install referrer: $e');
    }
  }

  @override
  void dispose() {
    try {
      final linkService = Provider.of<LinkService>(context, listen: false);
      linkService.removeListener(_onLinkChanged);
    } catch (_) {}

    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmailValid = emailRegex.hasMatch(email);
    final isPasswordValid = password.isNotEmpty && password.length >= 6;
    final isConfirmPasswordValid = password == _confirmPasswordController.text;

    setState(() {
      _isValid = isEmailValid && isPasswordValid && isConfirmPasswordValid;
    });
  }

  Future<void> _handleSignup() async {
    if (!_isValid) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signup(
        _emailController.text.trim(),
        _passwordController.text,
        referralCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
      );

      await PendingReferralStorage.clear();
      if (mounted) {
        final linkService = Provider.of<LinkService>(context, listen: false);
        linkService.consumeCode();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool get _showReferralTextField {
    final t = _referralCodeController.text.trim();
    return t.isEmpty || _referralFieldExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.signupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l.signupEmail,
                  hintText: l.signupEmailHint,
                  helperText: ' ',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 3),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l.signupPassword,
                  helperText: ' ',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 3),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: l.signupConfirmPassword,
                  helperText: ' ',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 8),
              if (_showReferralTextField)
                TextField(
                  controller: _referralCodeController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.signupReferralCode,
                    hintText: l.signupReferralCodeHint,
                    helperText: ' ',
                  ),
                  textCapitalization: TextCapitalization.characters,
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.signupReferralFromInviteTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.signupReferralFromInviteBody(
                            _referralCodeController.text.trim(),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _referralFieldExpanded = true;
                              });
                            },
                            child: Text(l.signupReferralChangeCode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _isValid ? _handleSignup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isValid ? Colors.deepOrange : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(l.signupButton),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
