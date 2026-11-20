import 'dart:io';
import 'dart:typed_data';

import 'package:gym_ready/repdb_assets.dart';

Future<void> main() async {
  final source = Uri.https(
    'huggingface.co',
    '/datasets/RepDB/exercise-dataset/resolve/$repDbRevision/images/',
  );
  final paths = {
    for (final id in repDbEquipmentImages.values) 'equipment/$id.webp',
    for (final id in repDbExerciseImages.values) 'flat/$id.webp',
  };
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  var failed = 0;
  try {
    for (final path in paths) {
      final image = File('assets/repdb/$path');
      if (await image.exists() && _isWebP(await image.readAsBytes())) continue;
      try {
        final request = await client.getUrl(source.resolve(path));
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          throw HttpException('HTTP ${response.statusCode}');
        }
        final data = BytesBuilder(copy: false);
        await for (final chunk in response.timeout(
          const Duration(seconds: 20),
        )) {
          data.add(chunk);
          if (data.length > 1024 * 1024) {
            throw const FormatException('Image is too large.');
          }
        }
        final bytes = data.takeBytes();
        if (!_isWebP(bytes)) throw const FormatException('Invalid WebP image.');
        await image.parent.create(recursive: true);
        final partial = await File('${image.path}.part').writeAsBytes(bytes);
        await partial.rename(image.path);
      } catch (error) {
        failed++;
        stderr.writeln('$path: $error');
      }
    }
  } finally {
    client.close(force: true);
  }
  stdout.writeln(
    '${paths.length - failed}/${paths.length} RepDB stills are ready.',
  );
  if (failed != 0) exitCode = 1;
}

bool _isWebP(Uint8List data) =>
    data.length >= 12 &&
    String.fromCharCodes(data.take(4)) == 'RIFF' &&
    String.fromCharCodes(data.skip(8).take(4)) == 'WEBP' &&
    ByteData.sublistView(data).getUint32(4, Endian.little) + 8 == data.length;
