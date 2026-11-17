import 'package:flutter/material.dart';

/// =====================================================================
/// App 色彩與主題設定（黑灰 / 灰色系 Dark UI）
/// =====================================================================
/// 集中管理顏色，未來要調整整體風格（例如換成淺色主題、或幫其他運具
/// 上不同的主題色）時，只需要改這裡。
class AppColors {
  AppColors._();

  // 背景層級：由深到淺，做出卡片堆疊的層次感
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // 主要品牌色：淺灰
  static const Color primary = Color(0xFFD0D0D0);
  static const Color primaryDim = Color(0xFF8A8A8A);

  // 各運具識別色（在首頁宮格 / 各功能模組中使用）
  static const Color tra = Color(0xFFE0E0E0); // 台鐵：亮灰
  static const Color bus = Color(0xFFBDBDBD); // 公車：淺灰
  static const Color thsr = Color(0xFF9E9E9E); // 高鐵：中灰
  static const Color metro = Color(0xFF7A7A7A); // 捷運：深灰

  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFFA6A6A6);
  static const Color textDisabled = Color(0xFF5E5E5E);

  static const Color divider = Color(0xFF333333);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC15E);

  // ---------------------------------------------------------------
  // 標題列（Title Bar）配色：全 App 共用的黑灰漸層
  // ---------------------------------------------------------------
  /// 標題列漸層起始色（黑灰）
  static const Color titleBarStart = Color(0xFF1A1A1A);

  /// 標題列漸層結束色（灰）
  static const Color titleBarEnd = Color(0xFF4A4A4A);

  /// 標題列上的文字 / 圖示顏色
  static const Color titleBarForeground = Color(0xFFF5F5F5);

  /// 標題列上「未選取」文字（例如 TabBar 未選中的頁籤）
  static const Color titleBarMuted = Color(0xFFB0B0B0);

  /// 標題列漸層（由左上到右下），集中在此方便日後統一調整風格
  static const LinearGradient titleBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [titleBarStart, titleBarEnd],
  );

  // ---------------------------------------------------------------
  // 車種識別色（結果頁 / 詳細頁的車種標籤共用）
  // ---------------------------------------------------------------
  static const Color trainLocal = Color(0xFF8C8C8C); // 區間：中灰
  static const Color trainLocalExpress = Color(0xFFB3B3B3); // 區間快：淺灰
  static const Color trainExpress = Color(0xFFE6E6E6); // 自強 / 普悠瑪 / 太魯閣：亮灰
  static const Color trainChuKuang = Color(0xFFCCCCCC); // 莒光：灰白
  static const Color trainOther = Color(0xFF6E6E6E); // 其他車種：深灰

  // ---------------------------------------------------------------
  // 清單交錯底色：第 1 筆灰色、第 2 筆黑灰色、第 3 筆灰色…依此類推
  // ---------------------------------------------------------------
  static const Color listRowGray = Color(0xFF3A3A3A);
  static const Color listRowDark = Color(0xFF1F1F1F);

  /// 依清單索引（從 0 開始）取得交錯底色
  static Color listRow(int index) => index.isEven ? listRowGray : listRowDark;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      // 標題列預設樣式：底色由 AppTopBar 的漸層負責，這裡統一文字與圖示樣式
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.titleBarStart,
        foregroundColor: AppColors.titleBarForeground,
        iconTheme: IconThemeData(color: AppColors.titleBarForeground),
        actionsIconTheme: IconThemeData(color: AppColors.titleBarForeground),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.titleBarForeground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      // 標題列下方的頁籤（結果頁車種切換）也套用標題列配色
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.titleBarForeground,
        unselectedLabelColor: AppColors.titleBarMuted,
        indicatorColor: AppColors.titleBarForeground,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceVariant;
        }),
        overlayColor: WidgetStatePropertyAll<Color?>(Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
