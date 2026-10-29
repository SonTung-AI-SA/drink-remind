import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../domain/models.dart';
import '../../pets/presentation/island_scene.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.data,
    required this.now,
    required this.amount,
    required this.busy,
    required this.pose,
    required this.message,
    required this.onAmount,
    required this.onDrink,
    required this.onCustom,
    required this.onPet,
    required this.onSchedule,
  });
  final HydrationSnapshot data;
  final DateTime now;
  final int amount, pose;
  final bool busy;
  final String message;
  final ValueChanged<int> onAmount;
  final VoidCallback onDrink, onCustom, onPet, onSchedule;
  @override
  Widget build(BuildContext context) {
    final total = data.totalOn(now),
        goal = data.goalOn(now),
        remaining = math.max(0, goal - total);
    final progress = (total / goal).clamp(0.0, 1.0);
    final future = (data.plans[dayKey(now)] ?? [])
        .where((s) => s.at.isAfter(now))
        .toList();
    final next = future.isNotEmpty
        ? DateFormat('HH:mm').format(future.first.at)
        : null;
    final fmt = NumberFormat.decimalPattern('vi');
    return LayoutBuilder(
      builder: (context, c) {
        final sceneHeight = (c.maxHeight - 500).clamp(145.0, 260.0);
        return SingleChildScrollView(
          key: const PageStorageKey('today-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đảo nhỏ của bạn',
                      style: TextStyle(fontSize: 14, color: IslandColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Một ngày thật trong lành.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              IslandScene(
                pet: data.preferences.pet,
                height: sceneHeight,
                pose: pose,
                message: message,
                level: data.meals ~/ 5 + 1,
                complete: remaining == 0,
                onPet: onPet,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: IslandColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: IslandColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.water_drop_outlined,
                                color: IslandColors.blue,
                                size: 19,
                              ),
                              const SizedBox(width: 7),
                              const Expanded(
                                child: Text(
                                  'Nước cho hôm nay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: IslandColors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: fmt.format(total),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: IslandColors.ink,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${fmt.format(goal)} ml',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: IslandColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 9,
                              color: IslandColors.blue,
                              backgroundColor: IslandColors.soft,
                              semanticsLabel: 'Tiến độ uống nước',
                              semanticsValue: '${(progress * 100).round()}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 5,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                remaining == 0
                                    ? 'Đã đạt mục tiêu'
                                    : 'Còn ${fmt.format(remaining)} ml',
                                style: const TextStyle(fontSize: 14),
                              ),
                              TextButton(
                                onPressed: onSchedule,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                ),
                                child: Text(
                                  next != null
                                      ? '◷ $next · Xem lịch'
                                      : 'Xem lịch',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              for (final value in [150, 250, 350])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: value == 350 ? 0 : 8,
                                    ),
                                    child: OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => onAmount(value),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(44, 46),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        backgroundColor: amount == value
                                            ? IslandColors.soft
                                            : null,
                                        side: BorderSide(
                                          color: amount == value
                                              ? IslandColors.blue
                                              : IslandColors.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '$value ml',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            key: const Key('record-water'),
                            onPressed: busy ? null : onDrink,
                            icon: const Icon(Icons.add, size: 21),
                            label: Text('Tôi vừa uống $amount ml'),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: busy ? null : onCustom,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(100, 38),
                              ),
                              child: const Text(
                                'Dung tích khác',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
