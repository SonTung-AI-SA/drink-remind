import 'package:flutter/material.dart';

import 'pet_avatar.dart';
import 'daily_reward.dart';

/// Each companion uses the environment from its approved storyboard.
class IslandScene extends StatelessWidget {
  const IslandScene({
    super.key,
    required this.height,
    required this.pose,
    required this.message,
    required this.level,
    required this.complete,
    required this.onPet,
    this.pet = 'cat',
  });
  final double height;
  final int pose, level;
  final String message, pet;
  final bool complete;
  final VoidCallback onPet;

  static String backgroundFor(String pet) => switch (pet) {
    'fish' => 'assets/backgrounds/nemo-scene-v1.png',
    'dog' => 'assets/backgrounds/corgi-scene-v1.png',
    _ => 'assets/backgrounds/meo-cam-scene-v1.png',
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                backgroundFor(pet),
                key: ValueKey(backgroundFor(pet)),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: width * .27,
              bottom: height * .10,
              width: width * .46,
              height: height * .76,
              child: Semantics(
                button: true,
                label: 'Chạm để chào ${petName(pet)}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPet,
                  child: PetAvatar(
                    pet: pet,
                    pose: pose,
                    level: level,
                    rewarded: complete,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DailyRewardEffect(pet: pet, complete: complete),
            ),
            Positioned(
              top: 7,
              left: 18,
              right: 18,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFFEFA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF294958),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _badge(petName(pet), bold: true)),
                  const SizedBox(width: 12),
                  Flexible(child: _badge('${growthLabel(level)} · Lv. $level')),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _badge(String text, {bool bold = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFEFA),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: bold ? 16 : 14,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: const Color(0xFF294958),
      ),
    ),
  );
}
