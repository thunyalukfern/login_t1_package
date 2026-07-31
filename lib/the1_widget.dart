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
    required this.controller,
    required this.onAuthorizationCode,
  });
  final String? widgetPath;
  final String? clientId;
  final String? redirectUri;
  final String? state;
  final String? scope;
  final String? widgetLang;
  final Widget? loadingWidget;
  final T1WidgetController controller;
  final Future<void> Function(String code) onAuthorizationCode;

  @override
  State<T1Widget> createState() => _T1WidgetState();
}

class _T1WidgetState extends State<T1Widget> {
  InAppWebViewController? webViewController;
  String? pendingAccessToken;

  Future<String?> authenticate(String url) async {
    String? codeAuth;
    try {
      if ([
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
        final result = await LoginT1Service.webAuthT1(
          authorizationUrl: url,
          redirectUri: widget.redirectUri ?? '',
          context: context,
          loadingWidget: widget.loadingWidget,
        );
        codeAuth = Uri.parse(result ?? '').queryParameters['code'];
        return codeAuth;
      } else {
        throw Exception("Platform not support!");
      }
    } catch (e) {
      print("authenticate error: $e");
    }
    return null;
  }

  Future<void> setAccessTokenToT1Widget(String accessToken) async {
    final controller = webViewController;
    if (controller == null) {
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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sendPendingAccessToken() async {
    final controller = webViewController;
    final accessToken = pendingAccessToken;

    if (controller == null || accessToken == null) {
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
    String? widgetUrl =
        '${widget.widgetPath}'
        'client_id=${widget.clientId}&'
        'response_type=code&'
        'redirect_uri=${widget.redirectUri}&'
        'state=${widget.state}&'
        'scope=${widget.scope}&'
        'lang=${widget.widgetLang}';
    return SizedBox(
      height: 140,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(widgetUrl))),
        onWebViewCreated: (controller) async {
          webViewController = controller;

          await controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: 't1psdkjs',
              onPostMessage:
                  (message, sourceOrigin, isMainFrame, replyProxy) async {
                    debugPrint('[T1 Widget] message: ${message?.data}');
                    if (message != null) {
                      final data = jsonDecode(message.data.toString());
                      if (data["event"] == "ready") {
                      } else if (data["event"] == "widget_size_change") {
                      } else if (data["event"] == "widget_size_changed") {
                      } else if (data["event"] == "redirect_to_sso") {
                        var url = data["data"]["url"];
                        await authenticate(url).then((value) async {
                          if (value != null) {
                            await widget.onAuthorizationCode(value);
                          }
                        });
                      }
                    }
                  },
            ),
          );
        },
        onLoadStop: (controller, url) async {
          await _sendPendingAccessToken();
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
