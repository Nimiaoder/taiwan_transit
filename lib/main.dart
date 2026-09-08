import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

/// App 進入點。
/// 主題、路由等全域設定都集中在這裡，畫面邏輯則分散到 screens/ 底下，
/// 方便未來擴充公車、高鐵、捷運等其他運具模組。
void main() {
  runApp(const TaiwanTransitApp());
}

class TaiwanTransitApp extends StatelessWidget {
  const TaiwanTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台灣大眾運輸',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
