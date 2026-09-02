import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/mining_provider.dart';
import '../widgets/admin_gear.dart';
import '../services/api_service.dart';
import '../models/referral_bonus.dart';
import 'referral_bonus_detail_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

String _fmtDate(DateTime dt) {
  final l = dt.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

/// Matches server default `REFERRAL_BONUS_CATOSHI` when the user has no referral rows yet.
const int _kDefaultMilestoneBonusCatoshi = 10000000;

String _formatCatoshiAmount(int amount) {
  return NumberFormat.decimalPattern().format(amount);
}

Widget _referralStatusChip(AppLocalizations l, String status) {
  final s = status.toLowerCase();
  Color bg;
  Color fg = Colors.white;
  String label;
  switch (s) {
    case 'eligible':
      bg = Colors.green.shade600;
      label = l.referralBonusStateEligible;
      break;
    case 'rewarded':
      bg = Colors.blue.shade700;
      label = l.referralBonusStateRewarded;
      break;
    case 'under_review':
      bg = Colors.purple.shade600;
      label = l.referralBonusStateUnderReview;
      break;
    case 'rejected':
      bg = Colors.red.shade700;
      label = l.referralBonusStateRejected;
      break;
    default:
      bg = Colors.grey.shade600;
      label = l.referralBonusStatePending;
  }
  return Chip(
    label: Text(label, style: TextStyle(color: fg, fontSize: 11)),
    backgroundColor: bg,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ApiService _api = ApiService();
  List<ReferralBonusListItem> _bonusItems = [];
  bool _bonusLoading = false;
  String? _bonusError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MiningProvider>(context, listen: false).fetchStats();
      _loadReferralBonuses();
    });
  }

  Future<void> _loadReferralBonuses() async {
    setState(() {
      _bonusLoading = true;
      _bonusError = null;
    });
    try {
      final raw = await _api.get('/v1/referrals');
      final list = (raw['items'] as List<dynamic>? ?? [])
          .map((e) => ReferralBonusListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _bonusItems = list;
        _bonusLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bonusError = e.toString();
        _bonusLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final miningProvider = Provider.of<MiningProvider>(context);
    final l = AppLocalizations.of(context);
    final user = authProvider.user;
    final hasReferrer = (user?.referredBy?.trim().isNotEmpty ?? false) ||
        (user?.referredByDisplayName?.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.referralsTitle),
        actions: [
          const AdminGear(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await miningProvider.fetchStats();
          await _loadReferralBonuses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Referred by card
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.referralsInvitedBy,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.orange)),
                            const SizedBox(height: 4),
                            Text(
                              hasReferrer
                                  ? (user?.referredByDisplayName ??
                                      user?.referredBy ??
                                      l.referralsNoOneYet)
                                  : l.referralsNoOneYet,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (hasReferrer &&
                                user != null &&
                                (user.referredBy?.trim().isNotEmpty ?? false) &&
                                (user.referredByDisplayName
                                        ?.trim()
                                        .isNotEmpty ??
                                    false) &&
                                user.referredBy!.trim() !=
                                    user.referredByDisplayName!.trim())
                              Text(
                                user.referredBy!.trim(),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      if (!hasReferrer)
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l.commonAdd),
                          onPressed: () => _showEditReferralDialog(context),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Referral Code Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(l.referralsYourCode,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.referralCode ?? l.commonLoading,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: user?.referralCode != null
                                ? () {
                                    Clipboard.setData(ClipboardData(
                                        text: user!.referralCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l.referralsCopied)),
                                    );
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            color: Colors.orange,
                            onPressed: user?.referralCode != null
                                ? () {
                                    SharePlus.instance.share(
                                      ShareParams(
                                        text: l.referralsShareMessage(
                                            user!.referralCode),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Removed boost explanation container

              const SizedBox(height: 20),

              // Stats Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.people,
                                  color: Colors.blue, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                '${miningProvider.stats?.availableReferrals.length ?? 0}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(l.referralsTotal,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                '${miningProvider.stats?.availableReferrals.where((r) => r.isActive).length ?? 0}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(l.referralsActiveLast24h,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.flash_on,
                                  color: Colors.orange, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                miningProvider.stats?.referralBoostPercentage
                                        .toStringAsFixed(1) ??
                                    "0.0",
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(l.referralsBoostPercentage,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              if ((miningProvider.stats?.availableReferrals.length ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton.icon(
                    icon: miningProvider.pingReferralsLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(l.referralsPingAll),
                    onPressed: miningProvider.pingReferralsLoading
                        ? null
                        : () => _confirmPingAllReferrals(context, miningProvider, l),
                  ),
                ),
              Text(
                l.referralMilestoneBonusTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l.referralMilestoneBonusSubtitle(
                  _formatCatoshiAmount(
                    _bonusItems.isNotEmpty
                        ? _bonusItems.first.bonusAmountCatoshi
                        : (Provider.of<AdminProvider>(context).config
                                    ?.referralMilestoneBonusCatoshi ??
                                _kDefaultMilestoneBonusCatoshi),
                  ),
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),

              // Referral milestone bonus list
              if (_bonusLoading && _bonusItems.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_bonusError != null && _bonusItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_bonusError!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              else if (_bonusItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.person_add, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(l.referralsNoReferrals,
                              style:
                                  const TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(l.referralsSharePrompt,
                              style:
                                  const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._bonusItems.map((referral) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        child: Icon(Icons.card_giftcard, color: Colors.white),
                      ),
                      title: Text(referral.refereeName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.referralBonusDatesLine(
                              _fmtDate(referral.refereeJoinedAt),
                              _fmtDate(referral.referredAt),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.referralBonusListAmount(
                              _formatCatoshiAmount(referral.bonusAmountCatoshi),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (referral.conditionsMetCount < 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l.referralBonusConditionsProgress(
                                  referral.conditionsMetCount.toString(),
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: _referralStatusChip(l, referral.bonusStatus),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (ctx) => ReferralBonusDetailScreen(
                              referralId: referral.referralId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPingAllReferrals(
    BuildContext context,
    MiningProvider miningProvider,
    AppLocalizations l,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.referralsPingConfirmTitle),
        content: Text(l.referralsPingConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ping'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final stats = await miningProvider.pingAllReferrals();
      if (!context.mounted) return;
      final pinged = (stats['pinged'] as num?)?.toInt() ?? 0;
      final skipped = (stats['skipped'] as num?)?.toInt() ?? 0;
      final failed = (stats['failed'] as num?)?.toInt() ?? 0;
      final total = (stats['total_targets'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.referralsPingResult(pinged, skipped, failed, total)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.commonError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditReferralDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final u = auth.user;
    final hasReferrer = (u?.referredBy?.trim().isNotEmpty ?? false) ||
        (u?.referredByDisplayName?.trim().isNotEmpty ?? false);
    if (hasReferrer) return;

    final controller = TextEditingController(text: u?.referredBy);
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.referralsEnterInviterCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.referralsInviterCodeInstruction,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l.referralsInviterCodeLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              
              Navigator.pop(ctx);
              
              try {
                await Provider.of<AuthProvider>(context, listen: false).updateReferredBy(code);
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.referralsInviterCodeUpdated), backgroundColor: Colors.green),
                );
                // Refresh stats to ensure their boost updates instantly
                Provider.of<MiningProvider>(context, listen: false).fetchStats();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l.commonError}: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
  }
}


