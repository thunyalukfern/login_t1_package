import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginT1Service {
  static Future<String?> webAuthT1({
    required String authorizationUrl,
    required String redirectUri,
    required BuildContext context,
  }) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginT1ServiceView(
          authorizationUrl: authorizationUrl,
          redirectUri: redirectUri,
        ),
      ),
    );
    return result;
  }
}

class LoginT1ServiceView extends StatefulWidget {
  const LoginT1ServiceView({
    super.key,
    required this.authorizationUrl,
    required this.redirectUri,
    this.titleAppbar,
    this.titleAppbarStyle,
  });
  final String authorizationUrl;
  final String redirectUri;
  final String? titleAppbar;
  final TextStyle? titleAppbarStyle;

  @override
  State<LoginT1ServiceView> createState() => _LoginT1ServiceViewState();
}

class _LoginT1ServiceViewState extends State<LoginT1ServiceView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(widget.redirectUri)) {
              Navigator.pop(context, url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.titleAppbarStyle ?? ''}'),
        titleTextStyle: widget.titleAppbarStyle,
        backgroundColor: Colors.white,
        leading: SizedBox.shrink(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context); // ปิดหน้านี้
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
