import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'machine_media.dart';
import 'machine_model_cache.dart';
import 'machine_model_view.dart';
import 'machine_spin_view.dart';

export 'machine_media.dart' show MachineHotspot;

class MachineViewer360 extends StatefulWidget {
  const MachineViewer360({
    super.key,
    this.modelSrc,
    this.posterImage,
    this.fallbackPosterImage,
    this.spinFrames = const [],
    this.autoRotate = true,
    this.enableAr = false,
    this.iosModelSrc,
    this.backgroundColor,
    this.hotspots = const [],
    this.onLoaded,
    this.onError,
    this.modelBuilder,
  });

  final String? modelSrc;
  final String? posterImage;
  final String? fallbackPosterImage;
  final List<String> spinFrames;
  final bool autoRotate;
  final bool enableAr;
  final String? iosModelSrc;
  final Color? backgroundColor;
  final List<MachineHotspot> hotspots;
  final VoidCallback? onLoaded;
  final ValueChanged<Object>? onError;

  @visibleForTesting
  final Widget Function(MachineModelView model)? modelBuilder;

  @override
  State<MachineViewer360> createState() => _MachineViewer360State();
}

enum _ViewerMode { model, spin, poster }

class _MachineViewer360State extends State<MachineViewer360> {
  static const _hintKey = 'machine-viewer.drag-hint.v1';
  late _ViewerMode _mode = _initialMode();
  bool _loaded = false;
  bool _failed = false;
  bool _showHint = false;
  bool _interacted = false;
  int _generation = 0;
  Timer? _hintTimer;
  VoidCallback? _reset;

  _ViewerMode _initialMode() {
    if (widget.modelSrc?.trim().isNotEmpty ?? false) return _ViewerMode.model;
    return widget.spinFrames.length >= 2
        ? _ViewerMode.spin
        : _ViewerMode.poster;
  }

  @override
  void didUpdateWidget(covariant MachineViewer360 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelSrc != widget.modelSrc ||
        !listEquals(oldWidget.spinFrames, widget.spinFrames)) {
      _mode = _initialMode();
      _generation++;
      _loaded = _failed = _showHint = _interacted = false;
      _reset = null;
      _hintTimer?.cancel();
    }
  }

  void _reportFailure(int generation, Object error) {
    if (!mounted || generation != _generation || _mode == _ViewerMode.poster) {
      return;
    }
    setState(() {
      _mode = _mode == _ViewerMode.model && widget.spinFrames.length >= 2
          ? _ViewerMode.spin
          : _ViewerMode.poster;
      _failed = true;
      _loaded = _showHint = false;
      _reset = null;
      _generation++;
    });
    _hintTimer?.cancel();
    widget.onError?.call(error);
  }

  void _reportLoaded(int generation) {
    if (!mounted || generation != _generation || _loaded) return;
    setState(() => _loaded = true);
    widget.onLoaded?.call();
    unawaited(_maybeShowHint(generation));
  }

  Future<void> _maybeShowHint(int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted ||
          generation != _generation ||
          prefs.getBool(_hintKey) == true) {
        return;
      }
      if (!_interacted) {
        setState(() => _showHint = true);
        _hintTimer = Timer(const Duration(seconds: 4), _interaction);
      }
      await prefs.setBool(_hintKey, true);
    } catch (_) {
      // The viewer still works if preferences are unavailable.
    }
  }

  void _interaction() {
    _interacted = true;
    _hintTimer?.cancel();
    if (mounted && _showHint) setState(() => _showHint = false);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = widget.backgroundColor ?? theme.colorScheme.surface;
    final generation = _generation;
    final interactive = _mode != _ViewerMode.poster;
    final autoRotate =
        widget.autoRotate && !MediaQuery.disableAnimationsOf(context);
    final poster = _MachinePoster(
      source: widget.posterImage,
      fallback: widget.fallbackPosterImage,
    );
    final Widget view;
    switch (_mode) {
      case _ViewerMode.model:
        final model = MachineModelView(
          key: ValueKey(generation),
          source: widget.modelSrc!.trim(),
          backgroundColor: background,
          autoRotate: autoRotate,
          enableAr: widget.enableAr,
          iosModelSrc: widget.iosModelSrc,
          hotspots: widget.hotspots,
          onLoaded: () => _reportLoaded(generation),
          onError: (error) => _reportFailure(generation, error),
          onInteraction: _interaction,
          onResetAvailable: (reset) => _reset = reset,
        );
        view = widget.modelBuilder?.call(model) ?? model;
      case _ViewerMode.spin:
        view = MachineSpinView(
          key: ValueKey(generation),
          frames: widget.spinFrames,
          autoRotate: autoRotate,
          onLoaded: () => _reportLoaded(generation),
          onError: (error) => _reportFailure(generation, error),
          onInteraction: _interaction,
          onResetAvailable: (reset) => _reset = reset,
        );
      case _ViewerMode.poster:
        view = poster;
    }

    return ClipRect(
      child: ColoredBox(
        color: background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            view,
            if (interactive && !_loaded)
              IgnorePointer(
                child: ColoredBox(
                  color: background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      poster,
                      const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Loading 360° view',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showHint)
              const Positioned(
                left: 12,
                top: 12,
                child: IgnorePointer(
                  child: Chip(label: Text('360°  Drag to rotate')),
                ),
              ),
            if (interactive && _loaded)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Reset view',
                  onPressed: () {
                    _interaction();
                    _reset?.call();
                  },
                  icon: const Icon(Icons.replay),
                ),
              ),
            if (!interactive && _failed)
              const Positioned(
                left: 12,
                bottom: 8,
                child: Chip(label: Text('360° view unavailable')),
              ),
          ],
        ),
      ),
    );
  }
}

class _MachinePoster extends StatelessWidget {
  const _MachinePoster({this.source, this.fallback});

  final String? source;
  final String? fallback;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: _image(source, fallback),
  );

  Widget _image(String? source, String? backup) {
    final uri = Uri.tryParse(source ?? '');
    if (source == null ||
        source.isEmpty ||
        uri == null ||
        (uri.hasScheme && !isHttpsAsset(uri))) {
      if (backup != null) return _image(backup, null);
      return const Center(child: Icon(Icons.fitness_center, size: 60));
    }
    final key = ValueKey(source);
    return uri.hasScheme
        ? Image.network(
            source,
            key: key,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _image(backup, null),
          )
        : Image.asset(
            source,
            key: key,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _image(backup, null),
          );
  }
}
