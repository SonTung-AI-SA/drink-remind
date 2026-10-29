// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:little_island/app/theme.dart';
import 'package:little_island/features/hydration/domain/models.dart';
import 'package:little_island/features/hydration/presentation/today_page.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
    await loader.load();
  });
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(414, 896),
  ]) {
    testWidgets('Record action visible without scroll at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var recorded = false;
      final now = DateTime(2026, 10, 28, 9);
      final data = HydrationSnapshot(
        preferences: const Preferences(),
        intakes: [],
        goals: {dayKey(now): 2000},
        plans: {},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: islandTheme(),
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 96),
                Expanded(
                  child: TodayPage(
                    data: data,
                    now: now,
                    amount: 250,
                    busy: false,
                    pose: 0,
                    message: 'Mình uống nước cùng nhau nhé ♡',
                    onAmount: (_) {},
                    onDrink: () => recorded = true,
                    onCustom: () {},
                    onPet: () {},
                    onSchedule: () {},
                  ),
                ),
                const SizedBox(height: 68),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final button = find.byKey(const Key('record-water'));
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(size.height - 68),
      );
      await tester.tap(button);
      expect(recorded, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
