import 'dart:io';
import 'package:image/image.dart';

void main() {
  final files = ['cat_idle_sprite.png', 'cat_run_sprite.png', 'cat_boost_sprite.png'];
  final baseDir = 'lib/../assets/images';

  for (final file in files) {
    final path = '$baseDir/$file';
    final fileObj = File(path);
    if (!fileObj.existsSync()) {
      stdout.writeln('Skipping $file, does not exist.');
      continue;
    }

    try {
      final image = decodeImage(fileObj.readAsBytesSync());
      if (image == null) continue;

      final width = image.width;
      final height = image.height;
      final frameWidth = width ~/ 4;
      
      final name = file.replaceAll('_sprite.png', '');

      for (var i = 0; i < 4; i++) {
        final frame = copyCrop(image, x: i * frameWidth, y: 0, width: frameWidth, height: height);
        final outPath = '$baseDir/${name}_frame_$i.png';
        File(outPath).writeAsBytesSync(encodePng(frame));
        stdout.writeln('Saved $outPath');
      }
    } catch (e) {
      stdout.writeln('Error processing $file: $e');
    }
  }
}
