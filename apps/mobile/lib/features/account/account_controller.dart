import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend_config.dart';

class AccountController extends ChangeNotifier {
  AccountController(this.client, {this.initializationError}) {
    user = client?.auth.currentUser;
    subscription = client?.auth.onAuthStateChange.listen(
      (event) {
        user = event.session?.user;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = 'Phiên đăng nhập chưa cập nhật được. Hãy thử lại khi có mạng.';
        notifyListeners();
      },
    );
  }
  final SupabaseClient? client;
  final String? initializationError;
  User? user;
  String? error;
  bool busy = false;
  StreamSubscription<AuthState>? subscription;
  String get owner => user?.id ?? 'local-device';
  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      error = e.code == 'identity_already_exists'
          ? 'Nhà cung cấp này đã thuộc tài khoản khác. Hãy đăng nhập tài khoản đó; dữ liệu chưa được chuyển.'
          : 'Không hoàn tất đăng nhập. Kiểm tra cấu hình nhà cung cấp và thử lại.';
    } catch (_) {
      error = 'Chưa kết nối được. Kiểm tra mạng và thử lại.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> oauth(OAuthProvider provider, {bool link = false}) =>
      perform(() async {
        if (client == null || !BackendConfig.providerEnabled(provider.name)) {
          throw StateError('Provider not configured');
        }
        final opened = link
            ? await client!.auth.linkIdentity(
                provider,
                redirectTo: BackendConfig.callback,
              )
            : await client!.auth.signInWithOAuth(
                provider,
                redirectTo: BackendConfig.callback,
              );
        if (!opened) throw StateError('Browser not opened');
      });
  // Development only. Never creates a user or ships in a release build.
  Future<void> localLogin(String email, String password) => perform(() async {
    if (!BackendConfig.localAuth) throw StateError('Local login disabled');
    final response = await client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
    user = response.user;
  });
  Future<void> signOut() => perform(() async {
    await client!.auth.signOut(scope: SignOutScope.local);
    user = null;
  });
  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}
