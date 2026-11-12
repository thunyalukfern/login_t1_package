import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoginThe1Screen extends StatefulWidget {
  const LoginThe1Screen({
    super.key,
    required this.authorizationUrl,
    required this.redirectUri,
    this.titleAppbar,
    this.titleAppbarStyle,
    this.loadingColor,
    this.loadingWidget,
    this.callbackLoadingWidget,
    this.onRedirect,
  });
  final String authorizationUrl;
  final String redirectUri;
  final String? titleAppbar;
  final TextStyle? titleAppbarStyle;
  final Widget? loadingWidget;
  final Color? loadingColor;

  /// Loading shown while [onRedirect] is running. Falls back to [loadingWidget].
  final Widget? callbackLoadingWidget;

  /// Called with the redirect URL before the screen is closed.
  /// The screen stays open showing [callbackLoadingWidget] until it completes.
  final Future<void> Function(String url)? onRedirect;

  @override
  State<LoginThe1Screen> createState() => _LoginThe1ScreenState();
}

class _LoginThe1ScreenState extends State<LoginThe1Screen> {
  bool isLoading = false;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _callbackLoadingNotifier = ValueNotifier(false);
  bool _redirectHandled = false;

  @override
  void dispose() {
    _loadingNotifier.dispose();
    _callbackLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleRedirect(String url) async {
    _callbackLoadingNotifier.value = true;
    try {
      await widget.onRedirect?.call(url);
    } catch (e) {
      debugPrint('[T1 Login] redirect callback failed (${e.runtimeType})');
    } finally {
      if (mounted) Navigator.pop(context, url); // ส่งค่ากลับ
    }
  }

  Widget _buildLoading(Widget? loadingWidget) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child:
            loadingWidget ??
            CircularProgressIndicator(
              color: widget.loadingColor ?? Colors.black,
            ),
      ),
    );
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
            InAppWebView(
              initialSettings: InAppWebViewSettings(
                sharedCookiesEnabled: true,
                thirdPartyCookiesEnabled: true,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) async {
                Future.microtask(() {
                  controller.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(widget.authorizationUrl),
                    ),
                  );
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var url = navigationAction.request.url.toString();
                if (url.startsWith(widget.redirectUri)) {
                  if (!_redirectHandled) {
                    _redirectHandled = true;
                    _handleRedirect(url);
                  }
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onPermissionRequest: (controller, permissionRequest) async {
                return PermissionResponse(
                  resources: permissionRequest.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onLoadStart: (controller, url) {
                _loadingNotifier.value = true;
              },
              onLoadStop: (controller, url) async {
                _loadingNotifier.value = false;
              },
              onProgressChanged: (controller, progress) {
                _loadingNotifier.value = progress < 100;
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _callbackLoadingNotifier,
              builder: (context, isCallbackLoading, child) {
                // ซ่อนปุ่มปิดระหว่าง callback เพื่อไม่ให้ pop ซ้ำ
                if (isCallbackLoading) return const SizedBox.shrink();
                return child!;
              },
              child: Positioned(
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
            ),
            // Loading ตอนเข้าหน้า
            ValueListenableBuilder<bool>(
              valueListenable: _loadingNotifier,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SizedBox.shrink();
                return _buildLoading(widget.loadingWidget);
              },
            ),
            // Loading ตอน callback (อยู่บนสุด)
            ValueListenableBuilder<bool>(
              valueListenable: _callbackLoadingNotifier,
              builder: (context, isCallbackLoading, _) {
                if (!isCallbackLoading) return const SizedBox.shrink();
                return _buildLoading(
                  widget.callbackLoadingWidget ?? widget.loadingWidget,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
