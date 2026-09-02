import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';
import '../models/balance_details.dart';
import '../models/payout.dart';
import '../widgets/admin_gear.dart';

class BalanceDetailScreen extends StatefulWidget {
  const BalanceDetailScreen({super.key});

  @override
  State<BalanceDetailScreen> createState() => _BalanceDetailScreenState();
}

class _BalanceDetailScreenState extends State<BalanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRewardFilter = 'ALL';

  // Track which tabs have been loaded to implement lazy loading
  final Set<int> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Only load the first tab on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTab(0);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTab(_tabController.index);
    }
  }

  void _loadTab(int index) {
    if (_loadedTabs.contains(index)) return; // Already loaded
    _loadedTabs.add(index);

    final provider = Provider.of<WalletProvider>(context, listen: false);
    switch (index) {
      case 0:
        provider.fetchBalanceDetails();
        break;
      case 1:
        provider.fetchEarningsHistory();
        break;
      case 2:
        provider.fetchPayoutHistory();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.balanceDetailTitle),
        actions: [
          const AdminGear(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18),
                  const SizedBox(width: 6),
                  Text(l.balanceSummary),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  Text(l.balanceEarnings),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payments, size: 18),
                  const SizedBox(width: 6),
                  Text(l.balancePayouts),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildEarningsTab(),
          _buildPayoutsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Tab
  // ---------------------------------------------------------------------------

  Widget _buildSummaryTab() {
    final l = AppLocalizations.of(context);
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.balanceDetails == null) {
          return _buildSummaryShimmer();
        }

        final details = provider.balanceDetails;
        if (details == null) {
          return Center(child: Text(l.balanceLoadError));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchBalanceDetails(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!details.globalWithdrawalEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.balanceWithdrawSoon,
                          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildTotalBalanceCard(details.totalBalance),
              const SizedBox(height: 16),
              _buildEarningsBreakdownCard(details),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalBalanceCard(double balance) {
    final l = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.balanceTotal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(l.balanceNotWithdrawable, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            Text(
              '${balance.toStringAsFixed(0)} Catoshi',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdownCard(BalanceDetails details) {
    final l = AppLocalizations.of(context);
    double mining = details.earningsBreakdown['MINING_BASE'] ?? 0;
    double referrals = details.earningsBreakdown['MINING_REFERRAL_BOOST'] ?? 0;
    double games = details.earningsBreakdown['GAME_REWARD'] ?? 0;
    double gameBoosts = details.earningsBreakdown['GAME_BOOST'] ?? 0;
    double specialBonus = details.earningsBreakdown['SPECIAL_BONUS'] ?? 0;

    double missions = 0;
    details.earningsBreakdown.forEach((key, value) {
      if (key == 'MISSION_COMPLETION' || key.startsWith('SOCIAL_')) {
        missions += value;
      }
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.pie_chart_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(l.balanceBreakdown, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildBreakdownItem(l.balanceMining, mining, 'MINING_BASE', details),
          _buildBreakdownItem(l.balanceReferral, referrals, 'MINING_REFERRAL_BOOST', details),
          _buildBreakdownItem(l.balanceMission, missions, 'MISSIONS_ALL', details),
          _buildBreakdownItem(l.balanceGame, games, 'GAME_REWARD', details),
          _buildBreakdownItem("Game Boosts Rewards", gameBoosts, 'GAME_BOOST', details),
          _buildBreakdownItem("Special Bonus", specialBonus, 'SPECIAL_BONUS', details),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double amount, String type, BalanceDetails details) {
    final l = AppLocalizations.of(context);
    final bool canWithdraw = _isWithdrawAllowed(type, details);
    final bool hasEnough = type == 'GAME_REWARD' ? amount >= details.gameWithdrawalThreshold : amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                Text('${amount.toStringAsFixed(0)} Catoshi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: (details.globalWithdrawalEnabled && canWithdraw && hasEnough) ? () => _handleWithdraw(type) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(80, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l.balanceWithdraw, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer Skeletons
  // ---------------------------------------------------------------------------

  Widget _buildSummaryShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _shimmerBox(height: 80, radius: 12),
        const SizedBox(height: 16),
        _shimmerBox(height: 320, radius: 12),
      ],
    );
  }

  Widget _buildListShimmer({int itemCount = 6}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _shimmerBox(height: 60, radius: 8),
      ),
    );
  }

  Widget _shimmerBox({required double height, double radius = 8}) {
    return _ShimmerBox(height: height, radius: radius);
  }

  // ---------------------------------------------------------------------------
  // Earnings Tab
  // ---------------------------------------------------------------------------

  Widget _buildEarningsTab() {
    final l = AppLocalizations.of(context);
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text("Filter:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'ALL',
                          'MINING_BASE',
                          'MINING_REFERRAL_BOOST',
                          'MISSION_COMPLETION',
                          'GAME_REWARD',
                          'GAME_BOOST',
                          'SPECIAL_BONUS'
                        ].map((type) {
                          final isSelected = _selectedRewardFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                type == 'ALL' ? 'All Types' : _getReadableType(type),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedRewardFilter = type;
                                  });
                                  provider.fetchEarningsHistory(rewardType: type);
                                }
                              },
                              selectedColor: Colors.orange,
                              checkmarkColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildHistoryList(provider, l),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryList(WalletProvider provider, AppLocalizations l) {
    if (provider.isLoading && provider.earningsHistory.isEmpty) {
      return _buildListShimmer();
    }

    if (provider.earningsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(l.balanceNoHistory, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchEarningsHistory(rewardType: _selectedRewardFilter),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.earningsHistory.length,
        itemBuilder: (context, index) {
          final entry = provider.earningsHistory[index];
          return _buildHistoryCard(entry);
        },
      ),
    );
  }

  Widget _buildHistoryCard(EarningsLedgerEntry entry) {
    final dateStr = DateFormat('MMM d, HH:mm').format(entry.createdAt.toLocal());
    final isNegative = entry.amount < 0;

    return ListTile(
      leading: Icon(
        isNegative ? Icons.outbox : Icons.add_circle,
        color: isNegative ? Colors.red : Colors.green,
      ),
      title: Text(_getReadableType(entry.rewardType)),
      subtitle: Text(entry.description ?? dateStr),
      trailing: Text(
        '${isNegative ? "" : "+"}${entry.amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isNegative ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Payouts Tab
  // ---------------------------------------------------------------------------

  Widget _buildPayoutsTab() {
    final l = AppLocalizations.of(context);
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.payouts.isEmpty) {
          return _buildListShimmer(itemCount: 4);
        }

        if (provider.payouts.isEmpty) {
          return Center(child: Text(l.balanceNoPayouts));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPayoutHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.payouts.length,
            itemBuilder: (context, index) {
              final payout = provider.payouts[index];
              return _buildPayoutCard(payout);
            },
          ),
        );
      },
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    final dateStr = DateFormat('MMM d, yyyy').format(payout.createdAt.toLocal());
    final isCompleted = payout.status == 'COMPLETED';
    final statusColor = isCompleted ? Colors.green : Colors.orange;
    final l = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('${payout.amountCat.toStringAsFixed(0)} ${l.dashboardCatoshi}'),
        subtitle: Text(l.payoutAddressTo(payout.catcoinAddress.length > 8 ? '${payout.catcoinAddress.substring(0, 8)}...' : payout.catcoinAddress)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payout.status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isWithdrawAllowed(String type, BalanceDetails details) {
    final mapping = {
      'MINING_BASE': 'mining',
      'MINING_REFERRAL_BOOST': 'referrals',
      'MISSION_COMPLETION': 'missions',
      'GAME_REWARD': 'games',
      'GAME_BOOST': 'game_boosts',
      'SPECIAL_BONUS': 'missions',
      'SOCIAL_X': 'missions',
      'SOCIAL_DISCORD': 'missions',
      'SOCIAL_TELEGRAM': 'missions',
      'MISSIONS_ALL': 'missions',
    };
    final key = mapping[type];
    return details.withdrawalPermissions[key] ?? false;
  }

  String _getReadableType(String type) {
    final l = AppLocalizations.of(context);
    switch (type) {
      case 'MINING_BASE': return l.balanceMining;
      case 'MINING_REFERRAL_BOOST': return l.balanceReferral;
      case 'MISSION_COMPLETION': return l.balanceMission;
      case 'GAME_REWARD': return l.balanceGame;
      case 'GAME_BOOST': return "Game Boost Earnings";
      case 'SPECIAL_BONUS': return "Special Bonus";
      case 'SOCIAL_X': return "X (Twitter) Rewards";
      case 'SOCIAL_DISCORD': return "Discord Rewards";
      case 'SOCIAL_TELEGRAM': return "Telegram Rewards";
      default: return type.replaceAll('_', ' ');
    }
  }

  void _handleWithdraw(String type) async {
    final l = AppLocalizations.of(context);
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final success = await provider.requestWithdrawal(type);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.balanceWithdrawSubmitted)),
      );
      _tabController.animateTo(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.rewardsError(provider.error ?? "Failed to request withdrawal"))),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Shimmer animation widget (no external package needed)
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: _animation.value * 0.12),
          ),
        );
      },
    );
  }
}
