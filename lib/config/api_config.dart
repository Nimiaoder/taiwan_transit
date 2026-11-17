/// =====================================================================
/// 後端 API 設定
/// =====================================================================
/// App 不再直接呼叫 TDX，所有資料都透過自建後端（TdxService）取得，
/// TDX 金鑰只存在後端，前端不需要也不應該持有任何金鑰。
///
/// 後端位址可在建置/執行時用 --dart-define 帶入，例如：
///   flutter run --dart-define=BACKEND_BASE_URL=http://192.168.1.10:8080
///
/// 未帶入時預設為 http://10.0.2.2:8080（Android 模擬器連線到本機的位址）。
class ApiConfig {
  ApiConfig._();

  /// 後端服務根網址（不含結尾斜線）
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// 台鐵 API 路徑前綴
  static const String trainPath = '/api/tdx/train';

  /// 單次請求逾時秒數
  static const int requestTimeoutSeconds = 20;

  /// 查詢結果頁自動更新即時動態（誤點）的間隔秒數
  static const int liveBoardRefreshSeconds = 60;
}
