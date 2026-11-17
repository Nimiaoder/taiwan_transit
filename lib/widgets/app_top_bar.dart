import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../screens/settings_screen.dart';

/// =====================================================================
/// 全 App 共用的標題列（Title Bar）
/// =====================================================================
/// 統一所有頁面的標題列樣式與行為，避免每個畫面各自寫一份 AppBar：
/// - 以黑灰漸層（[AppColors.titleBarGradient]）做底，符合現代簡潔風格
/// - 右上角固定提供「設定」按鈕（與首頁一致）
/// - 可透過 [bottom] 掛上 TabBar 等額外元件（例如結果頁的車種頁籤）
///
/// 新增其他運具（公車 / 高鐵 / 捷運）時，畫面只要使用
/// `appBar: const AppTopBar(title: 'xxx')`，即可自動獲得一致的外觀。
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 標題文字
  final String title;

  /// 掛在標題列下方的元件（例如 TabBar），可為 null
  final PreferredSizeWidget? bottom;

  /// 是否顯示右上角「設定」按鈕。
  /// 設定頁本身傳入 false，避免在設定頁再次進入設定頁。
  final bool showSettings;

  /// 設定按鈕左側的額外動作按鈕（依需求擴充）
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.bottom,
    this.showSettings = true,
    this.actions = const [],
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      // 底色交給 flexibleSpace 的漸層繪製，AppBar 本身保持透明
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.titleBarForeground,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const _TitleBarBackground(),
      bottom: bottom,
      actions: [
        ...actions,
        if (showSettings)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// 標題列的黑灰漸層底（含底部細微陰影，讓標題列與內容有層次區隔）
class _TitleBarBackground extends StatelessWidget {
  const _TitleBarBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.titleBarGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
