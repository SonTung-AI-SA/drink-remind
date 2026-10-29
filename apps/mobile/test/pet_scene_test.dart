import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/features/pets/presentation/island_scene.dart';

void main() {
  testWidgets(
    'switching pet swaps its full environment and removes old island props',
    (tester) async {
      for (final pet in ['cat', 'dog', 'fish']) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: SizedBox(
                width: 390,
                child: IslandScene(
                  height: 220,
                  pose: 0,
                  message: 'Xin chào',
                  level: 1,
                  complete: true,
                  pet: pet,
                  onPet: () {},
                ),
              ),
            ),
          ),
        );
        final assets = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => (image.image as AssetImage).assetName)
            .toList();
        expect(assets, contains(IslandScene.backgroundFor(pet)));
        expect(
          assets.any(
            (asset) =>
                asset.contains('island-base') ||
                asset.contains('island-props') ||
                asset.contains('sky-sea'),
          ),
          isFalse,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
