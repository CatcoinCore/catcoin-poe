import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wallet.dart'; // Import Wallet model for type checking
// import '../providers/auth_provider.dart'; // Removed unused import
import '../providers/wallet_provider.dart';
import '../providers/admin_provider.dart';
import '../utils/cat_wallet_generator.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Import Slidable
import '../widgets/admin_gear.dart';
import 'package:cat_poe/l10n/app_localizations.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallets();
    });
  }

  void _showManualWalletDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final addressController = TextEditingController();
    bool isPrimary = false;
    bool isAdding = false;
    String? validationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.walletAddExisting),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: l.walletCatcoinAddress,
                  hintText: l.walletPasteHint,
                  errorText: validationError,
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setState(() => validationError = null);
                  }
                },
              ),
              CheckboxListTile(
                title: Text(l.walletSetPrimary),
                value: isPrimary,
                onChanged: (val) => setState(() => isPrimary = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAdding ? null : () => Navigator.pop(context),
              child: Text(l.commonCancel),
            ),
            ElevatedButton(
              onPressed: isAdding
                  ? null
                  : () async {
                      final address = addressController.text.trim();
                      if (address.isEmpty) return;

                      // Validation Regex
                      final isEvm =
                          RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
                      final isSolana = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$')
                          .hasMatch(address);
                      final isCat = RegExp(r'^9[1-9A-HJ-NP-Za-km-z]{25,34}$')
                          .hasMatch(address);

                      if (!isEvm && !isSolana && !isCat) {
                        setState(() {
                          validationError = l.walletInvalidAddressComplex;
                        });
                        return;
                      }

                      setState(() => isAdding = true);
                      Navigator.pop(context); // Close dialog first?
                      // Actually better to keep dialog open until success if we want to show error there,
                      // but helper uses snackbar. Let's close then add.

                      await _addWalletToProvider(
                          address, 'MANUAL', isPrimary, context);
                    },
              child: isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.commonAdd),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoverWalletDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mnemonicController = TextEditingController();
    bool isRecovering = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l.walletRecoverTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.walletRecoverInstruction),
                const SizedBox(height: 16),
                TextField(
                  controller: mnemonicController,
                  decoration: InputDecoration(
                    labelText: l.walletSecretPhrase,
                    hintText: l.walletSecretPhraseHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isRecovering ? null : () => Navigator.pop(context),
                child: Text(l.commonCancel),
              ),
              ElevatedButton(
                onPressed: isRecovering
                    ? null
                    : () async {
                        final mnemonic = mnemonicController.text.trim();
                        // Basic validation (24 words)
                        if (mnemonic.split(RegExp(r'\s+')).length != 24) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l.walletInvalidPhrase)));
                          return;
                        }

                        setState(() => isRecovering = true);

                        try {
                          // Expensive CPU operation, await it
                          final wallet = await Future(() =>
                              CatWalletGenerator.importWalletFromMnemonic(
                                  mnemonic));

                          if (!context.mounted) return;

                          // Add recovered wallet
                          Navigator.pop(context); // Close dialog first
                          await _addWalletToProvider(
                              wallet['address']!, 'IMPORTED', false, context);
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isRecovering = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${l.commonError}: $e')));
                          }
                        }
                      },
                child: isRecovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.walletRecoverTitle),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(String walletId, String address) async {
    final l = AppLocalizations.of(context);
    bool isDeleting = false;

    return showDialog(
      context: context, // Use the screen's context
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l.walletDeleteTitle),
            content: Text(l.walletDeleteConfirmMessage(address)),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: Text(l.commonCancel),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);

                        // Capture scoped dependencies before async gap
                        final provider =
                            Provider.of<WalletProvider>(context, listen: false);
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        await provider.deleteWallet(walletId);

                        if (navigator.mounted) {
                          navigator.pop();
                        }

                        if (provider.error != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(provider.error!)),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(l.walletDeletedSuccess)),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.walletDeleteWallet, style: const TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addWalletToProvider(String address, String source,
      bool isPrimary, BuildContext context) async {
    final l = AppLocalizations.of(context);
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    await provider.addWallet(address, source: source, isPrimary: isPrimary);

    if (provider.error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l.walletAddedSuccess)),
      );
    }
  }

  void _showGenerateWalletFlow(BuildContext context) {
    final l = AppLocalizations.of(context);
    bool isGenerating = false;
    Map<String, String>? generatedWallet;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (generatedWallet != null) {
            // BACKUP STEP
            return AlertDialog(
              title: Text(l.walletBackupTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        l.walletAddedSuccess,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      l.walletBackupWarning,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        generatedWallet!['mnemonic']!,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l.walletAddressLabel(generatedWallet!['address']!),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.walletBackedUp),
                )
              ],
            );
          }

          return AlertDialog(
            title: Text(l.walletGenerateTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                Text(l.walletGenerateInstruction),
                const SizedBox(height: 16),
                if (isGenerating)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l.walletGenerating),
                    ],
                  ),
              ],
            ),
            actions: [
              if (!isGenerating) ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isGenerating = true;
                      error = null;
                    });

                    try {
                      // 1. Generate local keys (Expensive)
                      final walletData = await Future(
                          () => CatWalletGenerator.generateWallet());

                      if (!context.mounted) return;

                      // 2. Add to backend/provider
                      final provider =
                          Provider.of<WalletProvider>(context, listen: false);
                      await provider.addWallet(walletData['address']!,
                          source: 'GENERATED', isPrimary: false);

                      if (provider.error != null) {
                        setState(() {
                          isGenerating = false;
                          error = '${l.commonError}: ${provider.error}';
                        });
                        return;
                      }

                      // 3. Success! Update UI to show mnemonic backup
                      setState(() {
                        isGenerating = false;
                        generatedWallet = walletData;
                      });
                    } catch (e) {
                      setState(() {
                        isGenerating = false;
                        error = l.walletGenerationError(e.toString());
                      });
                    }
                  },
                  child: Text(l.commonGenerate),
                ),
              ]
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    // final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.walletMyWallets),
        actions: [
          const AdminGear(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMenuOpen) ...[
            FloatingActionButton.extended(
              heroTag: 'generate',
              onPressed: () {
                setState(() => _isMenuOpen = false);
                _showGenerateWalletFlow(context);
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.walletGenerateTitle),
              backgroundColor: Colors.green,
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'recover',
              onPressed: () {
                setState(() => _isMenuOpen = false);
                _showRecoverWalletDialog(context);
              },
              icon: const Icon(Icons.restore),
              label: Text(l.walletRecoverFromPhrase),
              backgroundColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'manual',
              onPressed: () {
                setState(() => _isMenuOpen = false);
                _showManualWalletDialog(context);
              },
              icon: const Icon(Icons.keyboard),
              label: Text(l.walletAddExisting),
              backgroundColor: Colors.blue,
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'menu',
            onPressed: () {
              setState(() {
                _isMenuOpen = !_isMenuOpen;
              });
            },
            backgroundColor: _isMenuOpen ? Colors.grey : Colors.blue,
            child: Icon(_isMenuOpen ? Icons.close : Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          if (walletProvider.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: walletProvider.isLoading &&
                            walletProvider.wallets.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: () => walletProvider.fetchWallets(),
                            child: Consumer<WalletProvider>(
                              builder: (context, provider, child) {
                                // Sort wallets: Primary first, then others
                                final sortedWallets =
                                    List<Wallet>.from(provider.wallets);
                                sortedWallets.sort((a, b) {
                                  if (a.isPrimary) return -1;
                                  if (b.isPrimary) return 1;
                                  return a.source.compareTo(b.source);
                                });

                                return ListView.builder(
                                  itemCount: sortedWallets.length,
                                  itemBuilder: (context, index) {
                                    final wallet = sortedWallets[index];

                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    Color cardColor;
                                    IconData sourceIcon;
                                    String sourceText;

                                    if (wallet.isPrimary) {
                                      // Primary gets special highlighting regardless of source
                                      cardColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
                                    } else if (wallet.source == 'GENERATED' ||
                                        wallet.source == 'IMPORTED') {
                                      // Generated and Recovered share same color
                                      cardColor = isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50;
                                    } else {
                                      // Manual
                                      cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
                                    }

                                    switch (wallet.source) {
                                      case 'GENERATED':
                                        sourceIcon = Icons.auto_awesome;
                                        sourceText = l.walletSourceGenerated;
                                        break;
                                      case 'IMPORTED':
                                        sourceIcon = Icons.import_export;
                                        sourceText = l.walletSourceRecovered;
                                        break;
                                      default: // MANUAL
                                        sourceIcon = Icons.keyboard;
                                        sourceText = l.walletSourceManual;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Slidable(
                                        key: Key(wallet.id),
                                        // Swipe Right -> Reveals Start Pane (Left side) -> Set Default
                                        startActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) async {
                                                if (wallet.isPrimary) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            l.walletSettingPrimary)));
                                                await Provider.of<
                                                            WalletProvider>(
                                                        context,
                                                        listen: false)
                                                    .setPrimaryWallet(
                                                        wallet.id);
                                              },
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              icon: Icons.star,
                                              label: l.walletSetDefault,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12),
                                                bottomLeft: Radius.circular(12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Swipe Left -> Reveals End Pane (Right side) -> Delete
                                        endActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (_) {
                                                _confirmDelete(wallet.id,
                                                    wallet.catcoinAddress);
                                              },
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete,
                                              label: l.profileDeleteAccount,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topRight: Radius.circular(12),
                                                bottomRight:
                                                    Radius.circular(12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Card(
                                          margin: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          color: cardColor,
                                          child: ListTile(
                                            leading: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .account_balance_wallet,
                                                    color: Colors.blueGrey),
                                              ],
                                            ),
                                            title: SelectableText(
                                              wallet.catcoinAddress,
                                              style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black87,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Row(
                                              children: [
                                                Icon(sourceIcon,
                                                    size: 12,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(sourceText,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey)),
                                                if (wallet.isPrimary) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(l.walletPrimary,
                                                      style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12)),
                                                ]
                                              ],
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (wallet.balance != null) ...[
                                                    Text(
                                                      '${wallet.balance!.toStringAsFixed(0)} ${l.dashboardCatoshi}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blueAccent,
                                                      ),
                                                    ),
                                                  if (Provider.of<AdminProvider>(
                                                                  context)
                                                              .config
                                                              ?.enableWalletHoldingDays ==
                                                          true &&
                                                      wallet.isPrimary) ...[
                                                    if (wallet.daysMaintained !=
                                                        null)
                                                      Text(
                                                        l.walletDaysHeld(wallet.daysMaintained.toString()),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    else if (wallet.balance !=
                                                            null &&
                                                        wallet.balance! >= 100)
                                                      Text(
                                                        l.walletCalculating,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.orange,
                                                            fontStyle: FontStyle
                                                                .italic),
                                                      )
                                                    else
                                                      Text(
                                                        l.walletDaysHeld('0'),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                  ]
                                                ] else
                                                  const SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


