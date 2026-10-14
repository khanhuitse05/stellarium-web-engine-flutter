import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mlastro_skymap/features/sky_map/data/sky_map_asset_loader.dart';
import 'package:mlastro_skymap/features/sky_map/data/sky_map_local_server.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/utils/logger.dart';
import 'package:webview_windows/webview_windows.dart';

/// Windows desktop implementation of the Sky Map WebView host using Microsoft WebView2
/// (texture-backed direct DirectX surface via `webview_windows`).
class SkyMapWindowsWebView extends StatefulWidget {
  const SkyMapWindowsWebView({required this.cubit, super.key});

  final SkyMapCubit cubit;

  @override
  State<SkyMapWindowsWebView> createState() => _SkyMapWindowsWebViewState();
}

class _SkyMapWindowsWebViewState extends State<SkyMapWindowsWebView> {
  WebviewController? _controller;
  final _server = SkyMapLocalServer();
  StreamSubscription<dynamic>? _msgSub;
  StreamSubscription<LoadingState>? _loadingSub;
  String? _loadError;
  Timer? _readyWatchdog;

  @override
  void initState() {
    super.initState();
    unawaited(_initWebView());
  }

  @override
  void dispose() {
    _readyWatchdog?.cancel();
    _msgSub?.cancel();
    _loadingSub?.cancel();
    unawaited(_controller?.dispose());
    unawaited(_server.stop());
    super.dispose();
  }

  void _startReadyWatchdog(WebviewController controller) {
    _readyWatchdog?.cancel();
    _readyWatchdog = Timer(const Duration(seconds: 40), () async {
      if (!mounted || widget.cubit.state.mapReady) return;
      try {
        final jsReady = await controller.executeScript(
          'window.MlastroSky && window.MlastroSky.isReady()',
        );
        xLog.e('SkyMap Windows: watchdog — map still not ready (js=$jsReady)');
        widget.cubit.onMapError(
          'Sky map loading timed out. Check %TEMP%\\mlastro_app.log for details.',
        );
      } catch (e, st) {
        xLog.e('SkyMap Windows: watchdog probe failed: $e\n$st');
      }
    });
  }

  Future<void> _initWebView() async {
    try {
      xLog.d('SkyMap Windows: checking WebView2 runtime');
      final version = await WebviewController.getWebViewVersion();
      if (version == null) {
        throw StateError(
          'Microsoft Edge WebView2 Runtime is not installed on this PC.\n'
          'Please install WebView2 Runtime to view the Sky Map.',
        );
      }
      xLog.d('SkyMap Windows: WebView2 version: $version');

      xLog.d('SkyMap Windows: ensuring assets installed');
      final root = await SkyMapAssetLoader.ensureInstalled();
      final baseUrl = await _server.start(root);
      xLog.d('SkyMap Windows: local server at $baseUrl (root=$root)');

      final controller = WebviewController();
      await controller.initialize();
      await controller.setBackgroundColor(const Color(0xFF060913));

      _msgSub = controller.webMessage.listen(_onWebMessage);
      _loadingSub = controller.loadingState.listen((loadingState) {
        if (loadingState == LoadingState.navigationCompleted) {
          xLog.d('SkyMap Windows: navigation completed');
        }
      });

      widget.cubit.attachWebController(
        WindowsWebviewControllerAdapter(controller),
      );
      _startReadyWatchdog(controller);

      // Mount controller into the widget tree immediately so surface size is
      // reported to WebView2 before the web page starts loading scripts.
      if (mounted) {
        setState(() => _controller = controller);
      }

      await controller.loadUrl('${baseUrl}index.html');
    } catch (e, st) {
      xLog.e('SkyMap Windows: WebView2 init failed: $e\n$st');
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
      widget.cubit.onMapError('Sky map Windows init failed: $e');
    }
  }

  void _onWebMessage(dynamic raw) {
    try {
      dynamic parsed = raw;
      if (parsed is String) {
        try {
          parsed = jsonDecode(parsed);
        } catch (_) {}
      }
      if (parsed is String) {
        try {
          parsed = jsonDecode(parsed);
        } catch (_) {}
      }
      if (parsed is! Map) {
        xLog.w('SkyMap Windows: unexpected web message: $raw');
        return;
      }
      final Map<dynamic, dynamic> decoded = parsed;

      final type = decoded['type']?.toString();
      final payload = decoded['payload'];

      switch (type) {
        case 'ready':
          _readyWatchdog?.cancel();
          unawaited(widget.cubit.onMapReady());
        case 'log':
          if (payload != null) {
            xLog.d('SkyMap JS (Win): $payload');
          }
        case 'select':
          if (payload is Map) {
            widget.cubit.onObjectSelected(Map<String, dynamic>.from(payload));
          }
        case 'long_press':
          if (payload is Map) {
            widget.cubit.onSkyPointLongPress(Map<String, dynamic>.from(payload));
          }
        case 'limit_line_tap':
          if (payload is Map) {
            widget.cubit.onLimitLineTap(Map<String, dynamic>.from(payload));
          }
        case 'user_pan':
          widget.cubit.onUserPan();
        case 'follow_telescope_changed':
          if (payload is bool) {
            widget.cubit.onFollowTelescopeChanged(payload);
          }
        case 'key_down':
          if (payload is Map) {
            widget.cubit.onKeyDown(Map<String, dynamic>.from(payload));
          }
        case 'error':
          if (payload != null) {
            final msg = payload.toString();
            xLog.e('SkyMap JS (Win) error: $msg');
            widget.cubit.onMapError(msg);
          }
      }
    } catch (e, st) {
      xLog.e('SkyMap Windows: bridge message error: $e\nraw=$raw\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Color(0xFF060913));
    }

    return Webview(controller);
  }
}
