import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';
import '../models/payout.dart';
import '../widgets/admin_gear.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchPayoutHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.payoutHistoryScreenTitle),
        actions: [
          const AdminGear(),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.payouts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(l.rewardsError(provider.error ?? '')));
          }

          if (provider.payouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l.payoutNoHistory,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
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
      ),
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    final dateStr =
        DateFormat('MMM d, yyyy HH:mm').format(payout.createdAt.toLocal());
    final isCompleted = payout.status == 'COMPLETED';
    final statusColor = isCompleted ? Colors.green : Colors.orange;

    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${payout.amountCat.toStringAsFixed(0)} ${l.dashboardCatoshi}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    payout.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.payoutAddressTo(payout.catcoinAddress),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (payout.txid != null)
                   Row(
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        l.payoutViewTx,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


