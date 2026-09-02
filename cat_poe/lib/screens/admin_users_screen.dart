import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool? _isSuspiciousFilter; // null = All, true = Suspicious, false = Safe
  bool? _isAdminFilter; // null = All, true = Admin, false = User
  /// Matches backend `activity_status`: all | active | inactive (24h last_active_at).
  String _activityStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUsers();
    });
  }

  void _refreshUsers({bool loadMore = false}) {
    Provider.of<AdminProvider>(context, listen: false).fetchUsers(
      search: _searchController.text,
      filterSuspicious: _isSuspiciousFilter,
      filterAdmin: _isAdminFilter,
      activityStatus: _activityStatus,
      loadMore: loadMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip:
                'Create in-app ping rows for users with no app touch in 24h (not push). Excludes admins.',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: provider.isLoading
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Ping inactive users?'),
                        content: const Text(
                          'Creates in-app ping records (not device push) for accounts with no last_active_at '
                          'within 24 hours. Admin accounts are excluded. Limited to about once per 5 minutes per admin.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    try {
                      final stats = await Provider.of<AdminProvider>(context, listen: false)
                          .pingInactiveUsers();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Inactive in-app pings: ${stats['pinged']} created, ${stats['skipped']} skipped, '
                            '${stats['failed']} failed (of ${stats['total_targets']})',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ping failed: $e')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Username or Email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _refreshUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onSubmitted: (_) => _refreshUsers(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message:
                      'Engagement = last app touch (last_active_at), not mining. '
                      'These totals match search + suspicious + role filters, but not the activity chips.',
                  child: const Text(
                    'Summary (filtered)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Tooltip(
                      message: 'Users matching current search/filters',
                      child: _summaryChip(
                        'Total (filtered)',
                        provider.summaryTotalUsers,
                        Colors.blueGrey,
                      ),
                    ),
                    Tooltip(
                      message: 'last_active_at within 24h',
                      child: _summaryChip(
                        'Recently active',
                        provider.summaryActiveUsers,
                        Colors.green,
                      ),
                    ),
                    Tooltip(
                      message: 'No touch or last_active_at older than 24h',
                      child: _summaryChip(
                        'Inactive >24h',
                        provider.summaryInactiveUsers,
                        Colors.orange,
                      ),
                    ),
                    Tooltip(
                      message: 'Rows in the list after activity filter',
                      child: _summaryChip(
                        'Listed rows',
                        provider.totalUsers,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Tooltip(
                  message: 'Engagement filter (last_active_at), not mining',
                  child: ChoiceChip(
                    label: const Text('Engagement: All', style: TextStyle(fontSize: 12)),
                    selected: _activityStatus == 'all',
                    onSelected: (_) {
                      setState(() => _activityStatus = 'all');
                      _refreshUsers();
                    },
                  ),
                ),
                Tooltip(
                  message: 'last_active_at within 24h',
                  child: ChoiceChip(
                    label: const Text('Engagement: Recent', style: TextStyle(fontSize: 12)),
                    selected: _activityStatus == 'active',
                    onSelected: (_) {
                      setState(() => _activityStatus = 'active');
                      _refreshUsers();
                    },
                  ),
                ),
                Tooltip(
                  message: 'No touch or last_active_at older than 24h',
                  child: ChoiceChip(
                    label: const Text('Engagement: Stale', style: TextStyle(fontSize: 12)),
                    selected: _activityStatus == 'inactive',
                    onSelected: (_) {
                      setState(() => _activityStatus = 'inactive');
                      _refreshUsers();
                    },
                  ),
                ),
                const SizedBox(width: 8, child: VerticalDivider()),
                // Suspicious Filter
                _buildFilterChip(
                  label: "Suspicious",
                  isSelected: _isSuspiciousFilter == true,
                  onSelected: (val) {
                    setState(() => _isSuspiciousFilter = val ? true : null);
                    _refreshUsers();
                  },
                  activeColor: Colors.red,
                ),
                _buildFilterChip(
                  label: "Safe",
                  isSelected: _isSuspiciousFilter == false,
                  onSelected: (val) {
                    setState(() => _isSuspiciousFilter = val ? false : null);
                    _refreshUsers();
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8, child: VerticalDivider()),
                // Admin Filter
                _buildFilterChip(
                  label: "Admins",
                  isSelected: _isAdminFilter == true,
                  onSelected: (val) {
                    setState(() => _isAdminFilter = val ? true : null);
                    _refreshUsers();
                  },
                  activeColor: Colors.blue,
                ),
                _buildFilterChip(
                  label: "Users",
                  isSelected: _isAdminFilter == false,
                  onSelected: (val) {
                    setState(() => _isAdminFilter = val ? false : null);
                    _refreshUsers();
                  },
                  activeColor: Colors.grey,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: provider.isLoading && provider.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _refreshUsers(),
                    child: ListView.builder(
                      itemCount: provider.users.length + (provider.hasMoreUsers ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.users.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: provider.isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton.icon(
                                      onPressed: () => _refreshUsers(loadMore: true),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Load More'),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final user = provider.users[index];
                        return _buildUserCard(user, provider);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int value, Color color) {
    return Chip(
      avatar: Icon(Icons.insights, size: 18, color: color),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: activeColor,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, AdminProvider provider) {
    final bool isSuspicious = user['is_suspicious'] == true;
    final bool isAdmin = user['is_admin'] == true;
    final bool isUnverified = user['email_verified'] == false;

    return Card(
      elevation: 0,
      color: isSuspicious
          ? Colors.red.withValues(alpha: 0.05)
          : (isAdmin ? Colors.blue.withValues(alpha: 0.05) : null),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSuspicious ? Colors.red.withValues(alpha: 0.3) : (isAdmin ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuspicious ? Colors.red : (isAdmin ? Colors.blue : null),
          child: Text(
            (user['username'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text('${user['username']} (${user['display_name'] ?? 'No Name'})', overflow: TextOverflow.ellipsis)),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              const Icon(Icons.admin_panel_settings, color: Colors.blue, size: 16),
            ],
            if (isSuspicious) ...[
              const SizedBox(width: 4),
              const Icon(Icons.warning, color: Colors.red, size: 16),
            ],
            if (isUnverified) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Email not yet verified',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'unverified',
                    style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(user['email'] ?? ''),
        trailing: isUnverified
            ? IconButton(
                tooltip: 'Verify email manually (admin override)',
                icon: const Icon(Icons.mark_email_read_outlined, color: Colors.green),
                onPressed: () => _confirmActivateEmail(
                  user['id'] as String,
                  user['username'] as String?,
                  user['email'] as String?,
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUserDetailScreen(user: user),
            ),
          ).then((_) => _refreshUsers());
        },
      ),
    );
  }

  Future<void> _confirmActivateEmail(
    String userId,
    String? username,
    String? email,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manually verify email?'),
        content: Text(
          'This marks ${username ?? "this user"} as email-verified without '
          'the activation code. Use only when the user can\'t receive their '
          'code (typo\'d or blocked address: ${email ?? "unknown"}). '
          'Referral signup bonuses are granted if applicable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    try {
      final result = await provider.activateUserEmail(userId);
      if (!mounted) return;
      final already = result['already_verified'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(already
              ? 'User was already verified.'
              : 'Email marked as verified.'),
          backgroundColor: already ? Colors.grey : Colors.green,
        ),
      );
      _refreshUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}


