import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';

class AdminUserMissionsScreen extends StatefulWidget {
  final String userId;
  final String username;

  const AdminUserMissionsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AdminUserMissionsScreen> createState() =>
      _AdminUserMissionsScreenState();
}

class _AdminUserMissionsScreenState extends State<AdminUserMissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUserMissions(widget.userId);
    });
  }

  Future<void> _resetMission(String missionCode, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Mission: $title?'),
        content: const Text(
            'This will clear progress and revoke rewards for this specific mission. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context
          .read<AdminProvider>()
          .resetIndividualMission(widget.userId, missionCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset mission $title success')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Missions: ${widget.username}'),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userMissions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.userMissions.isEmpty) {
            return const Center(child: Text("No missions found."));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchUserMissions(widget.userId),
            child: ListView.builder(
              itemCount: provider.userMissions.length,
              itemBuilder: (context, index) {
                final mission = provider.userMissions[index];
                final bool isCompleted = mission.status == 'COMPLETED';
                final bool isPending = mission.status == 'PENDING';
                final bool hasProgress = isCompleted || isPending;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      _getIconData(mission.icon),
                      color: isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(mission.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission.code,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        Text("Reward: ${NumberFormat.decimalPattern().format(mission.rewardAmount)} Catoshi",
                            style: TextStyle(
                                fontSize: 11, color: isDark ? Colors.green.shade300 : Colors.green.shade700, fontWeight: FontWeight.bold)),
                        if (mission.status != null)
                          Chip(
                            label: Text(mission.status!),
                            backgroundColor: isCompleted
                                ? (isDark ? Colors.green.shade900 : Colors.green.shade100)
                                : (isPending
                                    ? (isDark ? Colors.orange.shade900 : Colors.orange.shade100)
                                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    trailing: hasProgress
                        ? IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.orange),
                            tooltip: "Reset Progress",
                            onPressed: () =>
                                _resetMission(mission.code, mission.title),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'discord':
        return Icons.discord;
      case 'twitter':
      case 'x':
        return Icons.close;
      case 'telegram':
        return Icons.send;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.play_arrow;
      default:
        return Icons.star;
    }
  }
}


