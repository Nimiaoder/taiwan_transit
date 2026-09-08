import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';

/// 車次詳細頁中，單一車站的停靠列（含上下連接線）。
///
/// 依照需求，用不同的「站名樣式」區分：
/// - [isOrigin]：使用者選擇的起站 -> 綠色 + 圓形實心點
/// - [isDestination]：使用者選擇的迄站 -> 紅色/橘色 + 圓形實心點
/// - [isCurrent]：列車目前所在/即將抵達站 -> 藍色 + 有動畫感的外框圓點
class StopTimeTile extends StatelessWidget {
  final TraTrainStopDetail stop;
  final bool isFirst;
  final bool isLast;
  final bool isOrigin;
  final bool isDestination;
  final bool isCurrent;
  final bool isPast;

  const StopTimeTile({
    super.key,
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.isOrigin,
    required this.isDestination,
    required this.isCurrent,
    required this.isPast,
  });

  Color get _dotColor {
    if (isCurrent) return AppColors.thsr; // 藍色：目前位置
    if (isOrigin) return AppColors.primary; // 綠色：起站
    if (isDestination) return AppColors.warning; // 橘色：迄站
    return AppColors.textSecondary;
  }

  TextStyle get _nameStyle {
    final base = const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    if (isCurrent) {
      return base.copyWith(color: AppColors.thsr, fontWeight: FontWeight.w800);
    }
    if (isOrigin) {
      return base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800);
    }
    if (isDestination) {
      return base.copyWith(color: AppColors.warning, fontWeight: FontWeight.w800);
    }
    return base.copyWith(color: isPast ? AppColors.textDisabled : AppColors.textPrimary);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側：時刻表時間
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(stop.arrivalTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast ? AppColors.textDisabled : AppColors.textSecondary,
                    ),
                  ),
                  if (stop.departureTime.isNotEmpty && stop.departureTime != stop.arrivalTime)
                    Text(
                      _fmt(stop.departureTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: isPast ? AppColors.textDisabled : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 中間：連接線 + 圓點
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child: isFirst
                      ? const SizedBox.shrink()
                      : Container(width: 2, color: AppColors.divider),
                ),
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    color: (isOrigin || isDestination || isCurrent) ? _dotColor : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: _dotColor, width: 2),
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(width: 2, color: AppColors.divider),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 右側：站名 + 標籤
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(stop.stationName, style: _nameStyle),
                  const SizedBox(width: 6),
                  if (isCurrent) _buildTag('列車位置', AppColors.thsr),
                  if (isOrigin) _buildTag('起站', AppColors.primary),
                  if (isDestination) _buildTag('迄站', AppColors.warning),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  static String _fmt(String raw) => raw.length >= 5 ? raw.substring(0, 5) : raw;
}
