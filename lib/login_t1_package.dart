import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginT1Service {
  static Future<String?> webAuthT1({
    required String authorizationUrl,
    required String redirectUri,
    required BuildContext context,
    String? titleAppbar,
    TextStyle? titleAppbarStyle,
    Widget? loadingWidget,
    Color? loadingColor,
    bool? isRoot,
  }) async {
    var result = isRoot == true
        ? await Navigator.of(context, rootNavigator: isRoot ?? false).push(
            MaterialPageRoute(
              builder: (context) => LoginT1ServiceView(
                authorizationUrl: authorizationUrl,
                redirectUri: redirectUri,
                titleAppbar: titleAppbar,
                titleAppbarStyle: titleAppbarStyle,
                loadingColor: loadingColor,
                loadingWidget: loadingWidget,
              ),
            ),
          )
        : await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginT1ServiceView(
                authorizationUrl: authorizationUrl,
                redirectUri: redirectUri,
                titleAppbar: titleAppbar,
                titleAppbarStyle: titleAppbarStyle,
                loadingColor: loadingColor,
                loadingWidget: loadingWidget,
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
    this.loadingColor,
    this.loadingWidget,
  });
  final String authorizationUrl;
  final String redirectUri;
  final String? titleAppbar;
  final TextStyle? titleAppbarStyle;
  final Widget? loadingWidget;
  final Color? loadingColor;

  @override
  State<LoginT1ServiceView> createState() => _LoginT1ServiceViewState();
}

class _LoginT1ServiceViewState extends State<LoginT1ServiceView> {
  late final WebViewController _controller;
  bool isLoading = true; // 👈 เพิ่ม state loading

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
          },
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        maintainBottomViewPadding: false,
        child: isLoading == true
            ? Center(
                child:
                    widget.loadingWidget ??
                    CircularProgressIndicator(
                      color: widget.loadingColor ?? Colors.black,
                    ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: Icon(Icons.close, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
