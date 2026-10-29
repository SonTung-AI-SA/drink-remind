import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:little_island/app/island_app.dart';
import 'package:little_island/app/providers.dart';
import 'package:little_island/core/database/app_database.dart';
import 'package:little_island/features/hydration/data/hydration_repository.dart';
import 'package:little_island/features/hydration/domain/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
    final loader = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
    await loader.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
  });
  testWidgets('record, navigate to history, restart shell and retain data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = HydrationRepository(db);
    await repo.initialize();
    await repo.savePreferences(const Preferences(onboarded: true));
    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const RepaintBoundary(key: Key('capture'), child: IslandApp()),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
    }

    await mount();
    expect(
      find.byKey(const Key('nav-island')),
      findsOneWidget,
      reason: ProviderScope.containerOf(
        tester.element(find.byType(IslandShell)),
      ).read(hydrationProvider).error.toString(),
    );
    expect(find.text('Đảo của tôi'), findsNothing);
    await tester.tap(find.byKey(const Key('record-water')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(
      (await tester.runAsync(repo.snapshot))!.totalOn(DateTime.now()),
      250,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      ScaffoldMessenger.of(tester.element(find.byType(IslandShell)))
          .removeCurrentSnackBar();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final target = File('../../document/qa/island-390x844.png');
        await target.parent.create(recursive: true);
        await target.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.byKey(const Key('nav-journey')));
    await tester.pumpAndSettle();
    expect(find.text('+ 250 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mount();
    expect(
      (await tester.runAsync(repo.snapshot))!.totalOn(DateTime.now()),
      250,
    );
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Chăm mình theo cách riêng.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closing = db.close();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => closing);
  });
}
