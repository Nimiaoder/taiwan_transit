import '../models/tra_models.dart';

/// =====================================================================
/// 車種預設清單（Fallback）
/// =====================================================================
/// 正常情況下車種清單會即時向 TDX 的
/// `/v3/Rail/TRA/TrainType` 查詢，這裡提供的是「查詢失敗時」
/// （例如尚未設定金鑰、或剛好斷網）可以先讓使用者操作的預設清單，
/// 常見台鐵車種大致分為以下幾類，可依實際 TDX 回傳內容再調整代碼。
class TrainTypeCatalog {
  TrainTypeCatalog._();

  static List<TraTrainType> get defaultTypes => [
        const TraTrainType(
          trainTypeId: '1',
          trainTypeName: BilingualName(zhTw: '普悠瑪/太魯閣', en: 'Puyuma/Taroko'),
        ),
        const TraTrainType(
          trainTypeId: '2',
          trainTypeName: BilingualName(zhTw: '自強號', en: 'Tze-Chiang'),
        ),
        const TraTrainType(
          trainTypeId: '3',
          trainTypeName: BilingualName(zhTw: '莒光號', en: 'Chu-Kuang'),
        ),
        const TraTrainType(
          trainTypeId: '4',
          trainTypeName: BilingualName(zhTw: '復興號/區間快', en: 'Fu-Hsing/Local Express'),
        ),
        const TraTrainType(
          trainTypeId: '5',
          trainTypeName: BilingualName(zhTw: '區間車', en: 'Local'),
        ),
        const TraTrainType(
          trainTypeId: '6',
          trainTypeName: BilingualName(zhTw: '普快車', en: 'Ordinary'),
        ),
      ];
}
