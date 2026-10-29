import 'package:flutter/foundation.dart';

class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publicKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const oauthProviders = String.fromEnvironment('OAUTH_PROVIDERS');
  static const nativeCallback =
      'com.littleisland.little_island://login-callback/';
  static bool get configured => url.isNotEmpty && publicKey.isNotEmpty;
  static String get namespace =>
      Uri.parse(url).authority.replaceAll(RegExp('[^a-zA-Z0-9]'), '_');
  static String get callback => kIsWeb
      ? Uri.base.replace(query: '', fragment: '').toString()
      : nativeCallback;
  static bool get localAuth =>
      !kReleaseMode &&
      const bool.fromEnvironment('ALLOW_LOCAL_AUTH') &&
      ['localhost', '127.0.0.1', '10.0.2.2'].contains(Uri.tryParse(url)?.host);
  static bool providerEnabled(String name) =>
      configured && oauthProviders.split(',').contains(name);
}
