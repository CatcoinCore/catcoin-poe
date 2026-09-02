import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/leaderboard_entry.dart';

class TopReferredMinersCard extends StatefulWidget {
  const TopReferredMinersCard({super.key});

  @override
  State<TopReferredMinersCard> createState() => _TopReferredMinersCardState();
}

class _TopReferredMinersCardState extends State<TopReferredMinersCard> {
  List<LeaderboardEntry> _miners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMiners();
  }

  Future<void> _fetchMiners() async {
    try {
      final data = await ApiService().getReferredLeaderboard(limit: 10);
      if (mounted) {
        setState(() {
          _miners = data.map((e) => LeaderboardEntry.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';
    int offset = 127397;
    List<int> runes =
        countryCode.toUpperCase().codeUnits.map((u) => u + offset).toList();
    return String.fromCharCodes(runes);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  'Top 10 Active Referred Miners',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading miners: \$_error',
                      style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (_miners.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No active referred miners yet.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _miners.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final miner = _miners[index];
                  // Use ID/Username as requested, ID is first part of username or display name
                  final displayName = miner.displayName?.isNotEmpty == true
                      ? miner.displayName!
                      : miner.username;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        '#\${index + 1}',
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(_getFlagEmoji(miner.country),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${miner.balance.toStringAsFixed(0)} CAT',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


