import 'dart:math' as math;

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String clockLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

class Preferences {
  const Preferences({
    this.goal = 2000,
    this.startMinute = 480,
    this.endMinute = 1260,
    this.age = 26,
    this.weight = 60,
    this.height = 165,
    this.sex = 'unspecified',
    this.pet = 'cat',
    this.notifications = false,
    this.onboarded = false,
  });

  final int goal, startMinute, endMinute, age;
  final double weight, height;
  final String sex, pet;
  final bool notifications, onboarded;

  Preferences copyWith({
    int? goal,
    int? startMinute,
    int? endMinute,
    int? age,
    double? weight,
    double? height,
    String? sex,
    String? pet,
    bool? notifications,
    bool? onboarded,
  }) => Preferences(
    goal: goal ?? this.goal,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    age: age ?? this.age,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    sex: sex ?? this.sex,
    pet: pet ?? this.pet,
    notifications: notifications ?? this.notifications,
    onboarded: onboarded ?? this.onboarded,
  );

  void validate() {
    if (!['cat', 'dog', 'fish'].contains(pet)) {
      throw const FormatException('Chọn mèo, chó hoặc cá.');
    }
    if (goal < 500 || goal > 5000 || goal % 50 != 0) {
      throw const FormatException('Mục tiêu từ 500–5.000 ml, theo bước 50 ml.');
    }
    if (startMinute < 0 || endMinute > 1439 || endMinute - startMinute < 60) {
      throw const FormatException(
        'Khung giờ nhắc cần ít nhất 1 giờ, trong cùng ngày.',
      );
    }
    if (age < 18 ||
        age > 100 ||
        !weight.isFinite ||
        weight < 30 ||
        weight > 250 ||
        !height.isFinite ||
        height < 100 ||
        height > 230) {
      throw const FormatException(
        'Kiểm tra hồ sơ: tuổi 18–100, cân nặng 30–250 kg, chiều cao 100–230 cm.',
      );
    }
  }
}

class WaterIntake {
  const WaterIntake({
    required this.id,
    required this.amount,
    required this.at,
    required this.day,
    required this.onTime,
  });
  final String id, day;
  final int amount;
  final DateTime at;
  final bool onTime;
}

class ReminderSlot {
  const ReminderSlot(this.at, this.amount);
  final DateTime at;
  final int amount;
  Map<String, Object> toJson() => {
    'at': at.toIso8601String(),
    'amount': amount,
  };
  factory ReminderSlot.fromJson(Map<String, dynamic> value) => ReminderSlot(
    DateTime.parse(value['at'] as String).toLocal(),
    value['amount'] as int,
  );
}

/// Never moves existing reminders just because the screen is rebuilt.
/// Caller persists this plan and recalculates only after a relevant mutation.
List<ReminderSlot> buildReminderPlan({
  required DateTime now,
  required Preferences preferences,
  required int consumed,
  int serving = 250,
}) {
  final remaining = math.max(0, preferences.goal - consumed);
  if (remaining == 0) return [];
  final start = DateTime(
    now.year,
    now.month,
    now.day,
    preferences.startMinute ~/ 60,
    preferences.startMinute % 60,
  );
  final end = DateTime(
    now.year,
    now.month,
    now.day,
    preferences.endMinute ~/ 60,
    preferences.endMinute % 60,
  );
  var first = now.add(const Duration(minutes: 30));
  if (first.isBefore(start)) first = start;
  if (first.isAfter(end)) return [];
  final capacity = end.difference(first).inMinutes ~/ 30 + 1;
  final count = math.min(
    8,
    math.min(capacity, (remaining / serving.clamp(100, 350)).ceil()),
  );
  final perSlot = math.min(350, ((remaining / count / 10).ceil() * 10));
  var left = remaining;
  return List.generate(count, (index) {
    final at = count == 1
        ? first
        : first.add(
            Duration(
              seconds: (end.difference(first).inSeconds * index / (count - 1))
                  .round(),
            ),
          );
    final amount = math.min(left, perSlot);
    left -= amount;
    return ReminderSlot(at, amount);
  });
}

class HydrationSnapshot {
  const HydrationSnapshot({
    required this.preferences,
    required this.intakes,
    required this.goals,
    required this.plans,
  });
  final Preferences preferences;
  final List<WaterIntake> intakes;
  final Map<String, int> goals;
  final Map<String, List<ReminderSlot>> plans;

  List<WaterIntake> onDay(DateTime date) =>
      intakes.where((entry) => entry.day == dayKey(date)).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
  int totalOn(DateTime date) =>
      onDay(date).fold(0, (sum, item) => sum + item.amount);
  int goalOn(DateTime date) => goals[dayKey(date)] ?? preferences.goal;

  /// Max 8 qualifying meals per day, at least 30 min apart, >=100ml,
  /// no more meals after reaching that day's goal. Derived from non-deleted
  /// entries, so undo/retry never increments an independent XP counter.
  int get meals {
    var result = 0;
    final grouped = <String, List<WaterIntake>>{};
    for (final item in intakes) {
      grouped.putIfAbsent(item.day, () => []).add(item);
    }
    for (final day in grouped.keys) {
      final sorted = grouped[day]!..sort((a, b) => a.at.compareTo(b.at));
      DateTime? last;
      var consumed = 0, count = 0;
      for (final item in sorted) {
        if (consumed < (goals[day] ?? preferences.goal) &&
            item.amount >= 100 &&
            count < 8 &&
            (last == null || item.at.difference(last).inMinutes >= 30)) {
          result++;
          count++;
          last = item.at;
        }
        consumed += item.amount;
      }
    }
    return result;
  }

  int streak(DateTime now) {
    var date = DateTime(now.year, now.month, now.day);
    if (totalOn(date) < goalOn(date)) {
      date = date.subtract(const Duration(days: 1));
    }
    var result = 0;
    while (goals.containsKey(dayKey(date)) && totalOn(date) >= goalOn(date)) {
      result++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return result;
  }
}
