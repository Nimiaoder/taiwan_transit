import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';

/// 時刻表清單中的單一列（重新設計版）。
///
/// 版面由上到下：
/// 1. 出發時間 --------> 抵達時間　　狀態徽章（準點/誤點/已過站/尚未發車）
/// 2. 車種＋車次號、開往XX
/// 3. 經過幾站・行駛時間（小字）
///
/// [isPast] 為 true 時（已過站/已發車）會整列反灰處理。
class TimetableListTile extends StatelessWidget {
  final TraTimetableEntry entry;
  final TraLiveBoard? liveBoard;
  final bool isPast;
  final VoidCallback onTap;

  const TimetableListTile({
    super.key,
    required this.entry,
    required this.liveBoard,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = entry.trainInfo;
    final origin = entry.originStopTime;
    final dest = entry.destinationStopTime;

    return Opacity(
      opacity: isPast ? 0.4 : 1.0,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：出發時間 -> 抵達時間 + 狀態徽章
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(origin.departureTime),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            Expanded(child: Divider(color: AppColors.divider, thickness: 1.4)),
                            Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
                            Expanded(child: Divider(color: AppColors.divider, thickness: 1.4)),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(dest.arrivalTime),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                // 第二行：車種、車次號、開往XX
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${info.trainTypeName.isEmpty ? '' : info.trainTypeName} ${info.trainNo}　開往 ${info.endingStationName}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 2),
                // 第三行：經過幾站・行駛時間
                Text(
                  '經過 ${entry.stopsBetween} 站・${_formatDuration(entry.durationMinutes)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (isPast) {
      return _badge('已過站', AppColors.textDisabled);
    }
    if (liveBoard != null) {
      if (liveBoard!.isDelayed) {
        return _badge('誤點${liveBoard!.delayTime}分', AppColors.warning);
      }
      return _badge('準點', AppColors.primary);
    }
    // 還沒有即時動態資料（通常代表車次尚未發車、或還不在即時看板範圍內）
    return _badge('尚未發車', AppColors.textSecondary);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  /// TDX 回傳的時間有時候是 "HH:mm"，有時候是 "HH:mm:ss"，統一裁成 "HH:mm"
  static String _formatTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  static String _formatDuration(int minutes) {
    if (minutes <= 0) return '未知時間';
    if (minutes < 60) return '$minutes 分鐘';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h 小時' : '$h 小時 $m 分';
  }
}
