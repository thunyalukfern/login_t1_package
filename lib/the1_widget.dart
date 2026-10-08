import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:login_t1_package/login_t1_package.dart';
import 'package:login_t1_package/t1_widget_controller.dart';

class T1Widget extends StatefulWidget {
  const T1Widget({
    super.key,
    this.clientId,
    this.redirectUri,
    this.scope,
    this.state,
    this.widgetPath,
    this.widgetLang,
    this.loadingWidget,
    this.authProvider = LoginT1AuthProvider.inAppWebView,
    this.callbackUrlScheme,
    this.authOptions = const FlutterWebAuth2Options(),
    this.widgetSize = 140,
    required this.controller,
    required this.onAuthorizationCode,
    required this.onTokenExpired,
  });
  final String? widgetPath;
  final String? clientId;
  final String? redirectUri;
  final String? state;
  final String? scope;
  final String? widgetLang;
  final Widget? loadingWidget;
  final LoginT1AuthProvider authProvider;
  final String? callbackUrlScheme;
  final FlutterWebAuth2Options authOptions;
  final double widgetSize;
  final T1WidgetController controller;
  final Future<void> Function(String code) onAuthorizationCode;
  final Future<void> Function() onTokenExpired;

  @override
  State<T1Widget> createState() => _T1WidgetState();
}

class _T1WidgetState extends State<T1Widget> {
  InAppWebViewController? webViewController;
  String? pendingAccessToken;
  late double _webviewBoxHeight;
  bool _isSdkReady = false;

  @override
  void initState() {
    super.initState();
    _webviewBoxHeight = widget.widgetSize;
    widget.controller.attach(setAccessToken: setAccessTokenToT1Widget);
  }

  @override
  void didUpdateWidget(covariant T1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgetSize != widget.widgetSize) {
      _webviewBoxHeight = widget.widgetSize;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(setAccessToken: setAccessTokenToT1Widget);
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    webViewController = null;
    super.dispose();
  }

  Future<String?> authenticate(String url) async {
    String? codeAuth;
    try {
      if (widget.authProvider == LoginT1AuthProvider.flutterWebAuth2 ||
          [
            TargetPlatform.iOS,
            TargetPlatform.macOS,
            TargetPlatform.android,
          ].contains(defaultTargetPlatform)) {
        final result = await LoginT1Service.webAuthT1(
          authorizationUrl: url,
          redirectUri: widget.redirectUri ?? '',
          context: context,
          loadingWidget: widget.loadingWidget,
          authProvider: widget.authProvider,
          callbackUrlScheme: widget.callbackUrlScheme,
          options: widget.authOptions,
        );
        codeAuth = Uri.parse(result ?? '').queryParameters['code'];
        return codeAuth;
      } else {
        throw Exception("Platform not support!");
      }
    } catch (e) {
      debugPrint('authenticate error: $e');
    }
    return null;
  }

  Future<void> setAccessTokenToT1Widget(String accessToken) async {
    final controller = webViewController;
    if (controller == null || !_isSdkReady) {
      pendingAccessToken = accessToken;
      return;
    }

    await sendAccessTokenToWebView(
      controller: controller,
      accessToken: accessToken,
    );
  }

  Future<void> sendAccessTokenToWebView({
    required InAppWebViewController controller,
    required String accessToken,
  }) async {
    await controller.evaluateJavascript(
      source: 'T1PSDK.setAccessToken(${jsonEncode(accessToken)})',
    );
  }

  Future<void> _sendPendingAccessToken() async {
    final controller = webViewController;
    final accessToken = pendingAccessToken;

    if (controller == null || accessToken == null || !_isSdkReady) {
      return;
    }

    pendingAccessToken = null;

    await sendAccessTokenToWebView(
      controller: controller,
      accessToken: accessToken,
    );
  }

  Future<void> reloadT1Widget() async {
    await webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final baseUri = Uri.parse(widget.widgetPath ?? '');
    final widgetUri = baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'response_type': 'code',
        if (widget.clientId != null) 'client_id': widget.clientId!,
        if (widget.redirectUri != null) 'redirect_uri': widget.redirectUri!,
        if (widget.scope != null) 'scope': widget.scope!,
        if (widget.widgetLang != null) 'lang': widget.widgetLang!,
        if (widget.state != null) 'state': widget.state!,
      },
    );
    return SizedBox(
      height: _webviewBoxHeight,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(widgetUri)),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          underPageBackgroundColor: Colors.white,
        ),
        onWebViewCreated: (controller) async {
          webViewController = controller;
          await controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: 't1psdkjs',
              onPostMessage:
                  (message, sourceOrigin, isMainFrame, replyProxy) async {
                    final expectedOrigin = Uri.tryParse(widgetUri.origin);
                    final messageOrigin = Uri.tryParse(sourceOrigin.toString());
                    if (!isMainFrame ||
                        expectedOrigin == null ||
                        messageOrigin == null ||
                        messageOrigin.origin != expectedOrigin.origin ||
                        message == null) {
                      return;
                    }

                    try {
                      final decoded = jsonDecode(message.data.toString());
                      if (decoded is! Map<String, dynamic>) return;
                      final data = decoded['data'];

                      switch (decoded['event']) {
                        case 'ready':
                          _isSdkReady = true;
                          await _sendPendingAccessToken();
                        case 'widget_size_change':
                          if (data is Map) {
                            final height = double.tryParse(
                              data['height'].toString(),
                            );
                            if (height != null &&
                                height.isFinite &&
                                height > 0) {
                              setState(() => _webviewBoxHeight = height);
                            }
                          }
                        case 'redirect_to_sso':
                          if (data is Map && data['url'] is String) {
                            final authUri = Uri.tryParse(data['url'] as String);
                            if (authUri?.scheme == 'https') {
                              final code = await authenticate(
                                authUri.toString(),
                              );
                              if (code != null) {
                                await widget.onAuthorizationCode(code);
                              }
                            }
                          }
                        case 'token_expired':
                          await widget.onTokenExpired();
                      }
                    } catch (error) {
                      debugPrint('[T1 Widget] invalid message: $error');
                    }
                  },
            ),
          );
        },
        onLoadStop: (controller, url) async {
          await controller.evaluateJavascript(
            source: '''
            document.documentElement.style.backgroundColor = '#FFFFFF';
            document.body.style.backgroundColor = '#FFFFFF';
            document.documentElement.style.colorScheme = 'light';
            document.documentElement.style.fontSize = '18px';
            ''',
          );
          await _sendPendingAccessToken();
        },
        onLoadStart: (controller, url) {
          _isSdkReady = false;
        },
        onConsoleMessage: (controller, message) {
          debugPrint(
            '[WEB][${message.messageLevel}] '
            '${message.message}',
          );
        },
      ),
    );
  }
}
