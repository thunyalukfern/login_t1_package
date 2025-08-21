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
  });
  final String authorizationUrl;
  final String redirectUri;
  final String? titleAppbar;
  final TextStyle? titleAppbarStyle;
  final Widget? loadingWidget;
  final Color? loadingColor;

  @override
  State<LoginThe1Screen> createState() => _LoginThe1ScreenState();
}

class _LoginThe1ScreenState extends State<LoginThe1Screen> {
  bool isLoading = false;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(true);

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
              initialSettings: InAppWebViewSettings(sharedCookiesEnabled: true),
              initialUrlRequest: URLRequest(
                url: WebUri(widget.authorizationUrl),
              ),
              onWebViewCreated: (controller) {
                // เก็บ controller ไว้ใช้ เช่น reload, goBack
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var url = navigationAction.request.url.toString();

                // ✅ ตรวจจับ redirect
                if (url.startsWith(widget.redirectUri)) {
                  Navigator.pop(context, url); // ส่งค่ากลับ
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
