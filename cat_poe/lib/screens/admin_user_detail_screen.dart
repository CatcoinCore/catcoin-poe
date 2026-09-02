import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import 'admin_user_missions_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _isInitialLoading = true;
  bool _verifyingEmail = false;
  List<dynamic> _activityLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final service = AdminService(ApiService());
    
    await Future.wait([
      provider.fetchUserDetails(widget.user['id']),
      provider.fetchUserStats(widget.user['id']),
      _fetchLogs(service),
    ]);

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _fetchLogs(AdminService service) async {
    try {
      final logs = await service.getSuspiciousActivity(widget.user['id']);
      setState(() {
        _activityLogs = logs;
      });
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final user = provider.selectedUserDetails ?? widget.user;
    final stats = provider.selectedUserStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(user['username'] ?? 'User Detail'),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.selectedUserDetails == null
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("Failed to load user: ${provider.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                  const SizedBox(height: 8),
                  const Text("Note: If you get a 404, please ensure the backend is updated.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ))
            : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(user, isDark),
                  const SizedBox(height: 16),
                  _buildSocialCard(user, isDark),
                  const SizedBox(height: 16),
                  if (stats != null) _buildEarningsCard(stats, isDark),
                  const SizedBox(height: 16),
                  _buildPermissionCard(user, isDark),
                  const SizedBox(height: 16),
                  _buildFraudCard(user, isDark),
                  const SizedBox(height: 100), // Spacing for floating/bottom actions
                ],
              ),
            ),
      bottomNavigationBar: _isInitialLoading ? null : _buildBottomActions(user),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text("Quick Actions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            Row(
              children: [
                Expanded(child: _buildActionButton("Reset Mining", Icons.timer_outlined, Colors.orange, () => _confirmReset(user['id'], "Mining"))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton("Reset Missions", Icons.assignment_late_outlined, Colors.red, () => _confirmReset(user['id'], "Missions"))),
              ],
            ),
            if (user['email_verified'] != true) ...[
              const SizedBox(height: 8),
              _buildActionButton(
                _verifyingEmail ? "Verifying…" : "Verify email",
                Icons.mark_email_read_outlined,
                Colors.green,
                () => _confirmVerifyEmail(user['id'], user['email']?.toString()),
                enabled: !_verifyingEmail,
              ),
            ],
            const SizedBox(height: 8),
            _buildActionButton("Manage Specific Missions", Icons.assignment_outlined, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserMissionsScreen(userId: user['id'], username: user['username'])));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(user['username']?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['display_name'] ?? 'No Display Name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user['email'] ?? 'No Email', style: TextStyle(color: Colors.grey.shade600)),
                      Text("ID: ${user['id']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                if (user['is_suspicious'] == true)
                  const Icon(Icons.warning, color: Colors.red, size: 32),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.person_outline, "Username", user['username'] ?? 'N/A'),
            _buildEmailVerificationRow(user),
            _buildInfoRow(Icons.qr_code, "Referral Code", user['referral_code'] ?? 'None'),
            _buildInfoRow(Icons.account_balance_wallet_outlined, "Catoshi Balance", NumberFormat.decimalPattern().format(user['balance'] ?? 0)),
            _buildInfoRow(Icons.payments_outlined, "Total Earned", NumberFormat.decimalPattern().format(user['total_earnings'] ?? 0)),
            _buildInfoRow(Icons.person_add_alt, "Referred By", user['referred_by'] ?? 'None'),
            _buildInfoRow(Icons.calendar_today, "Joined", _formatDate(user['created_at'])),
            _buildInfoRow(Icons.public, "Country", _formatCountry(user)),
            _buildInfoRow(Icons.devices, "Device ID", user['device_id'] ?? 'N/A'),
            _buildAgeSignalRow(user),
          ],
        ),
      ),
    );
  }

  /// Read-only Play Age Signals badge + override menu. The platform-driven
  /// value lands via the client SDK (not wired yet — see
  /// docs/play_age_signals_integration.md); the menu lets support set or
  /// clear it manually in the meantime.
  Widget _buildAgeSignalRow(Map<String, dynamic> user) {
    final raw = user['age_signal_status'] as String?;
    final status = (raw == null || raw.isEmpty) ? 'not_checked' : raw;
    final (label, color) = _ageSignalCopy(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          const Text(
            "Age signal:",
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Override age signal (Play Age Signals API)',
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) =>
                _setAgeSignal(user['id'] as String, value),
            itemBuilder: (ctx) => const [
              PopupMenuItem<String>(value: 'verified', child: Text('Mark verified')),
              PopupMenuItem<String>(value: 'not_required', child: Text('Mark not required')),
              PopupMenuItem<String>(value: 'pending', child: Text('Mark pending')),
              PopupMenuItem<String>(value: 'not_verified', child: Text('Mark not verified')),
              PopupMenuDivider(),
              PopupMenuItem<String>(value: '', child: Text('Clear (reset to not_checked)')),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _ageSignalCopy(String status) {
    switch (status) {
      case 'verified':
        return ('verified', Colors.green);
      case 'not_required':
        return ('not required', Colors.blueGrey);
      case 'pending':
        return ('pending', Colors.orange);
      case 'not_verified':
        return ('not verified', Colors.red);
      case 'not_checked':
      default:
        return ('not checked', Colors.grey);
    }
  }

  Future<void> _setAgeSignal(String userId, String value) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await provider.updateUser(userId, {'age_signal_status': value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value.isEmpty
              ? 'Age signal cleared.'
              : 'Age signal set to "$value".'),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  String _formatCountry(Map<String, dynamic> user) {
    final code = user['country'] ?? 'N/A';
    final source = user['country_source'];
    final ip = user['ip_address'];
    
    String detail = code;
    if (source != null) {
      detail += " ($source)";
    } else {
      detail += " (Pending Sync)";
    }
    
    if (ip != null && ip.isNotEmpty && ip != 'null') {
      detail += " [IP: $ip]";
    }
    
    return detail;
  }

  Widget _buildSocialCard(Map<String, dynamic> user, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Social Identities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSocialRow("Discord", user['discord_id'], user['discord_id_verified'], user['discord_id_old']),
            _buildSocialRow("Telegram", user['telegram_id'], user['telegram_id_verified'], user['telegram_id_old']),
            _buildSocialRow("X (Twitter)", user['x_id'], user['x_id_verified'], user['x_id_old']),
            _buildSocialRow("Facebook", user['facebook_id'], user['facebook_id_verified'], user['facebook_id_old']),
            _buildSocialRow("WhatsApp", user['whatsapp_id'], user['whatsapp_id_verified'], user['whatsapp_id_old']),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow(String platform, String? id, bool? verified, String? oldId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text(platform, style: const TextStyle(fontWeight: FontWeight.w500))),
              Expanded(child: Text(id ?? 'Not set', style: TextStyle(color: id == null ? Colors.grey : null))),
              if (verified == true)
                const Icon(Icons.verified, color: Colors.blue, size: 16)
              else if (id != null)
                const Icon(Icons.pending, color: Colors.orange, size: 16),
            ],
          ),
          if (oldId != null && oldId != id)
            Padding(
              padding: const EdgeInsets.only(left: 80.0, top: 2),
              child: Text("Previous: $oldId", style: const TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(Map<String, dynamic> stats, bool isDark) {
    final breakdown = stats['earnings_breakdown'] as Map<String, dynamic>;
    final total = stats['balance'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Earnings Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${NumberFormat.decimalPattern().format(total)} Catoshi",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text("Current Balance", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildEarningsRow("Mining (Base)", breakdown['MINING_BASE'], Colors.blue, isDark: isDark),
            _buildEarningsRow("Mining (Referral)", breakdown['MINING_REFERRAL_BOOST'], Colors.lightBlue, isDark: isDark),
            _buildEarningsRow("Missions", breakdown['MISSION_COMPLETION'], Colors.green, isDark: isDark),
            _buildEarningsRow("Social Rewards", 
              (breakdown['SOCIAL_X'] ?? 0) + (breakdown['SOCIAL_DISCORD'] ?? 0) + (breakdown['SOCIAL_TELEGRAM'] ?? 0) + (breakdown['SOCIAL_FACEBOOK'] ?? 0), 
              Colors.purple, isDark: isDark),
            _buildEarningsRow("Referral Bonus", breakdown['REFERRAL_SIGNUP_BONUS'], Colors.orange, isDark: isDark),
            _buildEarningsRow("Game Rewards", breakdown['GAME_REWARD'], Colors.amber, isDark: isDark),
            _buildEarningsRow("Game Boosts", breakdown['GAME_BOOST'], Colors.purpleAccent, isDark: isDark),
            _buildEarningsRow("Special Bonus", breakdown['SPECIAL_BONUS'], Colors.orangeAccent, isDark: isDark),
            _buildEarningsRow("Airdrops", breakdown['AIRDROP'], Colors.teal, isDark: isDark),
            const Divider(),
            _buildEarningsRow("Withdrawals", breakdown['WITHDRAWAL'], Colors.red, isNegative: true, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> user, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Withdrawal Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPermissionToggle("Mining", user['can_withdraw_mining'] ?? false, (val) => _togglePermission(user['id'], 'can_withdraw_mining', val)),
            _buildPermissionToggle("Referrals", user['can_withdraw_referrals'] ?? false, (val) => _togglePermission(user['id'], 'can_withdraw_referrals', val)),
            _buildPermissionToggle("Missions", user['can_withdraw_missions'] ?? false, (val) => _togglePermission(user['id'], 'can_withdraw_missions', val)),
            _buildPermissionToggle("Games", user['can_withdraw_games'] ?? false, (val) => _togglePermission(user['id'], 'can_withdraw_games', val)),
            _buildPermissionToggle("Game Boosts", user['can_withdraw_game_boosts'] ?? false, (val) => _togglePermission(user['id'], 'can_withdraw_game_boosts', val)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionToggle(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.orange,
    );
  }

  Future<void> _togglePermission(String userId, String field, bool value) async {
    try {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.updateUser(userId, {field: value});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Widget _buildEarningsRow(String label, dynamic value, Color color, {bool isNegative = false, required bool isDark}) {
    final val = (value ?? 0.0).toDouble();
    if (val == 0 && !isNegative) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            "${isNegative ? '-' : ''}${NumberFormat.decimalPattern().format(val)} Catoshi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : (isDark ? Colors.green.shade300 : Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudCard(Map<String, dynamic> user, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message:
                      'Mining/referral activity is unrelated. Here you review stored fraud events one row at a time.',
                  child: const Text("Fraud reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (user['is_suspicious'] == true)
                  ElevatedButton(
                    onPressed: () => _confirmUnmarkSuspicious(context, user['id'], user['username']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("Clear account flag"),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_activityLogs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No suspicious activity detected.")))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activityLogs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, index) {
                  final log = _activityLogs[index];
                  final isResolved = log['is_resolved'] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning, color: isResolved ? Colors.grey : Colors.orange),
                    title: Text(log['activity_type'] ?? 'Unknown', style: TextStyle(decoration: isResolved ? TextDecoration.lineThrough : null)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['evidence'] ?? ''),
                        if (log['related_user_username'] != null)
                          Text("Linked: ${log['related_user_username']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: isResolved
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            tooltip: 'Resolve this review item (marks this event only)',
                            icon: const Icon(Icons.check, color: Colors.blue),
                            onPressed: () => _resolveLog(log['id']),
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildEmailVerificationRow(Map<String, dynamic> user) {
    final verified = user['email_verified'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(verified ? Icons.verified : Icons.mark_email_unread_outlined, size: 16, color: verified ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          const Text("Email verified:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              verified ? "Yes" : "No",
              style: TextStyle(fontWeight: FontWeight.w600, color: verified ? Colors.green.shade700 : Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmVerifyEmail(String userId, String? email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify email for this user?'),
        content: Text(
          email != null && email.isNotEmpty
              ? 'Mark $email as verified without a code. Pending signup bonuses may be granted if applicable.'
              : 'Mark this account as email-verified without a code. Pending signup bonuses may be granted if applicable.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _verifyingEmail = true);
    try {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      await provider.updateUser(userId, {'email_verified': true});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email marked verified')));
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _verifyingEmail = false);
    }
  }

  Widget _buildInfoRow(IconData? icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _resolveLog(String logId) async {
    try {
      await ApiService().post('/v1/admin/suspicious-activity/$logId/resolve');
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmUnmarkSuspicious(BuildContext context, String userId, String? username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear suspicious account flag?'),
        content: Text(
          'This only removes the red account-level flag. Open fraud-review rows stay open until you '
          'tap the check on each line. ${username ?? "This user"} can be flagged again if new issues appear.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear flag', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ApiService().post('/v1/admin/users/$userId/unmark-suspicious');
        _loadData();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _confirmReset(String userId, String action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset $action?'),
        content: Text('This will clear all $action progress for this user. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      if (action == "Missions") {
        await provider.resetUserMissions(userId);
      } else {
        await provider.resetUserMining(userId);
      }
      _loadData();
    }
  }
}

