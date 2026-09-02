import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'payout_history_screen.dart';
import 'wallet_screen.dart';
import 'social_profiles_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_gear.dart';
import '../services/api_service.dart';
import '../models/user_badge.dart';
import '../models/user.dart';
import '../utils/user_badge_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  // Focus the display-name field via a post-frame callback after the user
  // taps "edit" rather than via `autofocus: true`, so the IME's
  // showSoftInput() doesn't fire before the new sub-tree is fully laid
  // out (which can ANR the main thread waiting on a Binder IPC to the
  // InputMethodManager — see ANR trace 2026-05-26).
  final FocusNode _displayNameFocus = FocusNode();
  String _appVersion = '';
  bool _isEditingDisplayName = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setProfileImage(pickedFile.path);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failedPickImage(e.toString()))),
      );
    }
  }

  void _showImagePickerOptions() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.commonGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.commonCamera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (Provider.of<AuthProvider>(context, listen: false)
                        .profileImagePath !=
                    null &&
                Provider.of<AuthProvider>(context, listen: false)
                    .profileImagePath!
                    .isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l.commonRemovePhoto,
                    style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await Provider.of<AuthProvider>(context, listen: false)
                      .setProfileImage('');
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _displayNameController.text = user.displayName ?? '';
      }
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _appVersion =
          '${l.commonVersion} ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameFocus.dispose();
    super.dispose();
  }

  void _showLanguageSelector(BuildContext context) {
    final l = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languages = [
      {'locale': const Locale('en'), 'name': l.languageEnglish, 'isIndian': false},
      {'locale': const Locale('ja'), 'name': l.languageJapanese, 'isIndian': false},
      {'locale': const Locale('ko'), 'name': l.languageKorean, 'isIndian': false},
      {'locale': const Locale('zh'), 'name': l.languageChinese, 'isIndian': false},
      {'locale': const Locale('es'), 'name': l.languageSpanish, 'isIndian': false},
      {'locale': const Locale('fr'), 'name': l.languageFrench, 'isIndian': false},
      {'locale': const Locale('ru'), 'name': l.languageRussian, 'isIndian': false},
      {'locale': const Locale('ar'), 'name': l.languageArabic, 'isIndian': false},
      {'locale': const Locale('ms'), 'name': l.languageMalay, 'isIndian': false},
      {'locale': const Locale('id'), 'name': l.languageIndonesian, 'isIndian': false},
      {'locale': const Locale('vi'), 'name': l.languageVietnamese, 'isIndian': false},

      {'locale': const Locale('hi'), 'name': l.languageHindi, 'isIndian': true},
      {'locale': const Locale('te'), 'name': l.languageTelugu, 'isIndian': true},
      {'locale': const Locale('ta'), 'name': l.languageTamil, 'isIndian': true},
      {'locale': const Locale('gu'), 'name': l.languageGujarati, 'isIndian': true},
      {'locale': const Locale('or'), 'name': l.languageOdia, 'isIndian': true},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.languageSelectTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 0),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isIndian = lang['isIndian'] as bool;
                  
                  bool showHeader = false;
                  String headerText = '';
                  if (index == 0) {
                    showHeader = true;
                    headerText = l.languageGroupInternational;
                  } else if (isIndian && !(languages[index-1]['isIndian'] as bool)) {
                    showHeader = true;
                    headerText = l.languageGroupIndian;
                  }

                  final locale = lang['locale'] as Locale;
                  final name = lang['name'] as String;
                  final isSelected =
                      localeProvider.locale.languageCode == locale.languageCode;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) ...[
                        if (index > 0) const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Text(
                            headerText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                      ListTile(
                        title: Text(name),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.orange)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(locale);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profileImage = authProvider.profileImagePath;
    final adminConfig = Provider.of<AdminProvider>(context).config;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l = AppLocalizations.of(context);

    final currentLangName = {
      'en': l.languageEnglish,
      'vi': l.languageVietnamese,
      'zh': l.languageChinese,
      'es': l.languageSpanish,
      'hi': l.languageHindi,
      'te': l.languageTelugu,
      'ta': l.languageTamil,
      'ru': l.languageRussian,
      'ja': l.languageJapanese,
      'ms': l.languageMalay,
      'id': l.languageIndonesian,
      'ko': l.languageKorean,
      'ar': l.languageArabic,
      'fr': l.languageFrench,
      'gu': l.languageGujarati,
      'or': l.languageOdia,
    }[localeProvider.locale.languageCode] ?? l.languageEnglish;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          const AdminGear(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: adminConfig?.enableProfilePicture == true
                ? _showImagePickerOptions
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.orange,
                  backgroundImage:
                      profileImage != null && profileImage.isNotEmpty
                          ? FileImage(File(profileImage))
                          : null,
                  child: (profileImage == null || profileImage.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                if (adminConfig?.enableProfilePicture == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Display Name with edit capability
          Center(
            child: _isEditingDisplayName
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _displayNameController,
                          focusNode: _displayNameFocus,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await authProvider.updateProfile({
                            'display_name':
                                _displayNameController.text.isNotEmpty
                                    ? _displayNameController.text
                                    : null,
                          });
                          setState(() {
                            _isEditingDisplayName = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _displayNameController.text =
                              user?.displayName ?? '';
                          setState(() {
                            _isEditingDisplayName = false;
                          });
                        },
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingDisplayName = true;
                      });
                      // Defer keyboard-show until the new sub-tree is laid
                      // out so the IME's showSoftInput doesn't block on an
                      // un-attached window (cause of past ANRs).
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _displayNameFocus.requestFocus();
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user?.displayName ?? user?.username ?? l.commonUser} (${user?.username ?? ''})',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          _buildShowcaseSection(l, user, authProvider),

          // Settings Section
          _buildSectionHeader(l.profileSettings),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: Text(l.profileAppearance),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(l.profileThemeSystem)),
                      DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(l.profileThemeLight)),
                      DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l.profileThemeDark)),
                    ],
                    onChanged: (ThemeMode? mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.profileLanguage),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currentLangName,
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => _showLanguageSelector(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l.profileSocialProfiles),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SocialProfilesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet,
                      color: Colors.blueAccent),
                  title: Text(l.walletMyWallets),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l.profilePayoutHistory),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PayoutHistoryScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text(l.profileChangePassword),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showChangePasswordDialog(context, authProvider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                authProvider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l.profileLogout),
            ),
          ),
          const SizedBox(height: 16),

          // Delete Account Button (Danger Zone)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _showDeleteConfirmation(context, authProvider),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l.profileDeleteAccount),
            ),
          ),
          const SizedBox(height: 24),

          // Version Info
          Center(
            child: Text(
              _appVersion,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AuthProvider authProvider) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        var obscureOld = true;
        var obscureNew = true;
        var obscureConfirm = true;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(l.changePasswordTitle),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: l.changePasswordCurrent,
                        suffixIcon: IconButton(
                          tooltip: obscureOld ? 'Show' : 'Hide',
                          icon: Icon(obscureOld
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setDialogState(
                              () => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? l.commonRequired : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: l.changePasswordNew,
                        suffixIcon: IconButton(
                          tooltip: obscureNew ? 'Show' : 'Hide',
                          icon: Icon(obscureNew
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setDialogState(
                              () => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? l.changePasswordMin6 : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: l.changePasswordConfirm,
                        suffixIcon: IconButton(
                          tooltip: obscureConfirm ? 'Show' : 'Hide',
                          icon: Icon(obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != newPasswordController.text) {
                          return l.changePasswordMismatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final oldPwd = oldPasswordController.text;
                      final newPwd = newPasswordController.text;
                      Navigator.pop(ctx);

                      try {
                        await authProvider.changePassword(oldPwd, newPwd);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l.changePasswordSuccess),
                                backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${l.commonError}: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: Text(l.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, AuthProvider authProvider) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccountTitle),
        content: Text(l.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await authProvider.deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l.deleteAccountFailed(e.toString())),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.deleteAccountConfirm),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseSection(AppLocalizations l, User? user, AuthProvider authProvider) {
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l.profileShowcaseTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.profileShowcaseSubtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<UserBadge>>(
                  key: ValueKey(user.showcaseBadgeIds.join(',')),
                  future: ApiService().getMyBadges().then(
                        (list) => list
                            .map((e) => UserBadge.fromJson(Map<String, dynamic>.from(e as Map)))
                            .toList(),
                      ),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    final all = snap.data ?? [];
                    final map = {for (final b in all) b.id: b};
                    if (user.showcaseBadgeIds.isEmpty) {
                      return Text(l.profileShowcaseEmpty, style: TextStyle(color: Colors.grey.shade600));
                    }
                    return SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.showcaseBadgeIds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final id = user.showcaseBadgeIds[i];
                          final b = map[id];
                          if (b == null) {
                            return const SizedBox(width: 48, height: 48);
                          }
                          final col = userBadgeColor(b.badgeType);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => showUserBadgeDetailSheet(context, b),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: col.withValues(alpha: 0.25),
                                child: Icon(userBadgeIcon(b.badgeType), color: col, size: 28),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _openShowcaseEditor(context, authProvider),
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(l.profileShowcaseManage),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _openShowcaseEditor(BuildContext context, AuthProvider authProvider) async {
    final l = AppLocalizations.of(context);
    final user = authProvider.user;
    if (user == null) return;

    List<UserBadge> earned;
    try {
      final raw = await ApiService().getMyBadges();
      earned = raw.map((e) => UserBadge.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    if (!context.mounted) return;

    List<String> draft = List.from(user.showcaseBadgeIds);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.profileShowcaseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(l.profileShowcaseSubtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      Text(
                        l.profileShowcaseMax,
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: earned.isEmpty
                            ? Center(child: Text(l.awardsNoAwards))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: earned.length,
                                itemBuilder: (_, i) {
                                  final b = earned[i];
                                  final selected = draft.contains(b.id);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: userBadgeColor(b.badgeType).withValues(alpha: 0.25),
                                      child: Icon(userBadgeIcon(b.badgeType), color: userBadgeColor(b.badgeType)),
                                    ),
                                    title: Text(userBadgeTitle(l, b.badgeType)),
                                    subtitle: Text(
                                      b.description ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(
                                      selected ? Icons.check_circle : Icons.circle_outlined,
                                      color: selected ? Colors.green : null,
                                    ),
                                    onTap: () {
                                      setModal(() {
                                        if (selected) {
                                          draft.remove(b.id);
                                        } else {
                                          if (draft.length >= 6) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              SnackBar(content: Text(l.profileShowcaseMax)),
                                            );
                                            return;
                                          }
                                          draft.add(b.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      FilledButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                try {
                                  await authProvider.updateShowcaseBadges(draft);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l.profileUpdatedSuccess)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        child: Text(l.profileShowcaseSave),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}

