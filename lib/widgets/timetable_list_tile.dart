import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';

/// 時刻表清單中的單一列。
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

    final double opacity = isPast ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左側：發車 -> 到達 時間
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(origin.departureTime),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(dest.arrivalTime),
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // 中間：車次號 / 車種
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${info.trainTypeName.isEmpty ? '' : info.trainTypeName} ${info.trainNo}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '開往 ${info.endingStationName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 右側：誤點狀況 / 已過站標記
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isPast)
                      const Text('已過站', style: TextStyle(fontSize: 12, color: AppColors.textDisabled))
                    else if (liveBoard != null && liveBoard!.isDelayed)
                      Text(
                        '誤點 ${liveBoard!.delayTime} 分',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700),
                      )
                    else if (liveBoard != null)
                      const Text('準點', style: TextStyle(fontSize: 12, color: AppColors.primary))
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TDX 回傳的時間有時候是 "HH:mm"，有時候是 "HH:mm:ss"，統一裁成 "HH:mm"
  static String _formatTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }
}
