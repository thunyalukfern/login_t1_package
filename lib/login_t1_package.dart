import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

export 'package:flutter_web_auth_2/flutter_web_auth_2.dart'
    show FlutterWebAuth2Options;
import 'package:login_t1_package/view.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Selects how the authorization page is presented.
enum LoginT1AuthProvider { inAppWebView, flutterWebAuth2 }

class LoginT1Service {
  static Future<String?> webAuthT1({
    required String authorizationUrl,
    required String redirectUri,
    BuildContext? context,
    LoginT1AuthProvider authProvider = LoginT1AuthProvider.inAppWebView,
    String? callbackUrlScheme,
    FlutterWebAuth2Options options = const FlutterWebAuth2Options(),
    String? titleAppbar,
    TextStyle? titleAppbarStyle,
    Widget? loadingWidget,
    Color? loadingColor,
    bool? isRoot,
  }) async {
    if (authProvider == LoginT1AuthProvider.flutterWebAuth2) {
      final scheme = callbackUrlScheme ?? Uri.parse(redirectUri).scheme;
      if (!RegExp(r'^[a-z][a-z0-9+.-]*$').hasMatch(scheme)) {
        throw ArgumentError.value(
          scheme,
          'callbackUrlScheme',
          'Invalid scheme',
        );
      }
      try {
        return await FlutterWebAuth2.authenticate(
          url: authorizationUrl,
          callbackUrlScheme: scheme,
          options: options,
        );
      } on PlatformException catch (error) {
        if (error.code == 'CANCELED') return null;
        rethrow;
      }
    }
    if (context == null) {
      throw ArgumentError(
        'context is required for inAppWebView authentication',
      );
    }
    var result = isRoot == true
        ? await Navigator.of(context, rootNavigator: isRoot ?? false).push(
            MaterialPageRoute(
              builder: (context) => LoginThe1Screen(
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
              builder: (context) => LoginThe1Screen(
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
  bool isLoading = false;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _loadingNotifier.value = true;
          },
          onPageFinished: (url) {
            _loadingNotifier.value = false;
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
        child: Stack(
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
            ValueListenableBuilder<bool>(
              valueListenable: _loadingNotifier,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child:
                        widget.loadingWidget ??
                        CircularProgressIndicator(
                          color: widget.loadingColor ?? Colors.black,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
