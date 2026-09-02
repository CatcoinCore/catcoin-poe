import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class TelegramHelpDialog extends StatelessWidget {
  const TelegramHelpDialog({super.key});

  Future<void> _launchBot() async {
    final Uri url = Uri.parse('https://t.me/userinfobot');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch userinfobot');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.telegramHelpTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l.telegramHelpInstructions,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _launchBot,
              icon: const Icon(Icons.telegram),
              label: Text(l.telegramHelpBtnOpen),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088cc),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(l.telegramHelpQrLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/telegram_qr.png',
                    height: 180,
                    width: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                            child: Text(
                                l.telegramHelpQrError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 10))),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonOk),
        ),
      ],
    );
  }
}


