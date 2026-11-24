# login_t1_package

Choose the authentication provider with `authProvider`. The default is
`LoginT1AuthProvider.inAppWebView`, so existing callers keep their current flow.

```dart
import 'package:login_t1_package/login_t1_package.dart';

final callbackUrl = await LoginT1Service.webAuthT1(
  authorizationUrl: authorizationUrl,
  redirectUri: 'my-app://callback',
  authProvider: LoginT1AuthProvider.flutterWebAuth2,
  // Defaults to the scheme from redirectUri.
  callbackUrlScheme: 'my-app',
  options: const FlutterWebAuth2Options(preferEphemeral: true),
);
final code = callbackUrl == null
    ? null
    : Uri.parse(callbackUrl).queryParameters['code'];
```

`context` is required for the default in-app provider. The service returns the
callback URL, or `null` when the user cancels. Other plugin errors are propagated.
Appbar and loading parameters apply to the in-app provider.

For `T1Widget`, pass the same selection through its constructor:

```dart
T1Widget(
  controller: controller,
  widgetPath: widgetPath,
  clientId: clientId,
  redirectUri: 'my-app://callback',
  authProvider: LoginT1AuthProvider.flutterWebAuth2,
  callbackUrlScheme: 'my-app',
  authOptions: const FlutterWebAuth2Options(preferEphemeral: true),
  onAuthorizationCode: onAuthorizationCode,
  onTokenExpired: onTokenExpired,
)
```

The identity provider must allow the chosen redirect URI. Configure the consuming
app for [flutter_web_auth_2](https://pub.dev/packages/flutter_web_auth_2#setup).
For a custom scheme on Android, add this activity inside `<application>` in
`android/app/src/main/AndroidManifest.xml` (replace `my-app` with your scheme):

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="my-app" />
    </intent-filter>
</activity>
```

For HTTPS callbacks, configure verified app/universal links and supply
`FlutterWebAuth2Options(httpsHost: 'your-host', httpsPath: '/callback')`.
Web requires a callback HTML page; desktop has additional setup. Follow the
plugin's setup guide for each target platform. Selecting this auth provider does
not change the platform support of the embedded `T1Widget` itself.
