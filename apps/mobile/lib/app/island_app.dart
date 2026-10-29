import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../features/hydration/domain/models.dart';
import '../features/hydration/presentation/today_page.dart';
import '../features/insights/presentation/history_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/pets/domain/pet.dart';
import 'providers.dart';
import 'theme.dart';

class IslandApp extends ConsumerWidget {
  const IslandApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Little Island',
    debugShowCheckedModeBanner: false,
    theme: islandTheme(),
    home: IslandShell(
      key: ValueKey(ref.watch(accountProvider.select((a) => a.owner))),
    ),
  );
}

class IslandShell extends ConsumerStatefulWidget {
  const IslandShell({super.key});
  @override
  ConsumerState<IslandShell> createState() => _IslandShellState();
}

class _IslandShellState extends ConsumerState<IslandShell>
    with WidgetsBindingObserver {
  int page = 0, amount = 250, pose = 0;
  bool busy = false;
  DateTime now = DateTime.now();
  String message = 'Mình uống nước cùng nhau nhé ♡';
  String? notificationError;
  Timer? ticker, poseTimer;
  Future<void> notificationQueue = Future.value();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
    ticker = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  @override
  void dispose() {
    ticker?.cancel();
    poseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh(reschedule: true));
    }
  }

  Future<void> refresh({bool reschedule = false}) async {
    if (!mounted) return;
    try {
      await ref.read(repositoryProvider).ensureDay();
      if (!mounted) return;
      setState(() => now = DateTime.now());
      if (reschedule) {
        unawaited(ref.read(syncProvider).sync());
        final data = await ref.read(repositoryProvider).snapshot();
        schedule(data);
      }
    } catch (_) {
      if (mounted) notice('Không làm mới được dữ liệu. Hãy thử lại.');
    }
  }

  void notice(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
  }

  void schedule(HydrationSnapshot data) {
    notificationQueue = notificationQueue.then((_) async {
      if (!mounted) return;
      try {
        await ref.read(reminderProvider).synchronize(data, DateTime.now());
        if (mounted && notificationError != null) {
          setState(() => notificationError = null);
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => notificationError = 'Dữ liệu đã lưu. Chưa cập nhật được lịch thông báo; mở app lại hoặc kiểm tra quyền nhắc.',
          );
        }
      }
    });
  }

  Future<void> execute(Future<void> Function() action) async {
    if (!mounted || busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) setState(() => now = DateTime.now());
    } catch (e) {
      notice(
        e is FormatException
            ? e.message
            : 'Chưa lưu được thay đổi. Hãy thử lại.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> drink() => execute(() async {
    final repo = ref.read(repositoryProvider),
        before = await ref.read(repositoryProvider).snapshot();
    final id = await repo.record(amount), after = await repo.snapshot();
    if (!mounted) return;
    final meal = after.meals > before.meals;
    final reachedGoal =
        before.totalOn(now) < before.goalOn(now) &&
        after.totalOn(now) >= after.goalOn(now);
    poseTimer?.cancel();
    setState(() {
      pose = reachedGoal ? 8 : (pose == 3 ? 6 : 3);
      message = meal
          ? 'Măm măm! Cảm ơn bạn nha ♡'
          : 'Mình ghi nhận rồi, bạn làm tốt lắm ♡';
    });
    poseTimer = Timer(Duration(seconds: reachedGoal ? 9 : 3), () {
      if (mounted) {
        setState(() {
          pose = 0;
          message = 'Mình uống nước cùng nhau nhé ♡';
        });
      }
    });
    notice(
      'Đã lưu $amount ml${meal ? ' · ${petName(after.preferences.pet)} được ăn!' : ''}',
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () => execute(() async {
          await repo.delete(id);
          notice('Đã hoàn tác lần uống.');
        }),
      ),
    );
  });

  Future<int?> askAmount({int? initial}) async {
    final controller = TextEditingController(text: initial?.toString() ?? '');
    final form = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dung tích đã uống'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Lượng nước · ml'),
            validator: (value) {
              final n = int.tryParse(value ?? '');
              return n == null || n < 10 || n > 2000
                  ? 'Nhập từ 10 đến 2.000 ml'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 48)),
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(controller.text));
              }
            },
            child: const Text('Chọn'),
          ),
        ],
      ),
    );
    // Dialog exit animations can still reference its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    return result;
  }

  Future<void> edit(WaterIntake intake) async {
    final value = await askAmount(initial: intake.amount);
    if (value == null || !mounted) return;
    await execute(() async {
      await ref.read(repositoryProvider).updateAmount(intake.id, value);
      notice('Đã sửa lần ghi nhận.');
    });
  }

  Future<void> remove(String id) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lần ghi nhận?'),
        content: const Text(
          'Tiến độ nước và bữa ăn của bạn nhỏ sẽ được tính lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await execute(() async {
        await ref.read(repositoryProvider).delete(id);
        notice('Đã xóa lần ghi nhận.');
      });
    }
  }

  Future<void> savePreferences(Preferences p) async {
    await ref.read(repositoryProvider).savePreferences(p);
    if (!mounted) return;
    poseTimer?.cancel();
    setState(() {
      page = 0;
      pose = 0;
      message = 'Mình uống nước cùng nhau nhé ♡';
    });
    notice('Đã lưu mục tiêu và cập nhật lịch uống nước.');
  }

  Future<void> notifications(bool enabled) async {
    final service = ref.read(reminderProvider);
    final allowed = !enabled || await service.requestPermission();
    if (!allowed) {
      notice(
        'Chưa được cấp quyền. Bạn có thể bật nhắc trong cài đặt điện thoại.',
      );
      return;
    }
    final data = await ref.read(repositoryProvider).snapshot();
    await ref
        .read(repositoryProvider)
        .savePreferences(data.preferences.copyWith(notifications: enabled));
    notice(
      enabled ? 'Đã bật lịch nhắc trên điện thoại.' : 'Đã tắt nhắc uống nước.',
    );
  }

  void showSchedule(HydrationSnapshot data) {
    final slots = (data.plans[dayKey(now)] ?? [])
        .where((s) => s.at.isAfter(now))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            children: [
              Text(
                'Nhịp uống nước hôm nay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                data.preferences.notifications
                    ? 'Đã bật lời nhắc trên điện thoại.'
                    : 'Lịch gợi ý. Bật lời nhắc trong mục Cá nhân.',
              ),
              if (slots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    data.totalOn(now) >= data.goalOn(now)
                        ? 'Bạn đã hoàn thành hôm nay. Cùng nghỉ ngơi nhé ♡'
                        : 'Đã hết khung giờ nhắc. Không cần cố uống bù; ngày mai mình cùng bắt đầu lại.',
                  ),
                ),
              for (final slot in slots)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.water_drop_outlined,
                    color: IslandColors.blue,
                  ),
                  title: Text(DateFormat('HH:mm').format(slot.at)),
                  trailing: Text('${slot.amount} ml'),
                ),
              if (slots.isNotEmpty)
                const Text(
                  'Lịch không dồn quá 350 ml/lần. Nếu cuối ngày còn nhiều, app không thúc ép uống bù.',
                  style: TextStyle(fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncProvider);
    ref.listen(hydrationProvider, (_, next) {
      final data = next.asData?.value;
      if (data != null) schedule(data);
    });
    final async = ref.watch(hydrationProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 64,
                  color: IslandColors.blue,
                ),
                SizedBox(height: 14),
                Text(
                  'Little Island',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chưa mở được dữ liệu trên thiết bị.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(hydrationProvider),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            if (!data.preferences.onboarded) {
              return ProfilePage(
                key: const ValueKey('onboarding'),
                preferences: data.preferences,
                onboarding: true,
                onSave: savePreferences,
                onNotifications: notifications,
                notificationsSupported: ref.read(reminderProvider).supported,
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'mizu.',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w700,
                              color: IslandColors.blue,
                              letterSpacing: -1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: IslandColors.sand,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🔥 ${data.streak(now)} ngày cùng nhau',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: switch (page) {
                        0 => TodayPage(
                          data: data,
                          now: now,
                          amount: amount,
                          busy: busy,
                          pose: pose,
                          message: message,
                          onAmount: (value) => setState(() => amount = value),
                          onDrink: drink,
                          onCustom: () async {
                            final value = await askAmount(initial: amount);
                            if (value != null && mounted) {
                              setState(() => amount = value);
                            }
                          },
                          onPet: () {
                            if ([3, 6, 8].contains(pose)) return;
                            setState(() {
                              pose = pose == 4 ? 5 : 4;
                              message =
                                  '${petName(data.preferences.pet)} ở đây cùng bạn ♡';
                            });
                          },
                          onSchedule: () => showSchedule(data),
                        ),
                        1 => HistoryPage(
                          data: data,
                          now: now,
                          onDelete: remove,
                          onEdit: edit,
                        ),
                        _ => ProfilePage(
                          preferences: data.preferences,
                          onSave: savePreferences,
                          onNotifications: notifications,
                          notificationError: notificationError,
                          notificationsSupported: ref
                              .read(reminderProvider)
                              .supported,
                        ),
                      },
                    ),
                    Container(
                      height: 68,
                      decoration: const BoxDecoration(
                        color: IslandColors.surface,
                        border: Border(
                          top: BorderSide(color: IslandColors.border),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) {
                          final name = ['island', 'journey', 'profile'][index];
                          final selected = page == index;
                          return Semantics(
                            label: [
                              'Không gian đảo',
                              'Hành trình',
                              'Cá nhân',
                            ][index],
                            button: true,
                            selected: selected,
                            child: IconButton(
                              key: Key('nav-$name'),
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                setState(() => page = index);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: selected
                                    ? IslandColors.soft
                                    : Colors.transparent,
                                fixedSize: const Size(68, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: ExcludeSemantics(
                                child: SvgPicture.asset(
                                  'assets/icons/navigation/$name${selected ? '-active' : ''}.svg',
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
