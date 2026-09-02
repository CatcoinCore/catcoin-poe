import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const address = '9eteYzrmnzyxURMe5dWo1Tt5K2P3G9KrTh'; // Known address
  const explorerApiUrl = 'https://chainz.cryptoid.info/cat/api.dws';
  // const apiKey = '0575d3ad24b8'; // Test with and without this
  const String? apiKey = null; // Test WITHOUT key first (fast mode)

  stdout.writeln('Testing Wallet Info for: $address');
  stdout.writeln('API Key: $apiKey');

  try {
    // 1. Fetch current balance
    final balanceUrl = Uri.parse('$explorerApiUrl?q=getbalance&a=$address');
    stdout.writeln('Fetching balance...');
    final balanceResponse = await http.get(balanceUrl);

    if (balanceResponse.statusCode != 200) {
      stdout.writeln('Failed to fetch balance: ${balanceResponse.statusCode}');
      return;
    }

    final currentBalance = double.tryParse(balanceResponse.body) ?? 0.0;
    stdout.writeln('Current Balance: $currentBalance');

    if (currentBalance < 100) {
      stdout.writeln('Balance < 100, Days: 0');
      return;
    }

    // 1b. Fetch Chain Tip
    final heightUrl = Uri.parse('$explorerApiUrl?q=getblockcount');
    final heightResponse = await http.get(heightUrl);
    final tipHeight = int.tryParse(heightResponse.body) ?? 0;
    stdout.writeln('Tip Height: $tipHeight');

    // 2. Fetch Transaction History
    List<dynamic> allTxs = [];
    String? beforeBlock;
    bool hasMore = true;
    int pageCount = 0;
    const int maxPages = 20;

    while (hasMore && pageCount < maxPages) {
      var txUrl = '$explorerApiUrl?q=multiaddr&active=$address&n=50';
      if (apiKey != null && apiKey.isNotEmpty) {
        txUrl += '&key=$apiKey';
      }
      if (beforeBlock != null && beforeBlock != 'null') {
        txUrl += '&before=$beforeBlock';
      }

      stdout.writeln('Fetching page $pageCount: $txUrl');
      final txResponse = await http.get(Uri.parse(txUrl));

      if (txResponse.statusCode == 200) {
        final data = jsonDecode(txResponse.body);
        final txs = data['txs'] as List<dynamic>;

        if (txs.isEmpty) {
          hasMore = false;
        } else {
          try {
            final mappedTxs = txs.map((t) {
              // Exact logic from BlockchainService
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
          } catch (e) {
            stdout.writeln('PARSING ERROR: $e');
            stdout.writeln('Bad TX Data: ${txs.first}');
            hasMore = false;
          }
        }
      } else {
        stdout.writeln('Error fetching: ${txResponse.statusCode}');
        hasMore = false;
      }
    }

    stdout.writeln('Total TXs fetched: ${allTxs.length}');

    // 3. Calculate Days
    double runningBalance = currentBalance;
    DateTime? violationDate;

    for (var tx in allTxs) {
      final amount = tx['amount'] as double;
      double preTxBalance = runningBalance - amount;

      stdout.writeln('Date: ${tx['date']}, Amount: $amount, PreBal: $preTxBalance');

      if (preTxBalance < 100) {
        violationDate = tx['date'] as DateTime;
        stdout.writeln('VIOLATION FOUND: $violationDate');
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
        stdout.writeln('No violation. Days from oldest: $daysMaintained');
      } else {
        daysMaintained = 0;
        stdout.writeln('No history. Days: 0');
      }
    }

    stdout.writeln('FINAL RESULT: Days Maintained = $daysMaintained');
  } catch (e) {
    stdout.writeln('Exception: $e');
  }
}
