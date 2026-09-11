import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/train/tra_models.dart';

/// 車種勾選清單（預設全勾）。
class TrainTypeSelector extends StatelessWidget {
  final List<TraTrainType> trainTypes;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  const TrainTypeSelector({
    super.key,
    required this.trainTypes,
    required this.selectedIds,
    required this.onChanged,
  });

  bool get _isAllSelected => selectedIds.length == trainTypes.length;

  void _toggleAll() {
    if (_isAllSelected) {
      onChanged({});
    } else {
      onChanged(trainTypes.map((e) => e.trainTypeId).toSet());
    }
  }

  void _toggleOne(String id) {
    final next = Set<String>.from(selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('車種', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: _toggleAll,
              child: Text(_isAllSelected ? '取消全選' : '全選'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: trainTypes.map((type) {
            final selected = selectedIds.contains(type.trainTypeId);
            return FilterChip(
              label: Text(type.name.isEmpty ? type.trainTypeId : type.name),
              selected: selected,
              onSelected: (_) => _toggleOne(type.trainTypeId),
              selectedColor: AppColors.primary.withOpacity(0.25),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }
}
