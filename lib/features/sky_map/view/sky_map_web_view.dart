import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mlastro_skymap/features/sky_map/data/sky_map_asset_loader.dart';
import 'package:mlastro_skymap/features/sky_map/data/sky_map_local_server.dart';
import 'package:mlastro_skymap/features/sky_map/logic/sky_map_cubit.dart';
import 'package:mlastro_skymap/utils/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class SkyMapWebView extends StatefulWidget {
  const SkyMapWebView({required this.cubit, super.key});

  final SkyMapCubit cubit;

  @override
  State<SkyMapWebView> createState() => _SkyMapWebViewState();
}

class _SkyMapWebViewState extends State<SkyMapWebView> {
  WebViewController? _controller;
  final _server = SkyMapLocalServer();
  var _progress = 0;
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
    unawaited(_server.stop());
    super.dispose();
  }

  WebViewController _createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    return WebViewController.fromPlatformCreationParams(params);
  }

  void _startReadyWatchdog(WebViewController controller) {
    _readyWatchdog?.cancel();
    _readyWatchdog = Timer(const Duration(seconds: 50), () async {
      if (!mounted || widget.cubit.state.mapReady) return;
      try {
        final jsReady = await controller.runJavaScriptReturningResult(
          'window.MlastroSky && window.MlastroSky.isReady()',
        );
        xLog.e('SkyMap: watchdog — map still not ready (js=$jsReady)');
        widget.cubit.onMapError(
          'Sky map timed out. Check console for SkyMap: logs.',
        );
      } catch (e, st) {
        xLog.e('SkyMap: watchdog probe failed: $e\n$st');
      }
    });
  }

  Future<void> _initWebView() async {
    try {
      xLog.d('SkyMap: starting WebView init');
      final root = await SkyMapAssetLoader.ensureInstalled();
      final baseUrl = await _server.start(root);
      xLog.d('SkyMap: local server at $baseUrl (root=$root)');

      final controller = _createController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF060913))
        ..addJavaScriptChannel(
          'MlastroBridge',
          onMessageReceived: _onBridgeMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
            onPageFinished: (url) {
              xLog.d('SkyMap: page finished $url');
            },
            onHttpError: (error) {
              xLog.e(
                'SkyMap: HTTP ${error.response?.statusCode} '
                '${error.request?.uri}',
              );
            },
            onWebResourceError: (error) {
              final msg = '${error.errorType}: ${error.description} '
                  '(url=${error.url}, code=${error.errorCode})';
              xLog.e('SkyMap: web resource error: $msg');
              widget.cubit.onMapError(msg);
            },
          ),
        );

      if (Platform.isIOS && controller.platform is WebKitWebViewController) {
        final webKit = controller.platform as WebKitWebViewController;
        unawaited(webKit.setAllowsBackForwardNavigationGestures(false));
      }

      widget.cubit.attachWebController(controller);
      _startReadyWatchdog(controller);
      await controller.loadRequest(Uri.parse('${baseUrl}index.html'));

      if (mounted) {
        setState(() => _controller = controller);
      }
    } catch (e, st) {
      xLog.e('SkyMap: WebView init failed: $e\n$st');
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
      widget.cubit.onMapError('Sky map install failed: $e');
    }
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map) return;
      final type = decoded['type']?.toString();
      final payload = decoded['payload'];
      switch (type) {
        case 'ready':
          _readyWatchdog?.cancel();
          unawaited(widget.cubit.onMapReady());
        case 'log':
          if (payload != null) {
            xLog.d('SkyMap JS: $payload');
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
        case 'error':
          if (payload != null) {
            final msg = payload.toString();
            xLog.e('SkyMap: bridge error: $msg');
            widget.cubit.onMapError(msg);
          }
      }
    } catch (e, st) {
      xLog.e(
        'SkyMap: bridge message parse failed: $e\n'
        'raw=${message.message}\n$st',
      );
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
    if (controller == null) {
      return const ColoredBox(color: Color(0xFF060913));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
          },
        ),
        if (_progress < 100)
          LinearProgressIndicator(
            minHeight: 2,
            value: _progress / 100,
            color: const Color(0xFF00E5FF),
            backgroundColor: Colors.transparent,
          ),
      ],
    );
  }
}
