import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';

/// A reusable widget that displays a settings gear icon for administrators.
/// Navigates to the Admin Panel when tapped.
class AdminGear extends StatelessWidget {
  const AdminGear({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null || user.isAdmin != true) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Admin Panel',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            );
          },
        );
      },
    );
  }
}

