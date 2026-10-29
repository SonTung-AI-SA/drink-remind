import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/pet.dart';
import 'daily_reward.dart';
export '../domain/pet.dart';

/// Approved storyboard key poses, with finite motion between each acting beat.
class PetAvatar extends StatefulWidget {
  const PetAvatar({
    super.key,
    required this.pet,
    required this.pose,
    required this.level,
    this.rewarded = false,
  });
  final String pet;
  final int pose, level;
  final bool rewarded;
  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this)
    ..addStatusListener(_finished);
  Timer? idleTimer;
  int row = 0;
  bool resting = true, pendingGoal = false;
  String get species => switch (widget.pet) {
    'fish' => 'nemo',
    'dog' => 'corgi',
    _ => 'meo-cam',
  };
  bool get reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduced) {
      idleTimer?.cancel();
      controller.stop();
      resting = true;
      pendingGoal = false;
    } else if (!controller.isAnimating) {
      _scheduleIdle();
    }
  }

  void _scheduleIdle() {
    idleTimer?.cancel();
    if (reduced) return;
    idleTimer = Timer(const Duration(seconds: 16), () {
      if (mounted && !reduced) _play(0);
    });
  }

  void _play(int next, {bool goalAfter = false}) {
    idleTimer?.cancel();
    pendingGoal = goalAfter;
    row = next;
    resting = false;
    if (reduced) {
      resting = true;
      pendingGoal = false;
      controller.stop();
    } else {
      controller.duration = Duration(seconds: [5, 2, 3, 6][row]);
      controller.forward(from: 0);
    }
    setState(() {});
  }

  void _finished(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (pendingGoal) {
      _play(3);
    } else {
      setState(() {
        resting = true;
        row = 0;
      });
      _scheduleIdle();
    }
  }

  @override
  void didUpdateWidget(covariant PetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet != widget.pet) {
      controller.stop();
      pendingGoal = false;
      row = 0;
      resting = true;
      _scheduleIdle();
    } else if (oldWidget.pose != widget.pose && widget.pose != 0) {
      final drink = [3, 6, 8].contains(widget.pose);
      // Repeated taps do not interrupt a feeding/goal sequence or queue actions.
      if (!drink && controller.isAnimating && row != 0) return;
      _play(drink ? 2 : 1, goalAfter: widget.pose == 8);
    }
  }

  @override
  void dispose() {
    idleTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: petName(widget.pet),
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final beat = resting
            ? 2
            : (t < .20
                  ? 0
                  : t < .72
                  ? 1
                  : 2);
        final phase = resting || reduced ? 0.0 : math.sin(t * math.pi);
        final run = row == 1 || row == 3;
        final fish = widget.pet == 'fish';
        final offset = Offset(
          (run ? math.sin(t * math.pi * 2) * (row == 3 ? 19 : 10) : 0) * phase,
          -phase *
              (fish
                  ? 12
                  : run
                  ? 9
                  : 2),
        );
        final art = Image.asset(
          'assets/pets/storyboard-v1/$species/${row * 3 + beat}.png',
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: reduced || resting
                ? 0
                : math.sin(t * math.pi * 2) * phase * (fish ? .10 : .025),
            child: Transform.scale(
              scale: [.86, .94, 1.0][growthStage(widget.level)],
              alignment: Alignment.bottomCenter,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      art,
                      if (widget.rewarded)
                        IgnorePointer(
                          child: DailyRewardAccessory(
                            pet: widget.pet,
                            frame: row * 3 + beat,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
