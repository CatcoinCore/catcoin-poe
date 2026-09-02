import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/admin_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/markdown_safety.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  Locale? _lastFetchedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = Provider.of<LocaleProvider>(context).locale;
    if (_lastFetchedLocale == loc) return;
    _lastFetchedLocale = loc;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AdminProvider>(context, listen: false);
      final code = loc.languageCode;
      provider.fetchConfig(languageCode: code);
      provider.fetchWhatsNew(languageCode: code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Updates'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Announcements'),
              Tab(text: "What's New"),
            ],
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnnouncementsTab(context),
            _buildWhatsNewTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTab(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading && adminProvider.config == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final msg = adminProvider.config?.globalPushMessage;
        if (msg == null || msg.trim().isEmpty) {
          return const Center(
            child: Text(
              'No new announcements.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: MarkdownBody(
                  data: msg,
                  onTapLink: safeOnTapMarkdownLink,
                  imageBuilder: safeMarkdownImageBuilder,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWhatsNewTab(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.whatsNewLoading && adminProvider.whatsNewReleases == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final err = adminProvider.whatsNewError;
        final releases = adminProvider.whatsNewReleases ?? [];

        if (err != null && releases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load release notes.\n$err',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (releases.isEmpty) {
          return const Center(
            child: Text(
              'No release notes yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: releases.length,
          itemBuilder: (context, index) {
            final entry = releases[index];
            final version = entry.version;
            final date = entry.dateLabel;
            final notes = entry.notes;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ...notes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                note,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
