import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'games_screen.dart';
import 'referral_screen.dart';
import 'updates_screen.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/game_provider.dart';
import '../providers/mining_provider.dart';
import '../utils/games_screen_eligibility.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GamesScreen(),
    const LeaderboardScreen(),
    const UpdatesScreen(),
    const ReferralScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // Navigate only if mining is active or we're on the dashboard
    final isMining = context.read<MiningProvider>().isMining;
    if (!isMining && index != 0) {
      // Optinally show a hint, but the overlay will already handle feedback
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<MiningProvider>(
      builder: (context, miningProvider, child) {
        // Redirection logic: if mining stops while on another tab, go to dashboard
        if (!miningProvider.isMining && _selectedIndex != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedIndex = 0;
            });
          });
        }

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Opacity(
            opacity: miningProvider.isMining ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !miningProvider.isMining,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed, // Needed for >3 items
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: l.navHome,
                  ),
                  BottomNavigationBarItem(
                    icon: Consumer2<GameProvider, AdminProvider>(
                      builder: (context, gameProvider, adminProvider, child) {
                        final playableCount = visiblePlayableGamesCount(
                          config: adminProvider.config,
                          statusMap: gameProvider.statusMap,
                        );
                        if (playableCount == 0) return const Icon(Icons.games);
                        return Badge(
                          label: Text(playableCount.toString()),
                          child: const Icon(Icons.games),
                        );
                      },
                    ),
                    label: l.navGames,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.leaderboard),
                    label: l.navLeaders,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.campaign),
                    label: l.navUpdates, // we need to add this to localizations
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people),
                    label: l.referralsTitle,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person),
                    label: l.navProfile,
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.orange,
                onTap: _onItemTapped,
              ),
            ),
          ),
        );
      },
    );
  }
}
