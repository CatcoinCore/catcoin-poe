import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const address = '9eteYzrmnzyxURMe5dWo1Tt5K2P3G9KrTh';
  const explorerApiUrl = 'https://chainz.cryptoid.info/cat/api.dws';

  stdout.writeln('Checking wallet: $address');

  // 1. Fetch Balance
  final balanceUrl = Uri.parse('$explorerApiUrl?q=getbalance&a=$address');
  final balanceRes = await http.get(balanceUrl);
  stdout.writeln('Balance Response: ${balanceRes.body}');
  final currentBalance = double.tryParse(balanceRes.body) ?? 0.0;
  stdout.writeln('Current Balance: $currentBalance');

  if (currentBalance < 100) {
    stdout.writeln('Balance < 100, days maintained = 0');
    return;
  }

  // 2. Fetch History
  List<dynamic> allTxs = [];
  String? beforeBlock;
  bool hasMore = true;
  int pageCount = 0;
  const int maxPages = 5;
  const apiKey = '0575d3ad24b8';

  // 0. Fetch Tip Height for Block calc
  final heightRes =
      await http.get(Uri.parse('$explorerApiUrl?q=getblockcount'));
  final tipHeight = int.tryParse(heightRes.body) ?? 0;
  stdout.writeln('Chain Tip: $tipHeight');

  while (hasMore && pageCount < maxPages) {
    var txUrl = '$explorerApiUrl?q=multiaddr&active=$address&n=50&key=$apiKey';
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
        stdout.writeln('First TX Raw: ${txs.first}');
        // Map to our expected format
        final mappedTxs = txs.map((t) {
          final amount = (t['change'] as num) / 100000000.0; // Satoshis to CAT
          final date = DateTime.parse(t['time_utc']); // ISO to DateTime
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

        stdout.writeln(
            'Fetched ${mappedTxs.length} txs. First: ${mappedTxs.first['amount']}, Last: ${mappedTxs.last['amount']}');

        allTxs.addAll(mappedTxs);

        final oldestTx = mappedTxs.last;
        beforeBlock = oldestTx['block_height'].toString();
        stdout.writeln('Next beforeBlock: $beforeBlock');

        // Prevent infinite loop if block height doesn't change (e.g. multiple txs in same block)
        // Ideally should handle this, but for now just increment page
        pageCount++;
      }
    } else {
      stdout.writeln('Error fetching: ${txResponse.statusCode}');
      hasMore = false;
    }
  }

  stdout.writeln('Total txs fetched: ${allTxs.length}');

  // 3. Logic Check
  double runningBalance = currentBalance;
  DateTime? violationDate;

  for (var tx in allTxs) {
    final amount = tx['amount'] as double;
    final date = tx['date'] as DateTime;
    // final timestamp = tx['timestamp'] as int;

    double preTxBalance = runningBalance - amount;

    stdout.writeln(
        'Date: $date, TxAmount: $amount, PostBal: $runningBalance, PreBal: $preTxBalance');

    if (preTxBalance < 100) {
      stdout.writeln('VIOLATION FOUND on $date. Balance dropped to $preTxBalance');
      violationDate = date;
      break;
    }
    runningBalance = preTxBalance;
  }

  if (violationDate != null) {
    final days = DateTime.now().difference(violationDate).inDays;
    stdout.writeln('Days Maintained: $days');
  } else {
    if (allTxs.isNotEmpty) {
      final oldestFetchedTxDate =
          DateTime.fromMillisecondsSinceEpoch(allTxs.last['timestamp'] * 1000);
      final days = DateTime.now().difference(oldestFetchedTxDate).inDays;
      stdout.writeln(
          'No violation in fetched history. At least: $days days (since $oldestFetchedTxDate)');
    } else {
      stdout.writeln('No history found. Days: 0');
    }
  }
}
