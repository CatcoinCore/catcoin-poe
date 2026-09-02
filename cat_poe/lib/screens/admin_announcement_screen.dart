import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/locale_provider.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() =>
      _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String _editingLang = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (final loc in LocaleProvider.supportedLocales) {
      _controllers[loc.languageCode.toLowerCase()] = TextEditingController();
    }
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await provider.fetchFullAdminConfig();
      if (mounted && provider.config != null) {
        final config = provider.config!;
        final map = config.globalPushMessages;
        final legacy = config.globalPushMessage ?? '';
        for (final loc in LocaleProvider.supportedLocales) {
          final code = loc.languageCode.toLowerCase();
          final ctrl = _controllers[code];
          if (ctrl == null) continue;
          final localized = map?[code];
          ctrl.text = localized ?? (code == 'en' ? legacy : '');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load config: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_isLoading) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    if (provider.config == null) return;

    final out = <String, String>{};
    _controllers.forEach((code, ctrl) {
      final t = ctrl.text.trim();
      if (t.isNotEmpty) {
        out[code.toLowerCase()] = ctrl.text;
      }
    });

    setState(() => _isLoading = true);

    try {
      final updated = provider.config!.copyWith(
        globalPushMessages: out.isEmpty ? null : out,
        globalPushMessage: out['en'],
      );
      await provider.updateConfig(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update config: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langChoices = LocaleProvider.supportedLocales.map((l) {
      final code = l.languageCode.toLowerCase();
      return DropdownMenuItem<String>(
        value: code,
        child: Text(code.toUpperCase()),
      );
    }).toList();

    if (!langChoices.any((item) => item.value == _editingLang)) {
      _editingLang = 'en';
    }

    final activeController = _controllers[_editingLang];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Announcement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Localized messages shown in Updates → Announcements and on the dashboard. '
                  'Use one body per supported app language.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _editingLang,
                        items: langChoices,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _editingLang = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeController != null)
                  TextField(
                    controller: activeController,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText:
                          'Message for selected language (Markdown supported)',
                      border: OutlineInputBorder(),
                      hintText:
                          'Welcome — [learn more](https://example.com)',
                      alignLabelWithHint: true,
                    ),
                  ),
              ],
            ),
    );
  }
}
