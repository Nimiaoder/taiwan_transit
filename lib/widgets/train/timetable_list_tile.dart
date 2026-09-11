import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/train/train_category.dart';
import '../../models/train/tra_models.dart';

/// =====================================================================
/// 時刻表清單中的單一列（欄位對齊版）
/// =====================================================================
/// 版面由左到右分成 5 個「欄位」，每一列的欄位寬度固定，
/// 因此整份清單上下看起來會完全對齊：
///
///   [ 區間        ] [ 出發時間 ] [    ---->     ] [ 到站時間 ] [ 準點  ]
///   [ 1234(車號)  ]              [ 經過 8 站 32 分鐘 ]
///                                [ 開往 潮州     ]
///
/// 車種標籤採用與 [TraTrainDetailScreen] 相同的「圓角色塊」風格，
/// 並依車種給不同顏色（區間藍 / 區間快淺藍 / 自強、普悠瑪、太魯閣橘 /
/// 莒光橘偏黃），顏色定義集中在 [TrainCategoryUtil.colorOfName]。
///
/// [isPast] 為 true 時（已過站/已發車）會整列反灰處理。
class TimetableListTile extends StatelessWidget {
  /// 各欄位寬度（Expanded 的中間欄除外），統一管理方便日後微調
  static const double _typeColumnWidth = 62;
  static const double _timeColumnWidth = 54;
  static const double _statusColumnWidth = 62;
  static const double _columnGap = 6;

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              // 每個欄位都置中對齊，確保上下列的視覺基準一致
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 欄位 1：車種色塊 + 車次號
                SizedBox(
                  width: _typeColumnWidth,
                  child: _buildTrainTypeColumn(info),
                ),
                const SizedBox(width: _columnGap),
                // 欄位 2：出發時間
                SizedBox(
                  width: _timeColumnWidth,
                  child: _buildTimeText(origin.departureTime),
                ),
                const SizedBox(width: _columnGap),
                // 欄位 3：箭頭 + 經過站數/行駛時間 + 開往
                Expanded(child: _buildMiddleColumn(info)),
                const SizedBox(width: _columnGap),
                // 欄位 4：到站時間
                SizedBox(
                  width: _timeColumnWidth,
                  child: _buildTimeText(dest.arrivalTime),
                ),
                const SizedBox(width: _columnGap),
                // 欄位 5：狀態（尚未發車 / 準點 / 誤點 / 已過站）
                SizedBox(
                  width: _statusColumnWidth,
                  child: _buildStatusBadge(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 欄位 1：車種色塊（依車種著色）與車次號
  Widget _buildTrainTypeColumn(TraTrainInfo info) {
    final label = TrainCategoryUtil.labelOfName(info.trainTypeName);
    final color = TrainCategoryUtil.colorOfName(info.trainTypeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            border: Border.all(color: color.withOpacity(0.55)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          info.trainNo,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 欄位 2 / 4：時間文字（出發、到站共用同一種樣式，確保左右對齊）
  Widget _buildTimeText(String rawTime) {
    return Text(
      _formatTime(rawTime),
      textAlign: TextAlign.center,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// 欄位 3：中間的行程資訊（箭頭 / 經過站數與時間 / 開往終點站）
  Widget _buildMiddleColumn(TraTrainInfo info) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 用一條帶箭頭的線表示「起站 → 迄站」
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Icon(Icons.arrow_right_alt,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '經過 ${entry.stopsBetween} 站・${_formatDuration(entry.durationMinutes)}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '開往 ${info.endingStationName}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
        ),
      ],
    );
  }

  /// 欄位 5：即時動態狀態徽章
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w800, height: 1.2),
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
