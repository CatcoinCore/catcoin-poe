import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/admin_provider.dart';
import '../services/logger_service.dart';
import '../utils/api_locale.dart';

class VersionService {
  static Future<void> checkVersion(BuildContext context) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Ensure config is loaded
      if (adminProvider.config == null) {
        await adminProvider.fetchConfig(
          languageCode: apiLanguageCodeFromContext(context),
        );
      }

      final config = adminProvider.config;
      if (config == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      if (!context.mounted) return;
      
      final currentVersion = packageInfo.version;
      final platform = Theme.of(context).platform;

      String latestVersion = '1.0.0';
      String minVersion = '1.0.0';
      String updateUrl = '';

      if (platform == TargetPlatform.android) {
        latestVersion = config.latestVersionAndroid;
        minVersion = config.minVersionAndroid;
        updateUrl = config.updateUrlAndroid;
      } else if (platform == TargetPlatform.iOS) {
        latestVersion = config.latestVersionIOS;
        minVersion = config.minVersionIOS;
        updateUrl = config.updateUrlIOS;
      } else if (platform == TargetPlatform.windows) {
        latestVersion = config.latestVersionWindows;
        minVersion = config.minVersionWindows;
        updateUrl = config.updateUrlWindows;
      } else {
        // Fallback or skip
        return;
      }

      LoggerService.info(
          'Version Check: Current=$currentVersion, Latest=$latestVersion, Min=$minVersion');

      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        final isMandatory = _isUpdateAvailable(currentVersion, minVersion);

        if (context.mounted) {
          _showUpdateDialog(context, updateUrl, isMandatory, latestVersion);
        }
      }
    } catch (e) {
      LoggerService.error('Version check failed', e);
    }
  }

  static bool _isUpdateAvailable(String current, String target) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> targetParts = target.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        // Major.Minor.Patch
        int c = i < currentParts.length ? currentParts[i] : 0;
        int t = i < targetParts.length ? targetParts[i] : 0;

        if (c < t) return true;
        if (c > t) return false;
      }
      return false; // Equal
    } catch (e) {
      LoggerService.error('Version parsing error', e);
      return false;
    }
  }

  static void _showUpdateDialog(BuildContext context, String url,
      bool isMandatory, String latestVersion) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => PopScope(
        canPop: !isMandatory,
        child: AlertDialog(
          title: Text(l.updateTitle),
          content: Text(
              '${l.updateAvailable(latestVersion)}${isMandatory ? "\n\n${l.updateMandatory}" : ""}'),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.updateLater),
              ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.updateUrlError)),
                    );
                  }
                }
              },
              child: Text(l.updateNow),
            ),
          ],
        ),
      ),
    );
  }
}


