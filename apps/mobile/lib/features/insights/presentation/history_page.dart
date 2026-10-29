import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../hydration/domain/models.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.data,
    required this.now,
    required this.onDelete,
    required this.onEdit,
  });
  final HydrationSnapshot data;
  final DateTime now;
  final ValueChanged<String> onDelete;
  final ValueChanged<WaterIntake> onEdit;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? selected;
  @override
  Widget build(BuildContext context) {
    final data = widget.data, now = widget.now, date = selected ?? widget.now;
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final maxValue = days.fold<double>(
      1,
      (value, d) =>
          math.max(value, math.max(data.totalOn(d), data.goalOn(d)).toDouble()),
    );
    final fmt = NumberFormat.decimalPattern('vi');
    final logs = data.onDay(date);
    return ListView(
      key: const PageStorageKey('history-scroll'),
      padding: const EdgeInsets.all(22),
      children: [
        const Text('Hành trình của bạn', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        Text(
          'Đảo lớn lên từng chút.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Mỗi ngày chăm mình đều có ý nghĩa.'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: IslandColors.soft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, dd/MM', 'vi').format(date)),
              const SizedBox(height: 6),
              Text(
                '${fmt.format(data.totalOn(date))} ml',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: IslandColors.blue,
                ),
              ),
              Text(
                'Mục tiêu ${fmt.format(data.goalOn(date))} ml · ${logs.length} lần ghi nhận',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '7 ngày vừa qua',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 175,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final total = data.totalOn(d), active = dayKey(d) == dayKey(date);
              return Expanded(
                child: Semantics(
                  label: '${DateFormat('dd/MM').format(d)}: $total ml',
                  selected: active,
                  child: InkWell(
                    onTap: () => setState(() => selected = d),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(total / 1000).toStringAsFixed(1)}L',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 25,
                            height: math.max(4, total / maxValue * 100),
                            decoration: BoxDecoration(
                              color: active
                                  ? IslandColors.blue
                                  : IslandColors.soft,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: active ? IslandColors.soft : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Những ngụm nhỏ · ${DateFormat('dd/MM').format(date)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Chưa có lần uống nào trong ngày này.'),
          ),
        for (final entry in logs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: IslandColors.soft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: IslandColors.blue,
              ),
            ),
            title: Text('+ ${fmt.format(entry.amount)} ml'),
            subtitle: Text(
              '${DateFormat('HH:mm').format(entry.at)}${entry.onTime ? ' · Đúng nhịp' : ''}',
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Sửa hoặc xóa lần uống',
              onSelected: (value) => value == 'edit'
                  ? widget.onEdit(entry)
                  : widget.onDelete(entry.id),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa dung tích')),
                PopupMenuItem(value: 'delete', child: Text('Xóa lần ghi nhận')),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IslandColors.sand,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'Bạn nhỏ đã có ${data.meals} bữa ăn · Lv. ${data.meals ~/ 5 + 1}\n'
            'Uống đều đặn giúp bạn nhỏ lớn lên. Bữa ăn tăng cấp cách nhau ít nhất 30 phút, tối đa 8 bữa/ngày.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
