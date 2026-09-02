import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/link_service.dart';
import '../services/profile_service.dart';
import '../services/version_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'profile_setup_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({
    super.key,
    this.splashMinDuration = const Duration(seconds: 2),
    this.runVersionCheck = true,
  });

  /// Minimum time to show splash (branding). Use [Duration.zero] in tests.
  final Duration splashMinDuration;

  /// When false, skips [VersionService.checkVersion] (avoids network in widget tests).
  final bool runVersionCheck;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool _profileSetupCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Create [LinkService] early so /invite/CODE is captured on web (Uri.base)
      // before the user reaches Signup — it was previously lazy-created on Signup only.
      context.read<LinkService>();
      _checkAuthAndProfile();
    });
  }

  Future<void> _checkAuthAndProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Ensure splash screen shows for at least 2 seconds for branding
    await Future.wait([
      authProvider.checkAuth(),
      Future.delayed(widget.splashMinDuration),
    ]);

    // Check for app updates
    if (widget.runVersionCheck && mounted) {
      VersionService.checkVersion(context);
    }

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Check if profile setup is done
      final isDone =
          await ProfileService.isProfileSetupCompleted(authProvider.user!.id);

      // Also check if they already have a display name (implies done)
      final hasName = authProvider.user!.displayName != null &&
          authProvider.user!.displayName!.isNotEmpty;

      if (mounted) {
        setState(() {
          _profileSetupCompleted = isDone || hasName;
          _isInitializing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }

    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.sessionResumeBlocked) {
      final l = AppLocalizations.of(context);
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Could not reach the server to verify your session.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your login is still saved. You can retry or sign out.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: authProvider.isResumeProfileLoading
                      ? null
                      : () => context.read<AuthProvider>().retryResumeSession(),
                  child: authProvider.isResumeProfileLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.commonRetry),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authProvider.isResumeProfileLoading
                      ? null
                      : () => context.read<AuthProvider>().logout(),
                  child: Text(l.profileLogout),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated and checked
    if (!_profileSetupCompleted) {
      return const ProfileSetupScreen();
    }

    return const MainScreen();
  }
}


