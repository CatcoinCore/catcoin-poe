import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
// import '../providers/auth_provider.dart'; // Removed unused import
import 'social_missions_screen.dart';
import '../widgets/mission_card.dart';
import '../widgets/admin_gear.dart';
import 'package:cat_poe/l10n/app_localizations.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionProvider>().fetchMissions();
    });
  }

  Widget _buildCategoryButton(
      String title, IconData icon, Color color, String platform) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SocialMissionsScreen(
                platform: platform,
                title: title,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // final user = context.watch<AuthProvider>().user; // Removed unused user

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navRewards),
        actions: [
          const AdminGear(),
        ],
      ),
      body: Consumer<MissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.missions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(l.rewardsError(provider.error!)));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMissions(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.rewardsSocialTasks,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCategoryButton(
                          l.rewardsXTasks,
                          Icons.close,
                          Theme.of(context).colorScheme.onSurface,
                          'twitter'), // 'x' or 'twitter' handled in screen
                      const SizedBox(width: 12),
                      _buildCategoryButton(l.rewardsTelegramTasks, Icons.send,
                          const Color(0xFF0088cc), 'telegram'),
                      const SizedBox(width: 12),
                      _buildCategoryButton(l.rewardsDiscordTasks, Icons.discord,
                          const Color(0xFF5865F2), 'discord'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.rewardsAllMissions,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (provider.missions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l.rewardsNoMissions),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.missions.length,
                      itemBuilder: (context, index) {
                        return MissionCard(mission: provider.missions[index]);
                      },
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


