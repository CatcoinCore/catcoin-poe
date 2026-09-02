import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/mission.dart';

class AdminMissionsScreen extends StatefulWidget {
  const AdminMissionsScreen({super.key});

  @override
  State<AdminMissionsScreen> createState() => _AdminMissionsScreenState();
}

class _AdminMissionsScreenState extends State<AdminMissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchMissions();
    });
  }

  Widget _getIconWidget(BuildContext context, String? iconName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (iconName?.toLowerCase()) {
      case 'discord':
        return const Icon(Icons.discord, color: Color(0xFF5865F2));
      case 'twitter':
      case 'x':
        return Icon(Icons.close, color: isDark ? Colors.white : Colors.black);
      case 'telegram':
        return const Icon(Icons.send, color: Color(0xFF0088cc));
      case 'facebook':
        return const Icon(Icons.facebook, color: Color(0xFF1877F2));
      case 'youtube':
        return const Icon(Icons.play_arrow, color: Color(0xFFFF0000));
      default:
        return Icon(iconName == 'discord' ? Icons.videogame_asset : Icons.star,
            color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMissionDialog(context),
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading && provider.missions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.missions.length,
              itemBuilder: (context, index) {
                final mission = provider.missions[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Opacity(
                        opacity: mission.isActive ? 1.0 : 0.5,
                        child: _getIconWidget(context, mission.icon)),
                    title: Text(
                      mission.title,
                      style: TextStyle(
                        decoration: mission.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                        '${mission.rewardAmount.toStringAsFixed(0)} Catoshi - ${mission.type}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showMissionDialog(context, mission: mission),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Mission?'),
                                content: const Text(
                                    'Are you sure you want to delete this mission?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              await provider.deleteMission(mission.code);
                            }
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

  void _showMissionDialog(BuildContext context, {Mission? mission}) {
    final isEditing = mission != null;
    final codeController = TextEditingController(text: mission?.code ?? '');
    final titleController = TextEditingController(text: mission?.title ?? '');
    final descController =
        TextEditingController(text: mission?.description ?? '');
    final linkController = TextEditingController(text: mission?.link ?? '');
    final rewardController = TextEditingController(
        text: mission?.rewardAmount.toStringAsFixed(0) ?? '100');
    String iconName = mission?.icon ?? 'other';
    String type = mission?.type ?? 'SOCIAL';
    bool isActive = mission?.isActive ?? true;

    final iconOptions = [
      'discord',
      'twitter',
      'telegram',
      'facebook',
      'youtube',
      'other'
    ];
    if (!iconOptions.contains(iconName)) {
      iconName = 'other';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Mission' : 'New Mission'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditing)
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                        helperText: 'Default: 100000 catoshi'),
                  ),
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: descController,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                TextField(
                    controller: linkController,
                    decoration: const InputDecoration(labelText: 'Link (URL)')),
                DropdownButtonFormField<String>(
                  initialValue: iconName,
                  items: iconOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => iconName = val!,
                  decoration: const InputDecoration(labelText: 'Icon'),
                ),
                TextField(
                  controller: rewardController,
                  decoration:
                      const InputDecoration(labelText: 'Reward (Catoshi)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: ['SOCIAL', 'AD', 'OTHER']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => type = val!,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) {
                    setState(() {
                      isActive = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleController.text,
                  'description': descController.text,
                  'link': linkController.text,
                  'icon': iconName,
                  'reward_amount':
                      double.tryParse(rewardController.text) ?? 0.0,
                  'type': type,
                  'is_active': isActive,
                };

                final provider =
                    Provider.of<AdminProvider>(context, listen: false);
                if (isEditing) {
                  await provider.updateMission(mission.code, data);
                } else {
                  await provider.createMission(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}


