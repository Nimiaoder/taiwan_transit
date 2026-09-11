import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/train/tra_models.dart';

/// 選擇車站用的 BottomSheet，附搜尋功能。
/// 用於「起站」「迄站」的選擇，兩者共用同一個元件。
Future<TraStation?> showStationPickerSheet({
  required BuildContext context,
  required List<TraStation> stations,
  required String title,
}) {
  return showModalBottomSheet<TraStation>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StationPickerSheet(stations: stations, title: title),
  );
}

class _StationPickerSheet extends StatefulWidget {
  final List<TraStation> stations;
  final String title;

  const _StationPickerSheet({required this.stations, required this.title});

  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  late List<TraStation> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.stations;
  }

  void _onSearchChanged(String keyword) {
    setState(() {
      _filtered = widget.stations
          .where((s) => s.name.contains(keyword) || s.stationId.contains(keyword))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: '搜尋車站名稱',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text('找不到符合的車站', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final station = _filtered[index];
                          return ListTile(
                            title: Text(station.name),
                            subtitle: Text(station.stationId, style: const TextStyle(fontSize: 11)),
                            onTap: () => Navigator.of(context).pop(station),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
