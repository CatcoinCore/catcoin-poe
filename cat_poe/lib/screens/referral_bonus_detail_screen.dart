import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import '../models/referral_bonus.dart';
import '../services/api_service.dart';

class ReferralBonusDetailScreen extends StatefulWidget {
  final String referralId;

  const ReferralBonusDetailScreen({super.key, required this.referralId});

  @override
  State<ReferralBonusDetailScreen> createState() =>
      _ReferralBonusDetailScreenState();
}

class _ReferralBonusDetailScreenState extends State<ReferralBonusDetailScreen> {
  final ApiService _api = ApiService();
  ReferralBonusDetail? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.get('/v1/referrals/${widget.referralId}');
      if (!mounted) return;
      setState(() {
        _detail = ReferralBonusDetail.fromJson(raw as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _statusLine(AppLocalizations l, String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return l.referralBonusStatePending;
      case 'eligible':
        return l.referralBonusStateEligible;
      case 'rewarded':
        return l.referralBonusStateRewarded;
      case 'under_review':
        return l.referralBonusStateUnderReview;
      case 'rejected':
        return l.referralBonusStateRejected;
      default:
        return s;
    }
  }

  Widget _condIcon(bool met, int current) {
    if (met) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }
    if (current > 0) {
      return const Icon(Icons.schedule, color: Colors.orange, size: 22);
    }
    return Icon(Icons.highlight_off, color: Colors.grey.shade500, size: 22);
  }

  Widget _progressBar(double ratio) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: ratio.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.referralBonusDetailAppTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(l),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_loading && _detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _detail == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        ],
      );
    }
    final d = _detail!;
    final bonusAmt = d.bonusAmountCatoshi;

    double ratio(int cur, int req) =>
        req <= 0 ? 0.0 : (cur / req).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          d.refereeName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          d.refereeUserId,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          l.referralBonusDatesLine(
            _shortDate(d.refereeJoinedAt),
            _shortDate(d.referredAt),
          ),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        Text(
          l.referralBonusStatusHeading,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          _statusLine(l, d.bonusStatus),
          style: TextStyle(
            fontSize: 16,
            color: d.bonusStatus.toLowerCase() == 'rewarded'
                ? Colors.green.shade700
                : null,
          ),
        ),
        const Divider(height: 28),
        _checklistRow(
          label: l.referralBonusConditionMinedDays,
          icon: _condIcon(d.minedDays.met, d.minedDays.current),
          value: '${d.minedDays.current} / ${d.minedDays.required}',
          bar: _progressBar(ratio(d.minedDays.current, d.minedDays.required)),
        ),
        const SizedBox(height: 16),
        _checklistRow(
          label: l.referralBonusConditionMiningReward,
          icon: _condIcon(d.miningReward.met, d.miningReward.currentCatoshi),
          value:
              '${d.miningReward.currentCatoshi} / ${d.miningReward.requiredCatoshi} catoshi',
          bar: _progressBar(
              ratio(d.miningReward.currentCatoshi, d.miningReward.requiredCatoshi)),
        ),
        const SizedBox(height: 16),
        _checklistRow(
          label: l.referralBonusConditionGameReward,
          icon: _condIcon(d.gameReward.met, d.gameReward.currentCatoshi),
          value:
              '${d.gameReward.currentCatoshi} / ${d.gameReward.requiredCatoshi} catoshi',
          bar: _progressBar(
              ratio(d.gameReward.currentCatoshi, d.gameReward.requiredCatoshi)),
        ),
        const SizedBox(height: 24),
        Text(
          l.referralBonusRewardForReferrer(
            NumberFormat.decimalPattern().format(bonusAmt),
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          l.referralBonusRewardAmountNote,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        if (d.bonusAwardedAt != null)
          Text(
            l.referralBonusRewardCredited(
              NumberFormat.decimalPattern().format(bonusAmt),
            ),
            style: TextStyle(color: Colors.green.shade800),
          )
        else ...[
          Text(
            l.referralBonusConditionsProgress(d.conditionsMetCount.toString()),
          ),
        ],
      ],
    );
  }

  String _shortDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  Widget _checklistRow({
    required String label,
    required Widget icon,
    required String value,
    required Widget bar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  bar,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
