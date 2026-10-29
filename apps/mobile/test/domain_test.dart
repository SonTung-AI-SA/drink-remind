import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/features/hydration/domain/models.dart';

void main() {
  const p = Preferences();
  test('plan respects remaining amount, start/end, spacing, cap', () {
    final now = DateTime(2026, 10, 28, 7);
    final plan = buildReminderPlan(now: now, preferences: p, consumed: 500);
    expect(plan.fold(0, (sum, s) => sum + s.amount), 1500);
    expect(plan.first.at, DateTime(2026, 10, 28, 8));
    expect(plan.last.at, DateTime(2026, 10, 28, 21));
    expect(plan.every((s) => s.amount > 0 && s.amount <= 350), isTrue);
    for (var i = 1; i < plan.length; i++) {
      expect(
        plan[i].at.difference(plan[i - 1].at).inMinutes,
        greaterThanOrEqualTo(30),
      );
    }
  });
  test('late schedule never forces large catch-up', () {
    final plan = buildReminderPlan(
      now: DateTime(2026, 10, 28, 20, 30),
      preferences: p,
      consumed: 0,
    );
    expect(plan.length, 1);
    expect(plan.single.amount, 350);
    expect(
      buildReminderPlan(
        now: DateTime(2026, 10, 28, 21),
        preferences: p,
        consumed: 0,
      ),
      isEmpty,
    );
    expect(
      buildReminderPlan(
        now: DateTime(2026, 10, 28, 9),
        preferences: p,
        consumed: 2200,
      ),
      isEmpty,
    );
  });
  test('rewards have spacing, dose threshold, daily goal guard and undo', () {
    final date = DateTime(2026, 10, 28, 8);
    WaterIntake entry(int minute, int amount) => WaterIntake(
      id: '$minute',
      amount: amount,
      at: date.add(Duration(minutes: minute)),
      day: dayKey(date),
      onTime: true,
    );
    HydrationSnapshot data(List<WaterIntake> entries) => HydrationSnapshot(
      preferences: p,
      intakes: entries,
      goals: {dayKey(date): 500},
      plans: {},
    );
    final entries = [
      entry(0, 250),
      entry(1, 100),
      entry(30, 150),
      entry(60, 250),
    ];
    expect(data(entries).meals, 2);
    expect(data(entries.where((e) => e.id != '0').toList()).meals, 2);
    expect(data([entry(0, 50), entry(1, 100)]).meals, 1);
  });
  test('reward limit is eight per day and history preserves past goals', () {
    final date = DateTime(2026, 10, 28, 8);
    final data = HydrationSnapshot(
      preferences: const Preferences(goal: 5000),
      intakes: List.generate(
        10,
        (i) => WaterIntake(
          id: '$i',
          amount: 100,
          at: date.add(Duration(minutes: i * 30)),
          day: dayKey(date),
          onTime: false,
        ),
      ),
      goals: {dayKey(date): 2000},
      plans: {},
    );
    expect(data.meals, 8);
    expect(data.goalOn(date), 2000);
  });
  test('invalid preferences cannot be saved', () {
    expect(
      () => const Preferences(goal: 2051).validate(),
      throwsFormatException,
    );
    expect(
      () => const Preferences(startMinute: 1200, endMinute: 480).validate(),
      throwsFormatException,
    );
    expect(
      () => const Preferences(weight: double.nan).validate(),
      throwsFormatException,
    );
  });
}
