import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

/// Run monthly podium badge grants from the app (same as POST /v1/admin/leaderboard/award-monthly-podium).
class AdminLeaderboardAwardsScreen extends StatefulWidget {
  const AdminLeaderboardAwardsScreen({super.key});

  @override
  State<AdminLeaderboardAwardsScreen> createState() =>
      _AdminLeaderboardAwardsScreenState();
}

/// Matches backend `previous_completed_month_bounds` (UTC).
(int, int) previousCompletedYearMonthUtc() {
  final n = DateTime.now().toUtc();
  final first = DateTime.utc(n.year, n.month, 1);
  final prevEnd = first.subtract(const Duration(microseconds: 1));
  return (prevEnd.year, prevEnd.month);
}

class _AdminLeaderboardAwardsScreenState
    extends State<AdminLeaderboardAwardsScreen> {
  final _yearController = TextEditingController();
  late int _awardMonth;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    final (y, m) = previousCompletedYearMonthUtc();
    _yearController.text = y.toString();
    _awardMonth = m;
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _runAward() async {
    final year = int.tryParse(_yearController.text.trim());
    if (year == null || year < 2000 || year > 2100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid year (2000–2100).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final period =
        '$year-${_awardMonth.toString().padLeft(2, '0')}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Award monthly podium badges?'),
        content: Text(
          'Awards badges for UTC calendar month $period only. '
          'Global top 3, regional top 3 per active country, and game podiums. '
          'Users who already have a badge for that month are skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    try {
      final result = await provider.awardMonthlyPodium(
        year: year,
        month: _awardMonth,
      );
      if (!mounted) return;
      setState(() => _lastResult = result);
      final msg = result['message'] as String? ?? 'Done.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyDefaultMonth() {
    final (y, m) = previousCompletedYearMonthUtc();
    setState(() {
      _yearController.text = y.toString();
      _awardMonth = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard awards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Monthly podium badges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Writes UserBadge rows so winners see trophies under Leaderboard → Awards. '
            'Choose the UTC calendar month to award — only that month’s standings are used.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Award for month (UTC)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    hintText: 'e.g. 2026',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _awardMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var mm = 1; mm <= 12; mm++)
                      DropdownMenuItem(
                        value: mm,
                        child: Text('$mm — ${_monthName(mm)}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _awardMonth = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _applyDefaultMonth,
              child: const Text('Use last completed month (UTC)'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _runAward,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.emoji_events),
            label: const Text('Award monthly podium badges'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Last response',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _formatLastResult(_lastResult!),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (m >= 1 && m <= 12) ? names[m] : '';
  }

  String _formatLastResult(Map<String, dynamic> r) {
    final buf = StringBuffer();
    buf.writeln('period_year: ${r['period_year']}');
    buf.writeln('period_month: ${r['period_month']}');
    buf.writeln('message: ${r['message']}');
    buf.writeln(
      'global awarded: ${(r['awarded'] as List?)?.length ?? 0}, '
      'skipped: ${(r['skipped_existing'] as List?)?.length ?? 0}',
    );
    buf.writeln(
      'regional awarded: ${r['regional_awarded_count']}, '
      'skipped: ${r['regional_skipped_count']}',
    );
    buf.writeln(
      'games awarded: ${r['game_awarded_count']}, '
      'skipped: ${r['game_skipped_count']}',
    );
    return buf.toString().trim();
  }
}
