import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/tdx_config.dart';
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
  /// TDX v3 大多數端點的實際回傳格式，其實不是單純的陣列，而是像這樣的
  /// 包裝物件：
  /// ```json
  /// { "UpdateTime": "...", "TrainDate": "...", "TrainTimetables": [ ... ] }
  /// ```
  /// 陣列被放在一個「資料集專屬」的 key 底下（例如 TrainTimetables /
  /// Stations / TrainTypes / TrainLiveBoards）。這裡的邏輯依序嘗試：
  /// 1. 如果整包本身就是陣列（保留相容性，以防未來 API 改回單純陣列）
  /// 2. 如果有指定 [arrayKey]，直接取該欄位
  /// 3. 都沒有的話，自動掃描物件底下第一個型別為 List 的欄位（容錯）
  /// 4. 真的找不到任何陣列，才視為錯誤訊息物件並丟出例外
  Future<List<dynamic>> _getList(
    String path, {
    String? arrayKey,
    Map<String, String>? query,
  }) async {
    final data = await _get(path, query);

    if (data is List) return data;

    if (data is Map) {
      if (arrayKey != null && data[arrayKey] is List) {
        return data[arrayKey] as List<dynamic>;
      }
      for (final value in data.values) {
        if (value is List) return value;
      }
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
    final data = await _getList('/v3/Rail/TRA/Station', arrayKey: 'Stations');
    final stations =
        data.map((e) => TraStation.fromJson(e as Map<String, dynamic>)).toList();
    _stationCache = stations;
    return stations;
  }

  /// 查詢「起站 -> 迄站」在指定日期的所有時刻表
  /// [trainDate] 格式為 yyyy-MM-dd
  ///
  /// 實測 TDX 回傳格式為：
  /// ```json
  /// { "UpdateTime": "...", "TrainDate": "...", "TrainTimetables": [
  ///     { "TrainInfo": {...}, "StopTimes": [起站, 迄站] }, ...
  /// ] }
  /// ```
  Future<List<TraTimetableEntry>> getOdTimetable({
    required String originStationId,
    required String destinationStationId,
    required String trainDate,
  }) async {
    final path =
        '/v3/Rail/TRA/DailyTrainTimetable/OD/$originStationId/to/$destinationStationId/$trainDate';
    final data = await _getList(path, arrayKey: 'TrainTimetables');
    return data
        .map((e) => TraTimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查詢單一車次在指定日期的完整停靠站時刻（用於「車次詳細資料」頁）
  Future<TraTrainTimetableDetail?> getTrainStopTimes({
    required String trainNo,
    required String trainDate,
  }) async {
    const path =
        '/v3/Rail/TRA/DailyTrainTimetable/TrainDate/';

    final data = await _getList(
      '$path$trainDate',
      arrayKey: 'TrainTimetables',
      query: {
        r'$filter': "TrainInfo/TrainNo eq '$trainNo'",
      },
    );

    if (data.isNotEmpty) {
      return TraTrainTimetableDetail.fromJson(
        data.first as Map<String, dynamic>,
      );
    }

    return null;
  }

  /// 取得「目前所有正在行駛」列車的即時動態（誤點、目前位置），
  /// 一次查全部再由畫面端依 TrainNo 過濾，比對每個車次各查一次更省流量。
  Future<Map<String, TraLiveBoard>> getAllLiveBoards() async {
    try {
      final data = await _getList('/v3/Rail/TRA/TrainLiveBoard', arrayKey: 'TrainLiveBoards');
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
