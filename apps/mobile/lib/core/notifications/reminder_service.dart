import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/hydration/domain/models.dart';
import '../../features/pets/domain/pet.dart';

class ReminderService {
  Future<void> _queue = Future.value();
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!supported || initialized) return;
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true) ??
        false;
  }

  Future<void> synchronize(HydrationSnapshot data, DateTime now) {
    final work = _queue.then((_) => _synchronize(data, now));
    _queue = work.catchError((Object _) {});
    return work;
  }

  Future<void> _synchronize(HydrationSnapshot data, DateTime now) async {
    if (!supported) return;
    await initialize();
    // Refresh actual IANA timezone at each relevant update, including foreground.
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.cancelAllPendingNotifications();
    if (!data.preferences.notifications) return;
    final granted = defaultTargetPlatform == TargetPlatform.android
        ? await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled()
        : (await plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled;
    if (granted != true) {
      throw StateError('Notification permission is disabled');
    }
    final slots = <ReminderSlot>[
      ...(data.plans[dayKey(now)] ?? []).where((s) => s.at.isAfter(now)),
    ];
    // Rolling horizon <=56 requests, below the iOS pending-notification limit.
    for (var offset = 1; offset <= 6; offset++) {
      final midnight = DateTime(now.year, now.month, now.day + offset);
      slots.addAll(
        buildReminderPlan(
          now: midnight,
          preferences: data.preferences,
          consumed: 0,
        ),
      );
    }
    await scheduleSlots(slots, data.preferences.pet);
  }

  Future<void> scheduleSlots(
    List<ReminderSlot> slots,
    String pet, {
    int firstId = 1000,
  }) async {
    await initialize();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      await plugin.zonedSchedule(
        id: firstId + i,
        title: 'Một ngụm nước cùng ${petName(pet)}',
        body:
            'Đến giờ uống khoảng ${slot.amount} ml. Chăm mình, nuôi một niềm vui ♡',
        scheduledDate: tz.TZDateTime.from(slot.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders',
            'Nhắc uống nước',
            channelDescription:
                'Những lời nhắc dịu dàng trong khung giờ của bạn',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
