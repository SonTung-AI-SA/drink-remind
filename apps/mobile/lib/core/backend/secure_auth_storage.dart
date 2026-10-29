import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureAuthStorage extends LocalStorage {
  SecureAuthStorage(this.namespace);
  final String namespace;
  final storage = const FlutterSecureStorage();
  String get key => 'mizu.$namespace.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() => storage.read(key: key);
  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;
  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => storage.delete(key: key);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage(this.namespace);
  final String namespace;
  final storage = const FlutterSecureStorage();
  String prefixed(String key) => 'mizu.$namespace.pkce.$key';
  @override
  Future<String?> getItem({required String key}) =>
      storage.read(key: prefixed(key));
  @override
  Future<void> setItem({required String key, required String value}) =>
      storage.write(key: prefixed(key), value: value);
  @override
  Future<void> removeItem({required String key}) =>
      storage.delete(key: prefixed(key));
}
