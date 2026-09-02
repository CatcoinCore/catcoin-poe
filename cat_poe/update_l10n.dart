import 'dart:convert';
import 'dart:io';

void main() async {
  final projectRoot = File(Platform.script.toFilePath()).parent;
  final l10nDir = Directory('${projectRoot.path}/lib/l10n');
  final files = l10nDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));

  for (final file in files) {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);
    bool modified = false;

    if (data.containsKey('boostersReferralBoosting')) {
      final str = data['boostersReferralBoosting'] as String;
      if (!str.contains('{boost}')) {
        data['boostersReferralBoosting'] = '$str (+{boost}%)';
        data['@boostersReferralBoosting'] = {
          'placeholders': {
            'boost': {}
          }
        };
        modified = true;
      }
    }

    if (modified) {
      final encoder = JsonEncoder.withIndent('  ');
      final newContent = encoder.convert(data);
      await file.writeAsString('$newContent\n');
      stdout.writeln('Updated ${file.path.split(Platform.pathSeparator).last}');
    }
  }
}
