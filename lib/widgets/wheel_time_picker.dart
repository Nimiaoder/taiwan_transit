import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// =====================================================================
/// 24 小時制「滾輪」時間選擇器
/// =====================================================================
/// 使用者要求不要用時鐘介面，改用滾動式 UI（類似公車 App 常見的
/// 時間滾輪），這裡用兩組 [ListWheelScrollView] 分別滾「時」「分」。
class WheelTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  const WheelTimePicker({
    super.key,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<WheelTimePicker> {
  static const double _itemExtent = 44;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelected,
    required String suffix,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          onSelected(index);
          _emit();
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final isSelected = (suffix == '時' ? _hour : _minute) == index;
            return Center(
              child: Text(
                index.toString().padLeft(2, '0') + suffix,
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中間高亮的選取列（讓使用者清楚知道現在對到哪一格）
          Container(
            height: _itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Row(
            children: [
              _buildWheel(
                controller: _hourController,
                itemCount: 24,
                onSelected: (v) => setState(() => _hour = v),
                suffix: '時',
              ),
              _buildWheel(
                controller: _minuteController,
                itemCount: 60,
                onSelected: (v) => setState(() => _minute = v),
                suffix: '分',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 彈出「出發時間」滾輪選擇的 BottomSheet，回傳選好的 TimeOfDay。
Future<void> showDepartureTimePickerSheet({
  required BuildContext context,
  required TimeOfDay initialTime,
  required void Function(TimeOfDay time) onConfirm,
}) {
  TimeOfDay time = initialTime;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '選擇出發時間',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  WheelTimePicker(
                    initialTime: time,
                    onChanged: (t) => time = t,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirm(time);
                        Navigator.of(context).pop();
                      },
                      child: const Text('確定'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
