import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_t1_package/login_t1_package.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_web_auth_2');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<String?> authenticate({String? scheme}) => LoginT1Service.webAuthT1(
    authorizationUrl: 'https://example.com/authorize',
    redirectUri: 'my-app://callback',
    authProvider: LoginT1AuthProvider.flutterWebAuth2,
    callbackUrlScheme: scheme,
    options: const FlutterWebAuth2Options(preferEphemeral: true),
  );

  test(
    'uses native authentication without context and forwards configuration',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'authenticate') return null;
        expect(call.arguments['url'], 'https://example.com/authorize');
        expect(call.arguments['callbackUrlScheme'], 'my-app');
        expect(call.arguments['options']['preferEphemeral'], true);
        return 'my-app://callback?code=abc';
      });
      expect(await authenticate(), 'my-app://callback?code=abc');
    },
  );

  test('cancellation returns null', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'authenticate')
        throw PlatformException(code: 'CANCELED');
      return null;
    });
    expect(await authenticate(), isNull);
  });

  test('other platform failures propagate', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'authenticate')
        throw PlatformException(code: 'FAILED');
      return null;
    });
    await expectLater(authenticate(), throwsA(isA<PlatformException>()));
  });

  test('invalid scheme is rejected', () async {
    await expectLater(authenticate(scheme: 'bad_scheme'), throwsArgumentError);
  });

  test('default provider requires context', () async {
    await expectLater(
      LoginT1Service.webAuthT1(
        authorizationUrl: 'https://example.com/authorize',
        redirectUri: 'my-app://callback',
      ),
      throwsArgumentError,
    );
  });
}
