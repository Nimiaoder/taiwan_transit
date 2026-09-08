import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 首頁「運具選擇」宮格的單一項目。
///
/// 之所以獨立成一個 model + widget，是因為未來要新增公車/高鐵/捷運時，
/// 只要在 [HomeScreen] 的清單裡多加一筆 [TransportModeItem]，
/// 不需要動到排版程式碼。
class TransportModeItem {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const TransportModeItem({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.onTap,
  });
}

class TransportModeGridItem extends StatelessWidget {
  final TransportModeItem item;

  const TransportModeGridItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool enabled = item.enabled;
    final Color color = enabled ? item.color : AppColors.textDisabled;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? item.onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 4),
                const Text(
                  '即將推出',
                  style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
