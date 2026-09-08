import 'package:flutter/material.dart';

/// =====================================================================
/// App 色彩與主題設定（現代簡潔風 Dark UI）
/// =====================================================================
/// 集中管理顏色，未來要調整整體風格（例如換成淺色主題、或幫其他運具
/// 上不同的主題色）時，只需要改這裡。
class AppColors {
  AppColors._();

  // 背景層級：由深到淺，做出卡片堆疊的層次感
  static const Color background = Color(0xFF0E1013);
  static const Color surface = Color(0xFF171A1F);
  static const Color surfaceVariant = Color(0xFF20242B);

  // 主要品牌色：台鐵用藍綠色系，未來公車/高鐵/捷運可各自定義主題色
  static const Color primary = Color(0xFF3DDC97);
  static const Color primaryDim = Color(0xFF1F8F63);

  // 各運具識別色（在首頁宮格 / 各功能模組中使用）
  static const Color tra = Color(0xFF3DDC97); // 台鐵：綠
  static const Color bus = Color(0xFFFFB454); // 公車：橘黃
  static const Color thsr = Color(0xFF5AA9FF); // 高鐵：藍
  static const Color metro = Color(0xFFEF6DA8); // 捷運：粉

  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF9AA3AF);
  static const Color textDisabled = Color(0xFF565D68);

  static const Color divider = Color(0xFF2A2F37);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC15E);
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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
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
