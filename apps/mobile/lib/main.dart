import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/island_app.dart';
import 'app/providers.dart';
import 'core/backend/backend_config.dart';
import 'core/backend/secure_auth_storage.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Be Vietnam Pro'], text);
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  SupabaseClient? client;
  String? backendError;
  if (BackendConfig.configured) {
    try {
      await Supabase.initialize(
        url: BackendConfig.url,
        publishableKey: BackendConfig.publicKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: SecureAuthStorage(BackendConfig.namespace),
          pkceAsyncStorage: SecurePkceStorage(BackendConfig.namespace),
          detectSessionInUriPredicate: (uri) => kIsWeb
              ? uri.origin == Uri.base.origin && uri.path == Uri.base.path
              : uri.scheme == 'com.littleisland.little_island' &&
                    uri.host == 'login-callback',
        ),
      );
      client = Supabase.instance.client;
    } catch (_) {
      backendError = 'Chưa khởi tạo được kết nối tài khoản. Hãy mở lại app; dữ liệu khách vẫn được giữ.';
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        backendClientProvider.overrideWithValue(client),
        backendErrorProvider.overrideWithValue(backendError),
      ],
      child: const IslandApp(),
    ),
  );
}
