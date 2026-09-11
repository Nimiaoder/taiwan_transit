import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/train/tra_stations.dart';
import '../../models/train/tra_models.dart';

/// =====================================================================
/// 「先選地區、再選車站」的兩欄式選擇畫面
/// =====================================================================
/// 左邊是地區清單（可滾動），右邊是該地區底下的車站清單（可滾動），
/// 選地區時右邊清單會跟著切換，點選車站後關閉並回傳結果。
Future<TraStation?> showRegionStationPickerSheet({
  required BuildContext context,
  required List<TraStation> stations,
  required String title,
}) {
  return showModalBottomSheet<TraStation>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RegionStationPickerSheet(stations: stations, title: title),
  );
}

class _RegionStationPickerSheet extends StatefulWidget {
  final List<TraStation> stations;
  final String title;

  const _RegionStationPickerSheet({required this.stations, required this.title});

  @override
  State<_RegionStationPickerSheet> createState() => _RegionStationPickerSheetState();
}

class _RegionStationPickerSheetState extends State<_RegionStationPickerSheet> {
  late final Map<String, List<TraStation>> _stationsByRegion;
  late final List<String> _availableRegions;
  late String _selectedRegion;

  @override
  void initState() {
    super.initState();

    final grouped = <String, List<TraStation>>{};
    for (final station in widget.stations) {
      final region = TraStations.regionOf(station.name);
      grouped.putIfAbsent(region, () => []).add(station);
    }

    // 只顯示實際有車站的地區，並依照固定順序排列
    _availableRegions = TraStations.orderedRegions.where((r) => grouped.containsKey(r)).toList();
    _stationsByRegion = grouped;
    _selectedRegion = _availableRegions.isNotEmpty ? _availableRegions.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final stationsInRegion = _stationsByRegion[_selectedRegion] ?? const [];

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
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左欄：地區清單（可滾動選擇）
                    SizedBox(
                      width: 110,
                      child: Container(
                        color: AppColors.surfaceVariant,
                        child: ListView.builder(
                          itemCount: _availableRegions.length,
                          itemBuilder: (context, index) {
                            final region = _availableRegions[index];
                            final selected = region == _selectedRegion;
                            return InkWell(
                              onTap: () => setState(() => _selectedRegion = region),
                              child: Container(
                                color: selected ? AppColors.background : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                child: Text(
                                  region,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // 右欄：該地區的車站清單（可滾動選擇）
                    Expanded(
                      child: stationsInRegion.isEmpty
                          ? const Center(
                              child: Text('這個地區暫無車站', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: stationsInRegion.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final station = stationsInRegion[index];
                                return ListTile(
                                  title: Text(station.name),
                                  onTap: () => Navigator.of(context).pop(station),
                                );
                              },
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
