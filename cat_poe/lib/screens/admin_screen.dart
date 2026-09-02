import 'package:flutter/material.dart';
import 'admin_version_control.dart';
import 'admin_bot_config.dart';
import 'admin_mining_screen.dart';
import 'admin_ads_screen.dart';
import 'admin_wallet_screen.dart';
import 'admin_missions_screen.dart';
import 'admin_users_screen.dart';
import 'admin_x_post_screen.dart';
import 'admin_games_screen.dart';
import 'admin_announcement_screen.dart';
import 'admin_leaderboard_awards_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNavTile(
            title: 'Missions',
            subtitle: 'Manage missions list, create/edit',
            icon: Icons.list_alt,
            screen: const AdminMissionsScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Users',
            subtitle: 'View users, reset progress',
            icon: Icons.people,
            screen: const AdminUsersScreen(),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text('Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildNavTile(
            title: 'Mining Settings',
            subtitle: 'Hashrate, duration, referrals',
            icon: Icons.monitor_heart,
            screen: const AdminMiningScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Bot Configuration',
            subtitle: 'Discord, Telegram, X, Verification',
            icon: Icons.smart_toy,
            screen: const AdminBotConfigScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Ad Configuration',
            subtitle: 'Ad Unit IDs, Requirement Toggles',
            icon: Icons.monetization_on,
            screen: const AdminAdsScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Wallet Features',
            subtitle: 'Holding days, Explorer API',
            icon: Icons.account_balance_wallet,
            screen: const AdminWalletScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Games Visibility',
            subtitle: 'Toggle Runner, Miner, TicTacToe',
            icon: Icons.videogame_asset,
            screen: const AdminGamesScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Version Control',
            subtitle: 'Versions and Update URLs',
            icon: Icons.system_update,
            screen: const AdminVersionControlScreen(),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text('Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildNavTile(
            title: 'Post to X',
            subtitle: 'Tweet from official account',
            icon: Icons.chat_bubble_outline,
            screen: const AdminXPostScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Global Announcement',
            subtitle: 'Set a global dashboard message',
            icon: Icons.announcement,
            screen: const AdminAnnouncementScreen(),
          ),
          const SizedBox(height: 8),
          _buildNavTile(
            title: 'Leaderboard awards',
            subtitle: 'Grant monthly podium badges (global & regional)',
            icon: Icons.emoji_events,
            screen: const AdminLeaderboardAwardsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: Colors.orange),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}


