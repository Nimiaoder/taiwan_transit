import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// =====================================================================
/// 「出發日期」月曆選擇器（BottomSheet）
/// =====================================================================
/// 取代系統預設的 showDatePicker，改用與 App 深色風格一致的月曆卡片：
/// - 上方可左右切換月份
/// - 快捷鈕：今天 / 明天 / 後天
/// - 只允許選擇今天起 60 天內（TDX 時刻表可查詢範圍）
class DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const DatePickerSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  static const _weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

  late DateTime _selected;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selected = _dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelectable(DateTime d) =>
      !d.isBefore(_dateOnly(widget.firstDate)) &&
      !d.isAfter(_dateOnly(widget.lastDate));

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool get _canGoPrev {
    final prevMonthEnd = DateTime(_visibleMonth.year, _visibleMonth.month, 0);
    return !prevMonthEnd.isBefore(_dateOnly(widget.firstDate));
  }

  bool get _canGoNext {
    final nextMonthStart =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !nextMonthStart.isAfter(_dateOnly(widget.lastDate));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('選擇出發日期',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildQuickChips(),
            const SizedBox(height: 12),
            _buildMonthHeader(),
            const SizedBox(height: 8),
            _buildWeekHeader(),
            const SizedBox(height: 4),
            _buildGrid(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('確定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final today = _dateOnly(DateTime.now());
    final options = <String, DateTime>{
      '今天': today,
      '明天': today.add(const Duration(days: 1)),
      '後天': today.add(const Duration(days: 2)),
    };
    return Wrap(
      spacing: 8,
      children: options.entries.map((e) {
        final active = _isSameDay(_selected, e.value);
        return ChoiceChip(
          label: Text(e.key),
          selected: active,
          showCheckmark: false,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black : AppColors.textSecondary,
          ),
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primary,
          side: BorderSide.none,
          onSelected: (_) {
            if (!_isSelectable(e.value)) return;
            setState(() {
              _selected = e.value;
              _visibleMonth = DateTime(e.value.year, e.value.month);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
          disabledColor: AppColors.textDisabled,
        ),
        Expanded(
          child: Text(
            '${_visibleMonth.year} 年 ${_visibleMonth.month} 月',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: _canGoNext ? () => _shiftMonth(1) : null,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
          disabledColor: AppColors.textDisabled,
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    return Row(
      children: _weekLabels
          .map((w) => Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // DateTime.weekday: 1=一 ... 7=日；月曆以星期日為第一欄
    final leading = firstOfMonth.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      cells.add(_buildDayCell(date));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _buildDayCell(DateTime date) {
    final selectable = _isSelectable(date);
    final selected = _isSameDay(date, _selected);
    final isToday = _isSameDay(date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isToday && !selected
              ? const BorderSide(color: AppColors.primaryDim)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selectable ? () => setState(() => _selected = date) : null,
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: !selectable
                    ? AppColors.textDisabled
                    : selected
                        ? Colors.black
                        : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 彈出「出發日期」月曆選擇的 BottomSheet，回傳選好的日期（取消則回傳 null）。
Future<DateTime?> showDeparturePickerDateSheet({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final today = DateTime.now();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(today.year, today.month, today.day),
      lastDate: lastDate ??
          DateTime(today.year, today.month, today.day)
              .add(const Duration(days: 60)),
    ),
  );
}
