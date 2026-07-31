class T1WidgetController {
  Future<void> Function(String accessToken)? _setAccessTokenHandler;

  void attach({
    required Future<void> Function(String accessToken) setAccessToken,
  }) {
    _setAccessTokenHandler = setAccessToken;
  }

  void detach() {
    _setAccessTokenHandler = null;
  }

  Future<void> setAccessToken(String accessToken) async {
    final handler = _setAccessTokenHandler;
    if (handler == null) {
      throw StateError('T1 widget is not ready');
    }
    await handler(accessToken);
  }
}
