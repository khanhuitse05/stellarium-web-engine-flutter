import 'package:equatable/equatable.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

/// Abstract bridge controller representing the underlying WebView engine
/// (iOS/Android/macOS via webview_flutter or Windows via webview_windows).
abstract class SkyMapWebBridgeController {
  Future<void> runJavaScript(String script);
  Future<dynamic> runJavaScriptReturningResult(String script);
}

/// Adapter for webview_flutter's [WebViewController].
class FlutterWebViewControllerAdapter implements SkyMapWebBridgeController {
  const FlutterWebViewControllerAdapter(this.controller);
  final WebViewController controller;

  @override
  Future<void> runJavaScript(String script) => controller.runJavaScript(script);

  @override
  Future<dynamic> runJavaScriptReturningResult(String script) =>
      controller.runJavaScriptReturningResult(script);
}

/// Adapter for webview_windows's [WebviewController].
class WindowsWebviewControllerAdapter implements SkyMapWebBridgeController {
  const WindowsWebviewControllerAdapter(this.controller);
  final WebviewController controller;

  @override
  Future<void> runJavaScript(String script) => controller.executeScript(script);

  @override
  Future<dynamic> runJavaScriptReturningResult(String script) =>
      controller.executeScript(script);
}

/// Keyboard event forwarded across the JavaScript bridge when the canvas/window
/// is focused inside the WebView.
class SkyMapKeyEvent extends Equatable {
  const SkyMapKeyEvent({
    required this.code,
    required this.key,
    this.shiftKey = false,
    this.ctrlKey = false,
    this.altKey = false,
  });

  final String code;
  final String key;
  final bool shiftKey;
  final bool ctrlKey;
  final bool altKey;

  bool get isSpace => code == 'Space';
  bool get isEscape => code == 'Escape';
  bool get isArrowUp => code == 'ArrowUp';
  bool get isArrowDown => code == 'ArrowDown';
  bool get isArrowLeft => code == 'ArrowLeft';
  bool get isArrowRight => code == 'ArrowRight';

  factory SkyMapKeyEvent.fromJson(Map<String, dynamic> json) {
    return SkyMapKeyEvent(
      code: json['code']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      shiftKey: json['shiftKey'] == true,
      ctrlKey: json['ctrlKey'] == true,
      altKey: json['altKey'] == true,
    );
  }

  @override
  List<Object?> get props => [code, key, shiftKey, ctrlKey, altKey];
}
