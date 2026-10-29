// Standalone debug entry for emulator lifecycle checks, never used by app main.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:little_island/core/notifications/reminder_service.dart';
import 'package:little_island/features/hydration/domain/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode) throw StateError('Debug probe only');
  final service = ReminderService();
  await service.initialize();
  tz.setLocalLocation(
    tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
  );
  await service.plugin.cancelAll();
  const mode = String.fromEnvironment('PROBE_MODE', defaultValue: 'closed');
  // Reboot/zone tests use a distant slot to inspect restoration without waiting
  // for the OS's inexact batching window. Delivery is checked separately.
  final delay = mode == 'closed'
      ? const Duration(seconds: 15)
      : const Duration(hours: 4);
  final at = DateTime.now().add(delay);
  await service.scheduleSlots([ReminderSlot(at, 150)], 'dog', firstId: 9101);
  debugPrint('MIZU_PROBE_READY mode=$mode');
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Kiểm thử thông báo · $mode\nLịch thử đã lưu.'),
        ),
      ),
    ),
  );
}
