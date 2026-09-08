import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/tdx_config.dart';

/// =====================================================================
/// TDX 身分驗證服務
/// =====================================================================
/// 負責向 TDX 的 OAuth2 (Client Credentials) 端點換取 access token，
/// 並在 token 過期前快取起來，避免每一次 API 呼叫都重新登入。
///
/// 這個 class 刻意獨立出來（不跟業務邏輯混在一起），
/// 未來如果公車/高鐵/捷運模組也要打 TDX API，都可以直接共用它。
class TdxAuthService {
  TdxAuthService._internal();
  static final TdxAuthService instance = TdxAuthService._internal();

  String? _accessToken;
  DateTime? _expiresAt;

  /// 取得可用的 access token；若快取的 token 還沒過期就直接回傳快取值。
  /// 若未設定 TDX 金鑰（[TdxConfig.hasCredential] 為 false），
  /// 則回傳 null，呼叫端應改用「不帶 Authorization header」的免金鑰模式。
  Future<String?> getAccessToken() async {
    if (!TdxConfig.hasCredential) return null;

    final now = DateTime.now();
    if (_accessToken != null && _expiresAt != null && now.isBefore(_expiresAt!)) {
      return _accessToken;
    }

    final response = await http.post(
      Uri.parse(TdxConfig.authUrl),
      headers: const {'content-type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': TdxConfig.clientId,
        'client_secret': TdxConfig.clientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('TDX 授權失敗 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 1800;

    _accessToken = token;
    // 提早 60 秒視為過期，避免臨界值造成請求失敗
    _expiresAt = now.add(Duration(seconds: expiresIn - 60));
    return _accessToken;
  }

  /// 產生呼叫 TDX API 所需的 HTTP headers
  Future<Map<String, String>> buildHeaders() async {
    final token = await getAccessToken();
    return {
      'accept': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
  }
}
