import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/features/pets/presentation/island_scene.dart';
import 'package:little_island/features/pets/presentation/daily_reward.dart';
import 'package:little_island/features/hydration/domain/models.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf')))
        .load();
  });
  test('completed history does not grant a reward on the next local day', () {
    final today = DateTime(2026, 10, 29, 23, 59);
    final nextDay = DateTime(2026, 10, 30);
    final data = HydrationSnapshot(
      preferences: const Preferences(goal: 1000),
      intakes: [
        WaterIntake(
          id: 'goal',
          amount: 1000,
          at: today,
          day: dayKey(today),
          onTime: true,
        ),
      ],
      goals: {dayKey(today): 1000},
      plans: {},
    );
    expect(data.totalOn(today) >= data.goalOn(today), isTrue);
    expect(data.totalOn(nextDay) >= data.goalOn(nextDay), isFalse);
  });
  testWidgets(
    'reward restores without replay, appears on completion and is removed on undo or new day',
    (tester) async {
      Widget scene(bool complete, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: IslandScene(
            height: 240,
            pose: 0,
            message: 'Xin chào',
            level: 1,
            complete: complete,
            pet: 'cat',
            onPet: () {},
          ),
        ),
      );
      await tester.pumpWidget(scene(true));
      expect(find.byType(DailyRewardAccessory), findsOneWidget);
      expect(
        find.image(AssetImage(rewardAsset('cat', effect: true))),
        findsNothing,
      );
      await tester.pumpWidget(scene(false));
      expect(find.byType(DailyRewardAccessory), findsNothing);
      await tester.pumpWidget(scene(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.image(AssetImage(rewardAsset('cat', effect: true))),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(
        find.image(AssetImage(rewardAsset('cat', effect: true))),
        findsNothing,
      );
      await tester.pumpWidget(scene(true));
      expect(
        find.image(AssetImage(rewardAsset('cat', effect: true))),
        findsNothing,
      );
      await tester.pumpWidget(scene(false));
      await tester.pumpWidget(scene(true, reduced: true));
      expect(find.byType(DailyRewardAccessory), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('all three completed scenes render with their rewards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'BeVietnamPro'),
        home: Scaffold(body: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RepaintBoundary(
            key: const Key('rewards-gallery'),
            child: Column(
              children: [
                for (final pet in ['fish', 'dog', 'cat'])
                  IslandScene(
                    height: 240,
                    pose: 0,
                    message: 'Đã đạt mục tiêu hôm nay',
                    level: 1,
                    complete: true,
                    pet: pet,
                    onPet: () {},
                  ),
              ],
            ),
          ),
        )),
      ),
    );
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DailyRewardAccessory), findsNWidgets(3));
    if (const bool.fromEnvironment('CAPTURE_REWARDS')) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('rewards-gallery')),
        );
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('../../document/qa/daily-rewards-gallery.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
