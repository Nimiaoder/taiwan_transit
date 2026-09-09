import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../widgets/transport_mode_grid_item.dart';
import 'settings_screen.dart';
import 'tra_search_screen.dart';

/// =====================================================================
/// 主畫面：運具選擇
/// =====================================================================
/// 目前只有「台鐵」實作完成，公車 / 高鐵 / 捷運先放上入口（禁用狀態），
/// 之後要擴充時，只需要：
///   1. 實作對應的 Service（參考 TraService）
///   2. 實作對應的查詢 / 清單 / 詳細頁（參考 tra_search / tra_results / tra_train_detail）
///   3. 把下面清單中對應項目的 enabled 改成 true、onTap 接上新畫面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      TransportModeItem(
        label: '台鐵',
        icon: Icons.train,
        color: AppColors.tra,
        enabled: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TraSearchScreen()),
          );
        },
      ),
      TransportModeItem(
        label: '公車',
        icon: Icons.directions_bus,
        color: AppColors.bus,
        enabled: false,
      ),
      TransportModeItem(
        label: '高鐵',
        icon: Icons.tram,
        color: AppColors.thsr,
        enabled: false,
      ),
      TransportModeItem(
        label: '捷運',
        icon: Icons.subway,
        color: AppColors.metro,
        enabled: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣大眾運輸'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '選擇運具查詢時刻表',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) =>
                    TransportModeGridItem(item: items[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
