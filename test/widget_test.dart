// 基本的 Widget smoke test：確認 App 能正常啟動並顯示主畫面標題。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taiwan_transit/main.dart';

void main() {
  testWidgets('主畫面顯示四大運具入口', (WidgetTester tester) async {
    await tester.pumpWidget(const TaiwanTransitApp());

    expect(find.text('台鐵'), findsOneWidget);
    expect(find.text('公車'), findsOneWidget);
    expect(find.text('高鐵'), findsOneWidget);
    expect(find.text('捷運'), findsOneWidget);
  });
}
