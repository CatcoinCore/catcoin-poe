import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import '../services/admin_service.dart';
import '../services/blockchain_service.dart';
import '../models/wallet.dart';
import '../models/admin_config.dart';
import '../models/payout.dart';
import '../models/balance_details.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final BlockchainService _blockchainService = BlockchainService();
  final AdminService _adminService = AdminService(ApiService());

  List<Wallet> _wallets = [];
  bool _isLoading = false;
  String? _error;
  BalanceDetails? _balanceDetails;
  List<EarningsLedgerEntry> _earningsHistory = [];

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BalanceDetails? get balanceDetails => _balanceDetails;
  List<EarningsLedgerEntry> get earningsHistory => _earningsHistory;

  Future<void> fetchWallets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/wallets');
      if (response != null && response is List) {
        _wallets = response.map((json) => Wallet.fromJson(json)).toList();

        // Fetch balances in background
        fetchBalances();
      } else {
        _wallets = [];
      }
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to fetch wallets', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBalances() async {
    // 0. Fetch Config for API Key & Settings
    AdminConfig? config;
    try {
      config = await _adminService.getConfig();
    } catch (e) {
      LoggerService.error('Failed to fetch admin config', e);
    }
    final apiKey = config?.coinExplorerApiKey;

    // 1. Individual Balance Fetch (Fast if API Key present)
    for (int i = 0; i < _wallets.length; i++) {
      try {
        final wallet = _wallets[i];
        final balance = await _blockchainService
            .getSimpleBalance(wallet.catcoinAddress, apiKey: apiKey);

        // Update balance immediately
        _wallets[i] = wallet.copyWith(balance: balance);
        notifyListeners();
      } catch (e) {
        LoggerService.error('Failed to fetch balance for wallet ${i + 1}', e);
      }
    }

    // 2. Slow Detailed History Fetch (Days Maintained)
    // This will take time due to 10.5s rate limit per wallet
    if (config?.enableWalletHoldingDays == true) {
      try {
        for (int i = 0; i < _wallets.length; i++) {
          final wallet = _wallets[i];

          // NEW: Only fetch history for PRIMARY wallet
          if (!wallet.isPrimary) continue;

          // Optimization: If we just fetched balance and it's < 100, we know days = 0.
          if (wallet.balance != null && wallet.balance! < 100) {
            _wallets[i] = wallet.copyWith(daysMaintained: 0);
            notifyListeners();
            continue;
          }

          final info = await _blockchainService.getWalletInfo(
              wallet.catcoinAddress,
              apiKey: apiKey,
              knownBalance: wallet.balance);
          if (info.isNotEmpty) {
            _wallets[i] = wallet.copyWith(
                balance: info['balance'] as double,
                daysMaintained: info['daysMaintained'] as int);
            notifyListeners();
          }

          // Small delay just in case of rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        LoggerService.error('Failed to fetch history', e);
      }
    }
  }

  Future<void> addWallet(String address,
      {bool isPrimary = false, String source = 'MANUAL'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/wallets', body: {
        'catcoin_address': address,
        'is_primary': isPrimary,
        'source': source,
      });
      await fetchWallets();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to add wallet', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWallet(String walletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/wallets/$walletId');
      await fetchWallets();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to delete wallet', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPrimaryWallet(String walletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.put('/wallets/$walletId/primary', body: {});
      await fetchWallets();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to set primary wallet', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Payout History
  List<Payout> _payouts = [];
  List<Payout> get payouts => _payouts;

  Future<void> fetchPayoutHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/v1/payouts/');
      _payouts = (response as List).map((e) => Payout.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to fetch payout history', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBalanceDetails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/auth/users/me/balance-details');
      if (response != null) {
        _balanceDetails = BalanceDetails.fromJson(response);
      }
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to fetch balance details', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEarningsHistory({String? rewardType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '/auth/users/me/earnings-history';
      if (rewardType != null && rewardType != 'ALL') {
        url += '?reward_type=$rewardType';
      }
      final response = await _apiService.get(url);
      if (response != null && response is List) {
        _earningsHistory = response.map((json) => EarningsLedgerEntry.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to fetch earnings history', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestWithdrawal(String rewardType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/users/me/withdraw?reward_type=$rewardType', body: {});
      if (response != null && response['payout_id'] != null) {
        await fetchBalanceDetails(); // Refresh balance
        await fetchPayoutHistory(); // Refresh payout list
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('Failed to request withdrawal', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


