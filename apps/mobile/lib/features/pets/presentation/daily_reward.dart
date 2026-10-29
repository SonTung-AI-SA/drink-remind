import 'dart:math' as math;

import 'package:flutter/material.dart';

String rewardAsset(String pet, {bool effect = false}) =>
    'assets/rewards/daily-v1/${switch (pet) {
      'fish' => effect ? 'nemo-bubbles-fx' : 'nemo-crown',
      'dog' => effect ? 'corgi-confetti-fx' : 'corgi-scarf',
      _ => effect ? 'meo-cam-stars-fx' : 'meo-cam-badge',
    }}.png';

class DailyRewardAccessory extends StatelessWidget {
  const DailyRewardAccessory({
    super.key,
    required this.pet,
    required this.frame,
  });
  final String pet;
  final int frame;
  @override
  Widget build(BuildContext context) {
    // The last dog row already contains the teal scarf in the approved artwork.
    if (pet == 'dog' && frame >= 9) return const SizedBox.shrink();
    final index = frame.clamp(0, 11);
    final Offset anchor;
    final double width, height;
    if (pet == 'fish') {
      anchor = const [
        Offset(.47, .29),
        Offset(.48, .13),
        Offset(.48, .29),
        Offset(.43, .30),
        Offset(.45, .20),
        Offset(.47, .29),
        Offset(.43, .35),
        Offset(.39, .29),
        Offset(.46, .31),
        Offset(.46, .32),
        Offset(.42, .36),
        Offset(.43, .30),
      ][index];
      width = .34;
      height = .22;
    } else if (pet == 'dog') {
      anchor = const [
        Offset(.56, .73),
        Offset(.59, .65),
        Offset(.35, .54),
        Offset(.43, .52),
        Offset(.55, .58),
        Offset(.48, .52),
        Offset(.35, .52),
        Offset(.50, .68),
        Offset(.35, .55),
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ][index];
      width = .36;
      height = .24;
    } else {
      anchor = const [
        Offset(.59, .78),
        Offset(.61, .69),
        Offset(.62, .65),
        Offset(.59, .76),
        Offset(.57, .56),
        Offset(.62, .65),
        Offset(.58, .72),
        Offset(.58, .73),
        Offset(.62, .65),
        Offset(.57, .70),
        Offset(.61, .52),
        Offset(.61, .47),
      ][index];
      width = .13;
      height = .13;
    }
    return LayoutBuilder(
      builder: (context, size) => Stack(
        children: [
          Positioned(
            left: anchor.dx * size.maxWidth,
            top: anchor.dy * size.maxHeight,
            width: width * size.maxWidth,
            height: height * size.maxHeight,
            child: Image.asset(
              rewardAsset(pet),
              fit: BoxFit.contain,
              key: ValueKey('daily-reward-$pet'),
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays only on a transition to complete, never on app/page restoration.
class DailyRewardEffect extends StatefulWidget {
  const DailyRewardEffect({
    super.key,
    required this.pet,
    required this.complete,
  });
  final String pet;
  final bool complete;
  @override
  State<DailyRewardEffect> createState() => _DailyRewardEffectState();
}

class _DailyRewardEffectState extends State<DailyRewardEffect>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
    value: 1,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant DailyRewardEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.complete || oldWidget.pet != widget.pet) {
      controller.value = 1;
    } else if (!oldWidget.complete &&
        widget.complete &&
        !MediaQuery.disableAnimationsOf(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!widget.complete || controller.value == 1) {
          return const SizedBox.shrink();
        }
        final t = controller.value;
        return Opacity(
          opacity: math.sin(t * math.pi).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -24 * t),
            child: Transform.scale(
              scale: .85 + .25 * t,
              child: Image.asset(
                rewardAsset(widget.pet, effect: true),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        );
      },
    ),
  );
}
