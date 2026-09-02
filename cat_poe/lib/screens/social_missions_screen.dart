import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../widgets/mission_card.dart';
import '../widgets/admin_gear.dart';

class SocialMissionsScreen extends StatefulWidget {
  final String platform; // "twitter", "discord", "telegram"
  final String title;

  const SocialMissionsScreen({
    super.key,
    required this.platform,
    required this.title,
  });

  @override
  State<SocialMissionsScreen> createState() => _SocialMissionsScreenState();
}

class _SocialMissionsScreenState extends State<SocialMissionsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh missions on enter to ensure status is up to date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionProvider>().fetchMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          const AdminGear(),
        ],
      ),
      body: Consumer<MissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.missions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredMissions = provider.missions.where((m) {
            final icon = (m.icon ?? '').toLowerCase();
            final target = widget.platform.toLowerCase();
            if (target == 'twitter' || target == 'x') {
              return (icon.contains('twitter') || icon.contains('x')) &&
                  m.status != 'COMPLETED';
            }
            return icon.contains(target) && m.status != 'COMPLETED';
          }).toList();

          if (filteredMissions.isEmpty) {
            final l = AppLocalizations.of(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l.socialNoMissions(widget.title),
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMissions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMissions.length,
              itemBuilder: (context, index) {
                return MissionCard(mission: filteredMissions[index]);
              },
            ),
          );
        },
      ),
    );
  }
}


