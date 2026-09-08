/// =====================================================================
/// TDX（運輸資料流通服務平臺）API 設定
/// =====================================================================
/// 使用前請先至 https://tdx.transportdata.tw 註冊會員，
/// 於「會員中心 > 資料服務 > API金鑰」建立一組 Client ID / Client Secret。
///
/// 建議「不要」把金鑰寫死在程式碼中，而是在建置/執行時用 --dart-define 帶入，例如：
///   flutter run \
///     --dart-define=TDX_CLIENT_ID=your_client_id \
///     --dart-define=TDX_CLIENT_SECRET=your_client_secret
///
/// 若未帶入金鑰，App 仍可運作，但會呼叫 TDX 的「免金鑰」模式，
/// 該模式有較嚴格的呼叫頻率限制（每來源 IP 每日約 50 次），僅適合開發測試。
class TdxConfig {
  TdxConfig._();

  /// 由建置參數帶入的 TDX Client ID / Client Secret
  // static const String clientId =
  //     String.fromEnvironment('TDX_CLIENT_ID', defaultValue: '');
  // static const String clientSecret =
  //     String.fromEnvironment('TDX_CLIENT_SECRET', defaultValue: '');
  static const String clientId = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  static const String clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

  /// 是否有設定金鑰（沒有的話會走免金鑰模式）
  static bool get hasCredential => clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// TDX OAuth2 (Client Credentials) 取得 access token 的端點
  static const String authUrl =
      'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token';

  /// TDX 資料 API 的共用 base url（本專案目前只用到台鐵 v3 相關路徑）
  static const String apiBaseUrl = 'https://tdx.transportdata.tw/api/basic';

  /// 每次查詢/清單自動更新即時動態(誤點)的間隔秒數
  static const int liveBoardRefreshSeconds = 60;
}
