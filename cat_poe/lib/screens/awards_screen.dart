import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';

import '../widgets/awards_hub_body.dart';

/// Full-screen Awards (same hub as Leaderboard → Awards tab).
class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.awardsTitle),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: const AwardsHubBody(),
    );
  }
}
