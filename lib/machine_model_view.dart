import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'machine_media.dart';
import 'machine_model_cache.dart';

class MachineModelView extends StatefulWidget {
  const MachineModelView({
    super.key,
    required this.source,
    required this.backgroundColor,
    required this.autoRotate,
    required this.enableAr,
    required this.iosModelSrc,
    required this.hotspots,
    required this.onLoaded,
    required this.onError,
    required this.onInteraction,
    required this.onResetAvailable,
  });

  final String source;
  final Color backgroundColor;
  final bool autoRotate;
  final bool enableAr;
  final String? iosModelSrc;
  final List<MachineHotspot> hotspots;
  final VoidCallback onLoaded;
  final ValueChanged<Object> onError;
  final VoidCallback onInteraction;
  final ValueChanged<VoidCallback> onResetAvailable;

  @override
  State<MachineModelView> createState() => _MachineModelViewState();
}

class _MachineModelViewState extends State<MachineModelView> {
  static const _orbit = '35deg 74deg auto';
  static const _fieldOfView = '33deg';
  String? _source;
  WebViewController? _controller;
  Timer? _timeout;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepare());
    });
  }

  Future<void> _prepare() async {
    try {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        throw UnsupportedError('3D viewing requires a mobile WebView.');
      }
      final file = await resolveMachineModel(
        widget.source,
      ).timeout(const Duration(seconds: 35));
      if (!mounted) return;
      setState(() => _source = file);
      _timeout = Timer(
        const Duration(seconds: 25),
        () => _fail(TimeoutException('The 3D viewer did not load.')),
      );
    } catch (error) {
      if (mounted) _fail(error);
    }
  }

  void _fail(Object error) {
    if (_failed) return;
    _failed = true;
    _timeout?.cancel();
    widget.onError(error);
  }

  Future<void> _reset() async {
    try {
      await _controller?.runJavaScript('window.resetMachineView?.()');
    } catch (error) {
      if (mounted) _fail(error);
    }
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted || _failed) return;
    switch (message.message) {
      case 'loaded':
        if (_loaded) return;
        _loaded = true;
        _timeout?.cancel();
        widget.onResetAvailable(() => unawaited(_reset()));
        widget.onLoaded();
      case 'touch':
        widget.onInteraction();
      case 'error':
        _fail(StateError('The WebView could not render this model.'));
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _source;
    if (file == null) return const SizedBox.expand();
    final iosModel = widget.iosModelSrc;
    final supportsQuickLook = isHttpsAsset(Uri.tryParse(iosModel ?? ''));
    final ar =
        widget.enableAr &&
        (defaultTargetPlatform == TargetPlatform.android
            ? isHttpsAsset(Uri.tryParse(widget.source))
            : supportsQuickLook);

    final colors = Theme.of(context).colorScheme;
    return ModelViewer(
      src: file,
      alt: 'Interactive 3D machine model',
      loading: Loading.eager,
      backgroundColor: widget.backgroundColor,
      ar: ar,
      arModes: const ['scene-viewer', 'quick-look'],
      arScale: ArScale.fixed,
      iosSrc: ar && supportsQuickLook ? iosModel : null,
      cameraOrbit: _orbit,
      minCameraOrbit: 'auto 58deg auto',
      maxCameraOrbit: 'auto 86deg auto',
      fieldOfView: _fieldOfView,
      minFieldOfView: '28deg',
      maxFieldOfView: '43deg',
      disablePan: true,
      disableTap: true,
      touchAction: TouchAction.none,
      interactionPrompt: InteractionPrompt.none,
      autoRotate: widget.autoRotate,
      autoRotateDelay: 0,
      rotationPerSecond: '10deg',
      debugLogging: false,
      onWebViewCreated: (controller) => _controller = controller,
      javascriptChannels: {
        JavascriptChannel('MachineViewer', onMessageReceived: _onMessage),
      },
      innerModelViewerHtml: _html(ar),
      relatedCss:
          '''
        .hotspot, #ar-action {
          background: ${_cssColor(colors.surface)};
          color: ${_cssColor(colors.onSurface)};
          border: 1px solid ${_cssColor(colors.outline)};
          padding: 6px 10px;
          border-radius: 12px;
          font: 14px system-ui, sans-serif;
        }
        .hotspot:not([data-visible]) { visibility: hidden; }
        .hotspot summary { cursor: pointer; }
        #ar-action { position: absolute; left: 12px; bottom: 12px; }
      ''',
      relatedJs: _script,
    );
  }

  String _cssColor(Color color) =>
      '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

  String _html(bool ar) {
    final html = StringBuffer();
    if (ar) {
      html.write(
        '<button id="ar-action" slot="ar-button">View in your space</button>',
      );
    }
    for (final (index, spot) in widget.hotspots.indexed) {
      final position = htmlEscape.convert(spot.position);
      final normal = htmlEscape.convert(spot.normal);
      final label = htmlEscape.convert(spot.label);
      final detail = htmlEscape.convert(spot.description ?? spot.label);
      html.write(
        '<details class="hotspot" slot="hotspot-$index" '
        'data-position="$position" data-normal="$normal">'
        '<summary>$label</summary><p>$detail</p></details>',
      );
    }
    return html.toString();
  }

  String get _script =>
      '''
    const viewer = document.querySelector('model-viewer');
    const send = message => window.MachineViewer?.postMessage(message);
    viewer.addEventListener('load', () => send('loaded'));
    viewer.addEventListener('error', () => send('error'));
    if (viewer.loaded) send('loaded');

    const shouldRotate = ${widget.autoRotate};
    const active = new Set();
    let idle;
    const pause = () => {
      clearTimeout(idle);
      viewer.removeAttribute('auto-rotate');
    };
    const resume = () => {
      clearTimeout(idle);
      if (shouldRotate && active.size === 0) {
        idle = setTimeout(() => viewer.setAttribute('auto-rotate', ''), 3000);
      }
    };
    viewer.addEventListener('pointerdown', event => {
      active.add(event.pointerId);
      pause();
      send('touch');
    }, {capture: true});
    const release = event => {
      if (active.delete(event.pointerId)) resume();
    };
    window.addEventListener('pointerup', release, {capture: true});
    window.addEventListener('pointercancel', release, {capture: true});
    window.addEventListener('blur', () => { active.clear(); resume(); });

    window.resetMachineView = async () => {
      pause();
      viewer.resetTurntableRotation?.();
      viewer.cameraOrbit = '$_orbit';
      viewer.fieldOfView = '$_fieldOfView';
      await viewer.updateComplete;
      viewer.jumpCameraToGoal();
      resume();
    };
  ''';
}
