import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/tdx_config.dart';
import '../core/train_type_catalog.dart';
import '../models/tra_models.dart';
import 'tdx_auth_service.dart';

/// =====================================================================
/// 台鐵（TRA）資料服務
/// =====================================================================
/// 封裝所有跟「台鐵」有關的 TDX API 呼叫。
///
/// 之後如果要新增公車 / 高鐵 / 捷運，建議依樣畫葫蘆各寫一個
/// `BusService` / `ThsrService` / `MetroService`，
/// 並讓它們都透過同一個 [TdxAuthService] 取得 token，
/// 這樣主畫面/查詢流程的架構完全不用改，只要多插一個模組進去即可。
class TraService {
  TraService._internal();
  static final TraService instance = TraService._internal();

  final _auth = TdxAuthService.instance;

  // 車站清單快取（一整天內幾乎不會變動，查一次快取起來即可）
  List<TraStation>? _stationCache;
  // 車種清單快取
  List<TraTrainType>? _trainTypeCache;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('${TdxConfig.apiBaseUrl}$path').replace(
      queryParameters: {
        '\$format': 'JSON',
        ...?query,
      },
    );
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final headers = await _auth.buildHeaders();
    final uri = _buildUri(path, query);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('TDX API 錯誤 (${response.statusCode}): $uri\n${response.body}');
    }
    // TDX 回應是 UTF-8 編碼的 JSON，這裡明確指定 decode 方式避免中文亂碼
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// 呼叫「預期回傳陣列」的 API。
  ///
  /// TDX 在金鑰未設定 / 超過免金鑰額度（每來源 IP 每日約 50 次）/
  /// 帳號未訂閱該資料集等情況下，仍可能回傳 HTTP 200，
  /// 但內容是一個「錯誤說明物件」(Map) 而不是預期的陣列(List)。
  /// 這裡先做型別檢查，遇到這種情況丟出「看得懂」的錯誤訊息，
  /// 而不是讓 `as List<dynamic>` 直接丟出難以理解的 TypeError。
  Future<List<dynamic>> _getList(String path, [Map<String, String>? query]) async {
    final data = await _get(path, query);
    if (data is List) return data;
    if (data is Map) {
      final message = data['Message'] ?? data['message'] ?? data.toString();
      final hint = TdxConfig.hasCredential
          ? ''
          : '（目前未設定 TDX_CLIENT_ID / TDX_CLIENT_SECRET，請確認已用 --dart-define 帶入金鑰，'
          '免金鑰模式每日呼叫次數非常有限，很容易超過額度）';
      throw Exception('TDX API 回傳非預期格式：$message$hint');
    }
    throw Exception('TDX API 回傳非預期格式（既非陣列也非物件）：$data');
  }

  /// 取得台鐵所有車站清單
  Future<List<TraStation>> getStations({bool forceRefresh = false}) async {
    if (!forceRefresh && _stationCache != null) return _stationCache!;
    final data = await _getList('/v3/Rail/TRA/Station');
    final stations =
    data.map((e) => TraStation.fromJson(e as Map<String, dynamic>)).toList();
    _stationCache = stations;
    return stations;
  }

  /// 取得台鐵車種清單；查詢失敗時退回內建的預設清單，
  /// 確保「選擇車種」畫面永遠有東西可以勾選。
  Future<List<TraTrainType>> getTrainTypes({bool forceRefresh = false}) async {
    if (!forceRefresh && _trainTypeCache != null) return _trainTypeCache!;
    try {
      final data = await _getList('/v3/Rail/TRA/TrainType');
      final types = data
          .map((e) => TraTrainType.fromJson(e as Map<String, dynamic>))
          .toList();
      if (types.isNotEmpty) {
        _trainTypeCache = types;
        return types;
      }
    } catch (_) {
      // 忽略錯誤，改用預設清單
    }
    _trainTypeCache = TrainTypeCatalog.defaultTypes;
    return _trainTypeCache!;
  }

  /// 查詢「起站 -> 迄站」在指定日期的所有時刻表
  /// [trainDate] 格式為 yyyy-MM-dd
  Future<List<TraTimetableEntry>> getOdTimetable({
    required String originStationId,
    required String destinationStationId,
    required String trainDate,
  }) async {
    final path =
        '/v3/Rail/TRA/DailyTrainTimetable/OD/$originStationId/to/$destinationStationId/$trainDate';
    final data = await _getList(path);
    return data
        .map((e) => TraTimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查詢單一車次在指定日期的完整停靠站時刻（用於「車次詳細資料」頁）
  Future<TraTrainTimetableDetail?> getTrainStopTimes({
    required String trainNo,
    required String trainDate,
  }) async {
    final path = '/v3/Rail/TRA/DailyTrainTimetable/TrainDate/$trainDate/TrainNo/$trainNo';
    final data = await _get(path);
    // TDX 這支 API 可能回傳單一物件、或包一層陣列，這裡兩種都相容處理
    if (data is List && data.isNotEmpty) {
      return TraTrainTimetableDetail.fromJson(data.first as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return TraTrainTimetableDetail.fromJson(data);
    }
    return null;
  }

  /// 取得「目前所有正在行駛」列車的即時動態（誤點、目前位置），
  /// 一次查全部再由畫面端依 TrainNo 過濾，比對每個車次各查一次更省流量。
  Future<Map<String, TraLiveBoard>> getAllLiveBoards() async {
    try {
      final data = await _getList('/v3/Rail/TRA/TrainLiveBoard');
      final boards = data
          .map((e) => TraLiveBoard.fromJson(e as Map<String, dynamic>))
          .toList();
      return {for (final b in boards) b.trainNo: b};
    } catch (_) {
      // 即時動態查詢失敗不應該讓整個時刻表查詢跟著失敗，
      // 這裡吞掉錯誤、回傳空 map，畫面上就是不顯示誤點資訊而已。
      return {};
    }
  }
}
