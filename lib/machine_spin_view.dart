import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'machine_model_cache.dart';

class MachineSpinView extends StatefulWidget {
  const MachineSpinView({
    super.key,
    required this.frames,
    required this.autoRotate,
    required this.onLoaded,
    required this.onError,
    required this.onInteraction,
    required this.onResetAvailable,
  });

  final List<String> frames;
  final bool autoRotate;
  final VoidCallback onLoaded;
  final ValueChanged<Object> onError;
  final VoidCallback onInteraction;
  final ValueChanged<VoidCallback> onResetAvailable;

  @override
  State<MachineSpinView> createState() => _MachineSpinViewState();
}

class _MachineSpinViewState extends State<MachineSpinView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;
  List<ImageProvider>? _frames;
  double _zoom = 1;
  double _startZoom = 1;
  bool _preparing = false;
  final _pointers = <int>{};
  Timer? _idle, _spin;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController.unbounded(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preparing) return;
    _preparing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_precache());
    });
  }

  Future<void> _precache() async {
    try {
      final assets = await AssetManifest.loadFromAssetBundle(
        DefaultAssetBundle.of(context),
      );
      if (!mounted) return;
      final frames = widget.frames.map((source) {
        final uri = Uri.parse(source);
        final ImageProvider image;
        if (!uri.hasScheme && source.startsWith('assets/')) {
          if (assets.getAssetVariants(source) == null) {
            throw FormatException('Missing spin frame: $source');
          }
          image = AssetImage(source);
        } else if (isHttpsAsset(uri)) {
          image = NetworkImage(source);
        } else {
          throw const FormatException(
            'Spin frames must be assets or HTTPS images.',
          );
        }
        return ResizeImage.resizeIfNeeded(640, null, image);
      }).toList();
      for (final frame in frames) {
        await _warm(frame).timeout(const Duration(seconds: 15));
        if (!mounted) return;
      }
      setState(() => _frames = frames);
      widget.onResetAvailable(_reset);
      widget.onLoaded();
      _startAutoRotate();
    } catch (error) {
      if (mounted) widget.onError(error);
    }
  }

  Future<void> _warm(ImageProvider frame) async {
    Object? failure;
    await precacheImage(frame, context, onError: (error, _) => failure = error);
    final error = failure;
    if (error != null) throw error;
  }

  void _startAutoRotate() {
    if (!widget.autoRotate) return;
    _spin = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_turn.isAnimating) _turn.value += .003;
    });
  }

  void _pause() {
    _turn.stop();
    _idle?.cancel();
    _spin?.cancel();
  }

  void _resumeLater() {
    _idle?.cancel();
    if (widget.autoRotate) {
      _idle = Timer(const Duration(seconds: 3), _startAutoRotate);
    }
  }

  void _pointerUp(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isEmpty) _resumeLater();
  }

  void _reset() {
    _pause();
    _turn.value = 0;
    setState(() => _zoom = 1);
    _resumeLater();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _spin?.cancel();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = _frames;
    if (frames == null) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, size) {
        final width = size.maxWidth;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _pointers.add(event.pointer);
            _pause();
            widget.onInteraction();
          },
          onPointerUp: (event) => _pointerUp(event.pointer),
          onPointerCancel: (event) => _pointerUp(event.pointer),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) {
              _startZoom = _zoom;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount > 1) {
                setState(
                  () => _zoom = (_startZoom * details.scale).clamp(.8, 1.25),
                );
              } else if (width > 0) {
                _turn.value += details.focalPointDelta.dx / width;
              }
            },
            onScaleEnd: (details) {
              final speed = width > 0
                  ? details.velocity.pixelsPerSecond.dx / width
                  : 0.0;
              if (details.pointerCount == 0 && speed.abs() > .28) {
                unawaited(
                  _turn.animateWith(
                    FrictionSimulation(.1, _turn.value, speed.clamp(-2.0, 2.0)),
                  ),
                );
              }
            },
            child: Center(
              child: FractionallySizedBox(
                heightFactor: .8,
                widthFactor: .8,
                child: Transform.scale(
                  scale: _zoom,
                  child: AnimatedBuilder(
                    animation: _turn,
                    builder: (context, _) {
                      final index =
                          (_turn.value * frames.length).round() % frames.length;
                      return Image(
                        key: ValueKey(widget.frames[index]),
                        image: frames[index],
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) widget.onError(error);
                          });
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
