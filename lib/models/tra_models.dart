/// =====================================================================
/// 台鐵（TRA）資料模型
/// =====================================================================
/// 對應 TDX 運輸資料流通服務平臺 v3 版 API 的回傳格式。
/// 若日後 TDX 調整欄位名稱，理論上只需要修改這個檔案裡的 fromJson，
/// 畫面端的程式不需要跟著改動。
///
/// 注意：TDX API 偶爾會微調欄位，這裡的解析都盡量寫得寬鬆一點
/// （欄位不存在時給預設值），避免因單一欄位缺漏就整包解析失敗。

/// 雙語名稱（車站名 / 車種名 都是這個格式：{ "Zh_tw": "台北", "En": "Taipei" }）
class BilingualName {
  final String zhTw;
  final String en;

  const BilingualName({this.zhTw = '', this.en = ''});

  factory BilingualName.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BilingualName();
    return BilingualName(
      zhTw: json['Zh_tw']?.toString() ?? '',
      en: json['En']?.toString() ?? '',
    );
  }
}

/// 台鐵車站
class TraStation {
  final String stationId;
  final BilingualName stationName;

  const TraStation({required this.stationId, required this.stationName});

  String get name => stationName.zhTw;

  factory TraStation.fromJson(Map<String, dynamic> json) {
    return TraStation(
      stationId: json['StationID']?.toString() ?? '',
      stationName: BilingualName.fromJson(
        json['StationName'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// 台鐵車種（例如：自強、莒光、區間車...）
class TraTrainType {
  final String trainTypeId;
  final BilingualName trainTypeName;

  const TraTrainType({required this.trainTypeId, required this.trainTypeName});

  String get name => trainTypeName.zhTw;

  factory TraTrainType.fromJson(Map<String, dynamic> json) {
    return TraTrainType(
      trainTypeId: json['TrainTypeID']?.toString() ?? '',
      trainTypeName: BilingualName.fromJson(
        json['TrainTypeName'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// 車次基本資訊（車次號、車種、起訖站、方向...）
class TraTrainInfo {
  final String trainNo;
  final String direction; // "0"=順行(南下), "1"=逆行(北上)
  final String trainTypeId;
  final String trainTypeName;
  final String startingStationName;
  final String endingStationName;
  final String note;

  const TraTrainInfo({
    required this.trainNo,
    required this.direction,
    required this.trainTypeId,
    required this.trainTypeName,
    required this.startingStationName,
    required this.endingStationName,
    this.note = '',
  });

  factory TraTrainInfo.fromJson(Map<String, dynamic> json) {
    return TraTrainInfo(
      trainNo: json['TrainNo']?.toString() ?? '',
      direction: json['Direction']?.toString() ?? '',
      trainTypeId: json['TrainTypeID']?.toString() ?? '',
      trainTypeName: BilingualName.fromJson(
        json['TrainTypeName'] as Map<String, dynamic>?,
      ).zhTw,
      startingStationName: BilingualName.fromJson(
        json['StartingStationName'] as Map<String, dynamic>?,
      ).zhTw,
      endingStationName: BilingualName.fromJson(
        json['EndingStationName'] as Map<String, dynamic>?,
      ).zhTw,
      note: json['Note']?.toString() ?? '',
    );
  }
}

/// 起訖站查詢中，單一站的到/離站時間（簡易版，OD 查詢結果用）
class TraStopTimeBrief {
  final String stationId;
  final String stationName;
  final String arrivalTime; // "HH:mm" 或 "HH:mm:ss"
  final String departureTime;

  const TraStopTimeBrief({
    required this.stationId,
    required this.stationName,
    required this.arrivalTime,
    required this.departureTime,
  });

  factory TraStopTimeBrief.fromJson(Map<String, dynamic> json) {
    return TraStopTimeBrief(
      stationId: json['StationID']?.toString() ?? '',
      stationName: BilingualName.fromJson(
        json['StationName'] as Map<String, dynamic>?,
      ).zhTw,
      arrivalTime: json['ArrivalTime']?.toString() ?? '',
      departureTime: json['DepartureTime']?.toString() ?? '',
    );
  }
}

/// A 站到 B 站的時刻表清單，單一筆（畫面上清單的一列）
class TraTimetableEntry {
  final TraTrainInfo trainInfo;
  final TraStopTimeBrief originStopTime;
  final TraStopTimeBrief destinationStopTime;

  const TraTimetableEntry({
    required this.trainInfo,
    required this.originStopTime,
    required this.destinationStopTime,
  });

  factory TraTimetableEntry.fromJson(Map<String, dynamic> json) {
    return TraTimetableEntry(
      trainInfo: TraTrainInfo.fromJson(
        json['TrainInfo'] as Map<String, dynamic>? ?? const {},
      ),
      originStopTime: TraStopTimeBrief.fromJson(
        json['OriginStopTime'] as Map<String, dynamic>? ?? const {},
      ),
      destinationStopTime: TraStopTimeBrief.fromJson(
        json['DestinationStopTime'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// 列車完整停靠站時刻（詳細頁用，包含沿途所有站）
class TraTrainStopDetail {
  final int stopSequence;
  final String stationId;
  final String stationName;
  final String arrivalTime;
  final String departureTime;

  const TraTrainStopDetail({
    required this.stopSequence,
    required this.stationId,
    required this.stationName,
    required this.arrivalTime,
    required this.departureTime,
  });

  factory TraTrainStopDetail.fromJson(Map<String, dynamic> json) {
    return TraTrainStopDetail(
      stopSequence: int.tryParse(json['StopSequence']?.toString() ?? '') ?? 0,
      stationId: json['StationID']?.toString() ?? '',
      stationName: BilingualName.fromJson(
        json['StationName'] as Map<String, dynamic>?,
      ).zhTw,
      arrivalTime: json['ArrivalTime']?.toString() ?? '',
      departureTime: json['DepartureTime']?.toString() ?? '',
    );
  }
}

/// 單一車次的完整每日時刻表（詳細頁用）
class TraTrainTimetableDetail {
  final TraTrainInfo trainInfo;
  final List<TraTrainStopDetail> stopTimes;

  const TraTrainTimetableDetail({
    required this.trainInfo,
    required this.stopTimes,
  });

  factory TraTrainTimetableDetail.fromJson(Map<String, dynamic> json) {
    final rawStops = json['StopTimes'] as List<dynamic>? ?? const [];
    final stops = rawStops
        .map((e) => TraTrainStopDetail.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return TraTrainTimetableDetail(
      trainInfo: TraTrainInfo.fromJson(
        json['TrainInfo'] as Map<String, dynamic>? ?? const {},
      ),
      stopTimes: stops,
    );
  }
}

/// 列車即時動態（誤點分鐘數 / 目前所在或即將到達的車站）
class TraLiveBoard {
  final String trainNo;
  final String stationId;
  final String stationName;
  final int delayTime; // 誤點分鐘數，0 表示準點
  final String updateTime;

  const TraLiveBoard({
    required this.trainNo,
    required this.stationId,
    required this.stationName,
    required this.delayTime,
    required this.updateTime,
  });

  bool get isDelayed => delayTime > 0;

  factory TraLiveBoard.fromJson(Map<String, dynamic> json) {
    return TraLiveBoard(
      trainNo: json['TrainNo']?.toString() ?? '',
      stationId: json['StationID']?.toString() ?? '',
      stationName: BilingualName.fromJson(
        json['StationName'] as Map<String, dynamic>?,
      ).zhTw,
      delayTime: int.tryParse(json['DelayTime']?.toString() ?? '') ?? 0,
      updateTime: json['UpdateTime']?.toString() ?? '',
    );
  }
}
