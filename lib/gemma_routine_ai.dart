import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:litertlm/litertlm.dart';
import 'package:path_provider/path_provider.dart';

import 'routine_ai.dart';

class GemmaRoutineAi implements RoutineAi {
  const GemmaRoutineAi();

  static const _modelName = 'gemma-4-E2B-it.litertlm';
  static const _modelBytes = 2588147712;
  static const _modelHash =
      '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c';
  static const _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
      'resolve/2d74ac41a33d7da82f39f7d5720a04c68514a103/$_modelName';
  static bool _generating = false;
  static bool _downloading = false;

  @override
  bool get supported =>
      Abi.current() == Abi.androidArm64 ||
      Abi.current() == Abi.androidX64 ||
      Abi.current() == Abi.iosArm64;

  Future<File> _modelFile() async {
    final cache = await getApplicationCacheDirectory();
    return File('${cache.path}/3000-gemma/$_modelName');
  }

  @override
  Future<bool> hasModel() async {
    if (!supported) return false;
    final model = await _modelFile();
    return await model.exists() && await model.length() == _modelBytes;
  }

  @override
  Future<void> downloadModel(void Function(double) onProgress) async {
    if (!supported || _downloading) {
      throw StateError('The model download is unavailable.');
    }
    _downloading = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final model = await _modelFile();
      await model.parent.create(recursive: true);
      final partial = File('${model.path}.part');
      try {
        final request = await client.getUrl(Uri.parse(_modelUrl));
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode != HttpStatus.ok ||
            (response.contentLength >= 0 &&
                response.contentLength != _modelBytes)) {
          throw const FormatException('Unexpected model download response.');
        }
        var received = 0;
        var lastPercent = -1;
        final chunks = response.timeout(const Duration(seconds: 40)).map((
          chunk,
        ) {
          received += chunk.length;
          if (received > _modelBytes) {
            throw const FormatException(
              'The model download exceeded its expected size.',
            );
          }
          final percent = received * 100 ~/ _modelBytes;
          if (percent != lastPercent) {
            lastPercent = percent;
            onProgress(percent / 100);
          }
          return chunk;
        });
        final file = partial.openWrite();
        try {
          await file.addStream(chunks);
        } finally {
          await file.close();
        }
        if (received != _modelBytes ||
            (await sha256.bind(partial.openRead()).first).toString() !=
                _modelHash) {
          throw const FormatException(
            'The model download failed verification.',
          );
        }
        await partial.rename(model.path);
      } finally {
        if (await partial.exists()) await partial.delete();
      }
    } finally {
      client.close(force: true);
      _downloading = false;
    }
  }

  @override
  Future<String> generate(String prompt) async {
    if (_generating || !supported) {
      throw StateError('The local engine is unavailable.');
    }
    _generating = true;
    try {
      final model = await _modelFile();
      if (!await model.exists() || await model.length() != _modelBytes) {
        throw StateError('The model is missing.');
      }
      final modelPath = model.path;
      final cachePath = model.parent.path;
      return await Isolate.run(() => _runGemma(modelPath, cachePath, prompt));
    } finally {
      _generating = false;
    }
  }

  static Future<String> _runGemma(
    String modelPath,
    String cachePath,
    String prompt,
  ) async {
    final engine = Engine(
      engineConfig: EngineConfig(
        modelPath: modelPath,
        backend: const Backend.cpu(threadCount: 4),
        maxNumTokens: 1024,
        cacheDir: cachePath,
      ),
    );
    try {
      await engine.initialize();
      final conversation = await engine.createConversation(
        const ConversationConfig(
          automaticToolCalling: false,
          extraContext: {'enable_thinking': false},
          sessionConfig: SessionConfig(
            maxOutputTokens: 100,
            samplerConfig: SamplerConfig(topK: 1, topP: 1, temperature: 0),
          ),
        ),
      );
      try {
        final response = await conversation.sendMessage(Message.user(prompt));
        return response.text;
      } finally {
        await conversation.dispose();
      }
    } finally {
      await engine.dispose();
    }
  }
}
