import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

const _maxModelBytes = 20 * 1024 * 1024;
final _downloads = <String, Future<String>>{};

bool isHttpsAsset(Uri? uri) =>
    uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

/// Gives model_viewer_plus an asset path or a file URL for its loopback server.
Future<String> resolveMachineModel(String source) async {
  final uri = Uri.parse(source);
  if (!uri.hasScheme && source.startsWith('assets/')) {
    final model = await rootBundle.load(source);
    if (!_validGlb(model, model.lengthInBytes)) {
      throw const FormatException('Expected a GLB 2.0 model.');
    }
    return source;
  }
  if (!isHttpsAsset(uri)) {
    throw const FormatException('Use an HTTPS model URL.');
  }
  final pending = _downloads.putIfAbsent(source, () => _cacheRemoteModel(uri));
  try {
    return await pending;
  } finally {
    if (identical(_downloads[source], pending)) _downloads.remove(source);
  }
}

bool _validGlb(ByteData header, int size) =>
    size >= 20 &&
    size <= _maxModelBytes &&
    header.lengthInBytes >= 12 &&
    header.getUint32(0, Endian.little) == 0x46546c67 &&
    header.getUint32(4, Endian.little) == 2 &&
    header.getUint32(8, Endian.little) == size;

Future<bool> _validFile(File file) async {
  if (!await file.exists()) return false;
  final reader = await file.open();
  try {
    return _validGlb(
      ByteData.sublistView(await reader.read(12)),
      await reader.length(),
    );
  } finally {
    await reader.close();
  }
}

Future<String> _cacheRemoteModel(Uri source) async {
  final root = await getApplicationCacheDirectory();
  final directory = await Directory(
    '${root.path}/machine-models',
  ).create(recursive: true);
  final key = sha256.convert(source.toString().codeUnits);
  final file = File('${directory.path}/$key.glb');
  if (await _validFile(file)) return file.uri.toString();

  final partial = File('${file.path}.part');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final response = await _requestModel(client, source);
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > _maxModelBytes) {
      throw const FormatException(
        'The model download is unavailable or too large.',
      );
    }
    final output = await partial.open(mode: FileMode.write);
    try {
      var bytes = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        bytes += chunk.length;
        if (bytes > _maxModelBytes) {
          throw const FormatException('The model download exceeded 20 MiB.');
        }
        await output.writeFrom(chunk);
      }
    } finally {
      await output.close();
    }
    if (!await _validFile(partial)) {
      throw const FormatException(
        'The download is not a complete GLB 2.0 model.',
      );
    }
    return (await partial.rename(file.path)).uri.toString();
  } finally {
    client.close(force: true);
    if (await partial.exists()) await partial.delete();
  }
}

Future<HttpClientResponse> _requestModel(HttpClient client, Uri uri) async {
  for (var redirects = 0; redirects <= 4; redirects++) {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (!response.isRedirect) return response;
    final location = response.headers.value(HttpHeaders.locationHeader);
    final next = location == null ? null : uri.resolve(location);
    if (!isHttpsAsset(next)) break;
    await response.drain<void>().timeout(const Duration(seconds: 5));
    uri = next!;
  }
  throw const FormatException('The model URL must resolve over HTTPS.');
}
