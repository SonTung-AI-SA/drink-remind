import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/features/pets/presentation/pet_avatar.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('growth thresholds do not reward extra drinking', () {
    expect([1, 2, 3, 5, 6, 99].map(growthStage), [0, 0, 1, 1, 2, 2]);
  });
  testWidgets('drink finishes before goal and taps do not interrupt it', (
    tester,
  ) async {
    Widget scene(int pose, {bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: SizedBox(
          width: 200,
          height: 200,
          child: PetAvatar(pet: 'cat', pose: pose, level: 1),
        ),
      ),
    );
    String asset() =>
        ((tester.widget<Image>(find.byType(Image))).image as AssetImage)
            .assetName;
    await tester.pumpWidget(scene(0));
    await tester.pumpWidget(scene(8));
    expect(asset(), endsWith('/6.png'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(scene(4));
    expect(asset(), endsWith('/7.png'));
    await tester.pump(const Duration(milliseconds: 2100));
    expect(asset(), endsWith('/9.png'));
    await tester.pump(const Duration(milliseconds: 6100));
    expect(asset(), endsWith('/2.png'));
    await tester.pumpWidget(scene(3, reduced: true));
    await tester.pump(const Duration(seconds: 20));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('companions render all stages and finite feeding reactions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'BeVietnamPro'),
        home: RepaintBoundary(
          key: const Key('gallery'),
          child: Scaffold(
            backgroundColor: const Color(0xFFFAF7EF),
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Little Island · Bạn đồng hành',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                for (final level in [1, 3, 6])
                  Expanded(
                    child: Row(
                      children: [
                        for (final pet in ['cat', 'dog', 'fish'])
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: PetAvatar(
                                        pet: pet,
                                        pose: 0,
                                        level: level,
                                      ),
                                    ),
                                  ),
                                ),
                                Text('${petName(pet)} · ${growthLabel(level)}'),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PetAvatar), findsNWidgets(9));
    if (const bool.fromEnvironment('CAPTURE_PETS')) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('gallery')),
        );
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('../../document/qa/pets-gallery.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    for (final pet in ['cat', 'dog', 'fish']) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: PetAvatar(key: ValueKey(pet), pet: pet, pose: 0, level: 3),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: PetAvatar(key: ValueKey(pet), pet: pet, pose: 3, level: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
