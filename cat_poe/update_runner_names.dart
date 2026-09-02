import 'dart:convert';
import 'dart:io';

void main() async {
  final projectRoot = File(Platform.script.toFilePath()).parent;
  final l10nDir = Directory('${projectRoot.path}/lib/l10n');
  final files = l10nDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));

  for (final file in files) {
    if (file.path.endsWith('app_en.arb')) continue; // Skip English, assume it's right

    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);
    bool modified = false;

    // Keys that might hold the game title explicitly in English or translated. Let's just set to "Cat Runner"
    // Since names like Cat Runner are often untranslated brand names.
    final titleKeys = ['gamesRunnerTitle', 'gameLauncherTitle'];

    for (final key in titleKeys) {
      if (data.containsKey(key)) {
        if (data[key] != 'Cat Runner') {
          data[key] = 'Cat Runner';
          modified = true;
        }
      }
    }

    // For generic text, just do standard text replace for English variations
    if (data.containsKey('gamesRunner')) {
       final val = data['gamesRunner'];
       if (val is String && RegExp(r'catcoin runner', caseSensitive: false).hasMatch(val)) {
         data['gamesRunner'] = val.replaceAll(RegExp(r'catcoin runner', caseSensitive: false), 'Cat Runner');
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
