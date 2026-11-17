import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/train/tra_models.dart';

/// 後端回傳 status != 0 時丟出的例外，message 為後端提供的訊息。
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);

  @override
  String toString() => message;
}

/// =====================================================================
/// 台鐵（TRA）資料服務
/// =====================================================================
/// 所有台鐵資料皆透過自建後端取得（路徑前綴 /api/tdx/train）。
/// 後端統一回傳格式：
/// ```json
/// { "status": 0, "message": "查詢成功", "detail": { ...TDX 原始內容... } }
/// ```
/// status = 0 為成功（message 可能是「查詢成功」或「查無結果」），
/// status = 1 為失敗，detail 為空物件。
class TraService {
  TraService._internal();
  static final TraService instance = TraService._internal();

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}${ApiConfig.trainPath}$path')
        .replace(queryParameters: query);
  }

  /// 呼叫後端並回傳 detail 內容；status != 0 時丟出 [BackendException]
  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = _buildUri(path, query);
    final response = await http
        .get(uri, headers: const {'accept': 'application/json'})
        .timeout(const Duration(seconds: ApiConfig.requestTimeoutSeconds));

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (body == null) {
      throw BackendException('伺服器回應格式錯誤 (${response.statusCode})');
    }
    final status = (body['status'] as num?)?.toInt() ?? 1;
    if (status != 0) {
      throw BackendException(body['message']?.toString() ?? '查詢失敗');
    }
    return body['detail'];
  }

  /// 從 detail 中取出指定的陣列欄位（例如 TrainTimetables / StationLiveBoards）
  Future<List<dynamic>> _getList(
    String path, {
    required String arrayKey,
    Map<String, String>? query,
  }) async {
    final detail = await _get(path, query);
    if (detail is List) return detail;
    if (detail is Map && detail[arrayKey] is List) {
      return detail[arrayKey] as List<dynamic>;
    }
    return const [];
  }

  /// 將底層例外轉成「人話」訊息，讓畫面顯示友善提示。
  static String friendlyMessage(Object e) {
    if (e is BackendException) return e.message;
    final msg = e.toString();
    if (e is TimeoutException ||
        msg.contains('Timeout') ||
        msg.contains('timed out')) {
      return '連線逾時，請檢查網路連線後再試一次。';
    }
    if (msg.contains('Socket') ||
        msg.contains('Failed host') ||
        msg.contains('Network') ||
        msg.contains('handshake') ||
        msg.contains('Connection')) {
      return '網路連線異常，請檢查網路連線後再試一次。';
    }
    return '系統發生錯誤，請稍後再試。';
  }

  /// 查詢「起站 -> 迄站」在指定日期的所有時刻表
  /// GET /timetable?from=&to=&date=yyyy-MM-dd
  Future<List<TraTimetableEntry>> getOdTimetable({
    required String originStationId,
    required String destinationStationId,
    required String trainDate,
  }) async {
    final data = await _getList(
      '/timetable',
      arrayKey: 'TrainTimetables',
      query: {
        'from': originStationId,
        'to': destinationStationId,
        'date': trainDate,
      },
    );
    return data
        .map((e) => TraTimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查詢單一車次在指定日期的完整停靠站時刻（用於「車次詳細資料」頁）
  /// GET /trainTimetable?trainNo=&date=yyyy-MM-dd
  Future<TraTrainTimetableDetail?> getTrainStopTimes({
    required String trainNo,
    required String trainDate,
  }) async {
    final data = await _getList(
      '/trainTimetable',
      arrayKey: 'TrainTimetables',
      query: {'trainNo': trainNo, 'date': trainDate},
    );
    if (data.isEmpty) return null;
    return TraTrainTimetableDetail.fromJson(data.first as Map<String, dynamic>);
  }

  /// 取得指定車站的即時到離站看板（誤點資訊），以車次號為 key。
  /// GET /liveBoard?stationId=
  ///
  /// 即時動態查詢失敗不應讓整個畫面失敗，這裡吞掉錯誤並回傳空 map。
  Future<Map<String, TraLiveBoard>> getStationLiveBoards(String stationId) async {
    try {
      final data = await _getList(
        '/liveBoard',
        arrayKey: 'StationLiveBoards',
        query: {'stationId': stationId},
      );
      final boards = data
          .map((e) => TraLiveBoard.fromJson(e as Map<String, dynamic>))
          .toList();
      return {for (final b in boards) b.trainNo: b};
    } catch (_) {
      return {};
    }
  }
}
