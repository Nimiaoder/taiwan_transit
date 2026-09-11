/// =====================================================================
/// 車種分類（簡化版）
/// =====================================================================
/// 使用者不需要看到 TDX 原始資料裡過於細碎的車種名稱
/// （例如「自強(推拉式自強號且無自行車車廂)」），
/// 這裡把所有車種收斂成 6 種常見分類，並再往上分成兩大群組
/// （區間類 / 對號座類），對應結果頁的分頁頁籤。
///
/// 分類邏輯用「車種名稱關鍵字比對」而非 TrainTypeID/TrainTypeCode，
/// 因為 TDX 的名稱字串比較穩定好懂，也不用擔心猜錯代碼。
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TrainCategory {
  interval, // 區間
  intervalFast, // 區間快
  tzeChiang, // 自強（含推拉式等各種自強號子類型）
  puyuma, // 普悠瑪
  taroko, // 太魯閣
  chuKuang, // 莒光
  other, // 其他（復興、普快等少數車種）
}

class TrainCategoryUtil {
  TrainCategoryUtil._();

  /// 三個頁籤的名稱（「全部」在最前面）
  static const String groupAll = '全部';
  static const String groupLocal = '區間'; // 區間 + 區間快
  static const String groupExpress = '對號座'; // 普悠瑪 + 太魯閣 + 自強 + 莒光 + 其他

  static TrainCategory categorize(String trainTypeName) {
    if (trainTypeName.contains('太魯閣')) return TrainCategory.taroko;
    if (trainTypeName.contains('普悠瑪')) return TrainCategory.puyuma;
    if (trainTypeName.contains('區間快')) return TrainCategory.intervalFast;
    if (trainTypeName.contains('區間')) return TrainCategory.interval;
    if (trainTypeName.contains('莒光')) return TrainCategory.chuKuang;
    if (trainTypeName.contains('自強')) return TrainCategory.tzeChiang;
    return TrainCategory.other;
  }

  static String label(TrainCategory category) {
    switch (category) {
      case TrainCategory.interval:
        return '區間';
      case TrainCategory.intervalFast:
        return '區間快';
      case TrainCategory.tzeChiang:
        return '自強';
      case TrainCategory.puyuma:
        return '普悠瑪';
      case TrainCategory.taroko:
        return '太魯閣';
      case TrainCategory.chuKuang:
        return '莒光';
      case TrainCategory.other:
        return '其他';
    }
  }

  /// 車種對應的識別色（結果頁 / 詳細頁的車種標籤共用）。
  /// 之後要調整配色只需改 [AppColors] 裡的車種色票，不必動到畫面程式。
  static Color color(TrainCategory category) {
    switch (category) {
      case TrainCategory.interval:
        return AppColors.trainLocal; // 區間：藍
      case TrainCategory.intervalFast:
        return AppColors.trainLocalExpress; // 區間快：淺藍
      case TrainCategory.tzeChiang:
      case TrainCategory.puyuma:
      case TrainCategory.taroko:
        return AppColors.trainExpress; // 自強 / 普悠瑪 / 太魯閣：橘
      case TrainCategory.chuKuang:
        return AppColors.trainChuKuang; // 莒光：橘（偏黃）
      case TrainCategory.other:
        return AppColors.trainOther; // 其他：灰
    }
  }

  /// 直接用 TDX 原始車種名稱取得顏色（畫面最常用的入口）
  static Color colorOfName(String trainTypeName) =>
      color(categorize(trainTypeName));

  /// 直接用 TDX 原始車種名稱取得簡化後的顯示名稱
  static String labelOfName(String trainTypeName) =>
      label(categorize(trainTypeName));

  /// 是否屬於「區間」大群組（頁籤用）
  static bool isLocalGroup(TrainCategory category) =>
      category == TrainCategory.interval || category == TrainCategory.intervalFast;

  /// 該群組底下實際會出現的子分類，僅用於文件/測試參考
  static const List<TrainCategory> localGroupTypes = [
    TrainCategory.interval,
    TrainCategory.intervalFast,
  ];

  static const List<TrainCategory> expressGroupTypes = [
    TrainCategory.tzeChiang,
    TrainCategory.puyuma,
    TrainCategory.taroko,
    TrainCategory.chuKuang,
    TrainCategory.other,
  ];
}
