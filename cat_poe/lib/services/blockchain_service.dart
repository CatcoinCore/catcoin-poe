import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

class BlockchainService {
  static const String _explorerApiUrl =
      'https://chainz.cryptoid.info/cat/api.dws';
  // static const String _apiKey = '...'; // REMOVED: Now passed dynamically

  static DateTime? _lastRequestTime;
  // Increase delay to strictly respect 1 request per 10s rule + buffer
  // Default 10.5s for API Key (Strict Limit). Fast for no key (IP limit).
  static const Duration _slowRequestInterval = Duration(milliseconds: 10500);
  static const Duration _fastRequestInterval =
      Duration(milliseconds: 500); // 2 requests/sec roughly

  Future<http.Response> _rateLimitedGet(Uri url, {String? apiKey}) async {
    final interval = (apiKey != null && apiKey.isNotEmpty)
        ? _fastRequestInterval
        : _slowRequestInterval;

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < interval) {
        final waitTime = interval - timeSinceLastRequest;
        // Only log if wait time is significant (> 1 second) to avoid spamming "Waiting 0s"
        if (waitTime.inSeconds >= 1) {
          LoggerService.info(
              'Rate limiting (${interval.inMilliseconds}ms): Waiting ${waitTime.inSeconds}s before next call');
        }
        await Future.delayed(waitTime);
      }
    }

    _lastRequestTime = DateTime.now();
    return http.get(url);
  }

  Future<double> getSimpleBalance(String address, {String? apiKey}) async {
    final balanceUrl = Uri.parse('$_explorerApiUrl?q=getbalance&a=$address');
    try {
      final response = await _rateLimitedGet(balanceUrl, apiKey: apiKey);
      if (response.statusCode == 200) {
        return double.tryParse(response.body) ?? 0.0;
      }
    } catch (e) {
      LoggerService.error('Failed to fetch simple balance for $address', e);
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> getWalletInfo(String address,
      {String? apiKey, double? knownBalance}) async {
    try {
      double currentBalance;

      if (knownBalance != null) {
        currentBalance = knownBalance;
      } else {
        // 1. Fetch current balance
        final balanceUrl =
            Uri.parse('$_explorerApiUrl?q=getbalance&a=$address');
        LoggerService.info('Fetching balance for $address');
        final balanceResponse =
            await _rateLimitedGet(balanceUrl, apiKey: apiKey);

        if (balanceResponse.statusCode != 200) {
          LoggerService.error(
              'Failed to fetch balance: ${balanceResponse.statusCode}');
          return {};
        }

        currentBalance = double.tryParse(balanceResponse.body) ?? 0.0;
      }

      // If balance is less than 100, days maintained is 0.
      if (currentBalance < 100) {
        return {'balance': currentBalance, 'daysMaintained': 0};
      }

      // 1b. Validate API Key for History
      if (apiKey == null || apiKey.isEmpty) {
        LoggerService.warning('API Key missing. Skipping history fetch.');
        return {'balance': currentBalance, 'daysMaintained': 0};
      }

      // 1c. Fetch Chain Tip (for block height calc)
      final heightUrl = Uri.parse('$_explorerApiUrl?q=getblockcount');
      final heightResponse = await _rateLimitedGet(heightUrl, apiKey: apiKey);
      final tipHeight = int.tryParse(heightResponse.body) ?? 0;

      // 2. Fetch Transaction History (Recursive/Paginated)
      List<dynamic> allTxs = [];
      String? beforeBlock;
      bool hasMore = true;
      int pageCount = 0;
      const int maxPages = 20; // Limit to ~10000 txs if n=500
      const int pageSize = 500; // Increase page size to reduce calls

      while (hasMore && pageCount < maxPages) {
        var txUrl =
            '$_explorerApiUrl?q=multiaddr&active=$address&n=$pageSize&key=$apiKey';

        if (beforeBlock != null && beforeBlock != 'null') {
          txUrl += '&before=$beforeBlock';
        }

        try {
          final txResponse =
              await _rateLimitedGet(Uri.parse(txUrl), apiKey: apiKey);
          if (txResponse.statusCode == 200) {
            final data = jsonDecode(txResponse.body);
            final txs = data['txs'] as List<dynamic>;

            if (txs.isEmpty) {
              hasMore = false;
            } else {
              // Map to standard format
              final mappedTxs = txs.map((t) {
                final amount = (t['change'] as num) / 100000000.0;
                final date = DateTime.parse(t['time_utc']);
                final timestamp = date.millisecondsSinceEpoch ~/ 1000;
                final confirmations = t['confirmations'] as int;
                final blockHeight = tipHeight - confirmations + 1;

                return {
                  'amount': amount,
                  'timestamp': timestamp,
                  'block_height': blockHeight,
                  'date': date
                };
              }).toList();

              allTxs.addAll(mappedTxs);
              final oldestTx = mappedTxs.last;
              beforeBlock = oldestTx['block_height'].toString();
              pageCount++;
            }
          } else {
            hasMore = false;
          }
        } catch (e) {
          LoggerService.error('Error fetching tx page $pageCount', e);
          hasMore = false;
        }
      }

      // 3. Calculate Days Maintained
      double runningBalance = currentBalance;
      DateTime? violationDate;

      // Chainz API typically returns newest first.
      for (var tx in allTxs) {
        final amount = tx['amount'] as double;
        // runningBalance (post-tx) = pre-tx balance + amount
        // pre-tx balance = runningBalance - amount
        double preTxBalance = runningBalance - amount;

        if (preTxBalance < 100) {
          violationDate = tx['date'] as DateTime;
          break;
        }

        runningBalance = preTxBalance;
      }

      int daysMaintained;
      if (violationDate != null) {
        final diff = DateTime.now().difference(violationDate);
        daysMaintained = diff.inDays;
      } else {
        if (allTxs.isNotEmpty) {
          final oldestTxDate = allTxs.last['date'] as DateTime;
          final diff = DateTime.now().difference(oldestTxDate);
          daysMaintained = diff.inDays;
        } else {
          // If no history found (and balance > 100), assume 0 or handle nicely
          // If balance is > 100 implies at least one tx exists.
          daysMaintained = 0;
        }
      }

      return {'balance': currentBalance, 'daysMaintained': daysMaintained};
    } catch (e) {
      LoggerService.error('Error fetching wallet info for $address', e);
      return {};
    }
  }

  Future<Map<String, double>> getBalances(List<String> addresses,
      {String? apiKey}) async {
    if (addresses.isEmpty) return {};

    final joined = addresses.join('|');
    // Using multiaddr for balances is efficient.
    // We do NOT need full history here, so 'n=0' or default small is fine.
    // Actually, 'multiaddr' returns summary list.
    var urlStr = '$_explorerApiUrl?q=multiaddr&active=$joined';
    if (apiKey != null && apiKey.isNotEmpty) {
      urlStr += '&key=$apiKey';
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await _rateLimitedGet(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = <String, double>{};

        if (data is Map && data.containsKey('addresses')) {
          final addrList = data['addresses'] as List<dynamic>;
          for (var item in addrList) {
            final addr = item['address'] as String;
            final bal =
                double.tryParse(item['final_balance'].toString()) ?? 0.0;
            results[addr] = bal;
          }
        }
        return results;
      }
    } catch (e) {
      LoggerService.error('Error fetching bulk balances', e);
    }
    return {};
  }
}


