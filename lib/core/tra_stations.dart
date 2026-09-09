/// =====================================================================
/// 台鐵車站靜態資料（地區分類 + 車站代碼 + 座標）
/// =====================================================================
/// 這份資料取代原本透過 TDX API 即時查詢車站清單的做法，改為一份內建
/// 的靜態表，包含：車站名稱、TDX StationID、車站座標。
///
/// - 「地區分類」沿用原本 tra_regions.dart 的分組方式，方便「先選地區、
///   再選車站」的兩層選擇 UI。
/// - 「StationID」用於查詢起訖站時刻表（TDX OD API 需要車站代碼）。
/// - 「座標」用於「自動帶入最近車站」功能（依使用者定位找最近站）。
///
/// 注意：車站名稱統一用「台」而非「臺」，與 TDX 回傳的「臺北／臺中／
/// 臺南／臺東／臺中港」對應時會先做正規化。
class TraStationData {
  final String name;
  final String stationId;
  final double lat;
  final double lon;

  const TraStationData(this.name, this.stationId, this.lat, this.lon);
}

class TraStations {
  TraStations._();

  /// 地區顯示順序
  static const List<String> orderedRegions = [
    '台北地區',
    '桃園地區',
    '新竹地區',
    '苗栗地區',
    '台中地區',
    '彰化地區',
    '南投地區',
    '雲林地區',
    '嘉義地區',
    '台南地區',
    '高雄地區',
    '屏東地區',
    '台東地區',
    '花蓮地區',
    '宜蘭地區',
    '其他',
  ];

  /// 地區 -> 該地區的車站清單（含 StationID 與座標）
  static const Map<String, List<TraStationData>> stationsByRegion = {
    '台北地區': [
      TraStationData('基隆', '0900', 25.13191, 121.73837),
      TraStationData('三坑', '0910', 25.12305, 121.74202),
      TraStationData('暖暖', '7390', 25.10231, 121.74031),
      TraStationData('瑞芳', '7360', 25.10872, 121.80599),
      TraStationData('四腳亭', '7380', 25.10281, 121.76195),
      TraStationData('八堵', '0920', 25.10838, 121.72904),
      TraStationData('七堵', '0930', 25.09294, 121.71415),
      TraStationData('百福', '0940', 25.07795, 121.69379),
      TraStationData('五堵', '0950', 25.07799, 121.66758),
      TraStationData('汐止', '0960', 25.06790, 121.66113),
      TraStationData('汐科', '0970', 25.06406, 121.65233),
      TraStationData('南港', '0980', 25.05348, 121.60706),
      TraStationData('松山', '0990', 25.04927, 121.57906),
      TraStationData('台北', '1000', 25.04775, 121.51711),
      TraStationData('萬華', '1010', 25.03339, 121.49996),
      TraStationData('板橋', '1020', 25.01434, 121.46377),
      TraStationData('浮洲', '1030', 25.00419, 121.44477),
      TraStationData('樹林', '1040', 24.99123, 121.42442),
      TraStationData('南樹林', '1050', 24.98044, 121.40884),
      TraStationData('山佳', '1060', 24.97273, 121.39254),
      TraStationData('鶯歌', '1070', 24.95455, 121.35517),
      TraStationData('福隆', '7290', 25.01595, 121.94471),
      TraStationData('貢寮', '7300', 25.02197, 121.90879),
      TraStationData('雙溪', '7310', 25.03851, 121.86654),
      TraStationData('牡丹', '7320', 25.05871, 121.85197),
      TraStationData('大溪', '7260', 24.93836, 121.88983),
      TraStationData('龜山', '7250', 24.90484, 121.86890),
      TraStationData('石城', '7280', 24.97832, 121.94507),
      TraStationData('八斗子', '7362', 25.13528, 121.80286),
      TraStationData('海科館', '7361', 25.13754, 121.79997),
      TraStationData('三貂嶺', '7330', 25.06555, 121.82257),
      TraStationData('大華', '7331', 25.04998, 121.79732),
      TraStationData('十分', '7332', 25.04111, 121.77514),
      TraStationData('望古', '7333', 25.03445, 121.76349),
      TraStationData('嶺腳', '7334', 25.03016, 121.74795),
      TraStationData('平溪', '7335', 25.02571, 121.74019),
      TraStationData('菁桐', '7336', 25.02391, 121.72391),
    ],
    '桃園地區': [
      TraStationData('桃園', '1080', 24.98888, 121.31449),
      TraStationData('內壢', '1090', 24.97281, 121.25826),
      TraStationData('中壢', '1100', 24.95374, 121.22589),
      TraStationData('埔心', '1110', 24.91939, 121.18363),
      TraStationData('楊梅', '1120', 24.91427, 121.14637),
      TraStationData('富岡', '1130', 24.93436, 121.08309),
      TraStationData('新富', '1140', 24.93109, 121.06751),
    ],
    '新竹地區': [
      TraStationData('北湖', '1150', 24.92218, 121.05575),
      TraStationData('湖口', '1160', 24.90303, 121.04412),
      TraStationData('新豐', '1170', 24.86939, 120.99626),
      TraStationData('竹北', '1180', 24.83919, 121.00946),
      TraStationData('北新竹', '1190', 24.80875, 120.98381),
      TraStationData('新竹', '1210', 24.80157, 120.97157),
      TraStationData('三姓橋', '1220', 24.78731, 120.92844),
      TraStationData('香山', '1230', 24.76311, 120.91388),
      TraStationData('崎頂', '1240', 24.72291, 120.87183),
      TraStationData('千甲', '1191', 24.80657, 121.00340),
      TraStationData('新莊', '1192', 24.78811, 121.02196),
      TraStationData('竹中', '1193', 24.78145, 121.03141),
      TraStationData('上員', '1201', 24.77776, 121.05582),
      TraStationData('榮華', '1202', 24.74839, 121.08319),
      TraStationData('竹東', '1203', 24.73823, 121.09472),
      TraStationData('橫山', '1204', 24.72041, 121.11772),
      TraStationData('九讚頭', '1205', 24.72062, 121.13622),
      TraStationData('合興', '1206', 24.71667, 121.15437),
      TraStationData('富貴', '1207', 24.71551, 121.16743),
      TraStationData('內灣', '1208', 24.70535, 121.18255),
      TraStationData('六家', '1194', 24.80766, 121.03941),
    ],
    '苗栗地區': [
      TraStationData('竹南', '1250', 24.68654, 120.88041),
      TraStationData('造橋', '3140', 24.64186, 120.86721),
      TraStationData('豐富', '3150', 24.60429, 120.82637),
      TraStationData('苗栗', '3160', 24.57001, 120.82233),
      TraStationData('南勢', '3170', 24.52246, 120.79154),
      TraStationData('銅鑼', '3180', 24.48634, 120.78617),
      TraStationData('三義', '3190', 24.42066, 120.77393),
      TraStationData('泰安', '3210', 24.33146, 120.74181),
      TraStationData('談文', '2110', 24.65641, 120.85825),
      TraStationData('大山', '2120', 24.64565, 120.80376),
      TraStationData('後龍', '2130', 24.61621, 120.78731),
      TraStationData('龍港', '2140', 24.61169, 120.75812),
      TraStationData('白沙屯', '2150', 24.56481, 120.70824),
      TraStationData('新埔', '2160', 24.54018, 120.69518),
      TraStationData('通霄', '2170', 24.49141, 120.67843),
      TraStationData('苑裡', '2180', 24.44344, 120.65146),
    ],
    '台中地區': [
      TraStationData('后里', '3220', 24.30933, 120.73288),
      TraStationData('豐原', '3230', 24.25438, 120.72374),
      TraStationData('栗林', '3240', 24.23461, 120.71060),
      TraStationData('潭子', '3250', 24.21214, 120.70564),
      TraStationData('頭家厝', '3260', 24.19572, 120.70398),
      TraStationData('松竹', '3270', 24.18035, 120.70193),
      TraStationData('太原', '3280', 24.16449, 120.69988),
      TraStationData('台中', '3300', 24.13728, 120.68691),
      TraStationData('精武', '3290', 24.14887, 120.69784),
      TraStationData('大慶', '3320', 24.11911, 120.64795),
      TraStationData('烏日', '3330', 24.10867, 120.62244),
      TraStationData('新烏日', '3340', 24.10937, 120.61421),
      TraStationData('追分', '2260', 24.12051, 120.57018),
      TraStationData('大肚', '2250', 24.15417, 120.54249),
      TraStationData('日南', '2190', 24.37815, 120.65412),
      TraStationData('大甲', '2200', 24.34448, 120.62702),
      TraStationData('台中港', '2210', 24.30441, 120.60231),
      TraStationData('清水', '2220', 24.26364, 120.56918),
      TraStationData('沙鹿', '2230', 24.23702, 120.55752),
      TraStationData('龍井', '2240', 24.19748, 120.54335),
    ],
    '彰化地區': [
      TraStationData('成功', '3350', 24.11424, 120.59021),
      TraStationData('彰化', '3360', 24.08177, 120.53854),
      TraStationData('花壇', '3370', 24.02502, 120.53742),
      TraStationData('大村', '3380', 23.99002, 120.56062),
      TraStationData('員林', '3390', 23.95947, 120.56977),
      TraStationData('永靖', '3400', 23.92808, 120.57173),
      TraStationData('社頭', '3410', 23.89573, 120.58077),
      TraStationData('田中', '3420', 23.85843, 120.59146),
      TraStationData('二水', '3430', 23.81321, 120.61805),
    ],
    '南投地區': [
      TraStationData('源泉', '3431', 23.79845, 120.64211),
      TraStationData('濁水', '3432', 23.83467, 120.70467),
      TraStationData('龍泉', '3433', 23.83521, 120.75014),
      TraStationData('集集', '3434', 23.82647, 120.78495),
      TraStationData('水里', '3435', 23.81845, 120.85332),
      TraStationData('車埕', '3436', 23.83263, 120.86572),
    ],
    '雲林地區': [
      TraStationData('林內', '3450', 23.75967, 120.61499),
      TraStationData('石榴', '3460', 23.73167, 120.57998),
      TraStationData('斗六', '3470', 23.71184, 120.54099),
      TraStationData('斗南', '3480', 23.67257, 120.48089),
    ],
    '嘉義地區': [
      TraStationData('大林', '4050', 23.60089, 120.45597),
      TraStationData('民雄', '4060', 23.55522, 120.43165),
      TraStationData('嘉北', '4070', 23.49981, 120.44851),
      TraStationData('嘉義', '4080', 23.47915, 120.44114),
      TraStationData('水上', '4090', 23.43398, 120.39971),
      TraStationData('南靖', '4100', 23.41344, 120.38654),
    ],
    '台南地區': [
      TraStationData('後壁', '4110', 23.36626, 120.36058),
      TraStationData('林鳳營', '4140', 23.24259, 120.32107),
      TraStationData('柳營', '4130', 23.27762, 120.32252),
      TraStationData('新營', '4120', 23.30673, 120.32307),
      TraStationData('拔林', '4160', 23.17284, 120.32125),
      TraStationData('隆田', '4150', 23.19271, 120.31917),
      TraStationData('善化', '4170', 23.13333, 120.30653),
      TraStationData('南科', '4180', 23.10726, 120.30202),
      TraStationData('新市', '4190', 23.06823, 120.29004),
      TraStationData('永康', '4200', 23.03825, 120.25347),
      TraStationData('大橋', '4210', 23.01923, 120.22429),
      TraStationData('台南', '4220', 22.99681, 120.21295),
      TraStationData('保安', '4250', 22.93296, 120.23158),
      TraStationData('仁德', '4260', 22.92354, 120.24054),
      TraStationData('中洲', '4270', 22.90446, 120.25284),
      TraStationData('大湖', '4290', 22.87821, 120.25384),
    ],
    '高雄地區': [
      TraStationData('路竹', '4300', 22.85404, 120.26619),
      TraStationData('岡山', '4310', 22.79223, 120.30004),
      TraStationData('橋頭', '4320', 22.76098, 120.31011),
      TraStationData('楠梓', '4330', 22.72696, 120.32425),
      TraStationData('新左營', '4340', 22.68754, 120.30678),
      TraStationData('左營', '4350', 22.67445, 120.29401),
      TraStationData('內惟', '4360', 22.66589, 120.28701),
      TraStationData('美術館', '4370', 22.65185, 120.28148),
      TraStationData('鼓山', '4380', 22.64181, 120.28071),
      TraStationData('三塊厝', '4390', 22.63931, 120.29414),
      TraStationData('高雄', '4400', 22.63946, 120.30292),
      TraStationData('民族', '4410', 22.63879, 120.31494),
      TraStationData('科工館', '4420', 22.63709, 120.32603),
      TraStationData('正義', '4430', 22.63425, 120.34245),
      TraStationData('鳳山', '4440', 22.63145, 120.35745),
      TraStationData('後庄', '4450', 22.64016, 120.39131),
      TraStationData('九曲堂', '4460', 22.65641, 120.42089),
      TraStationData('六塊厝', '4470', 22.66597, 120.46497),
    ],
    '屏東地區': [
      TraStationData('屏東', '5000', 22.66905, 120.48617),
      TraStationData('歸來', '5010', 22.65246, 120.50263),
      TraStationData('麟洛', '5020', 22.63481, 120.51432),
      TraStationData('西勢', '5030', 22.61637, 120.52649),
      TraStationData('竹田', '5040', 22.58658, 120.53978),
      TraStationData('潮州', '5050', 22.55008, 120.53604),
      TraStationData('崁頂', '5060', 22.51311, 120.51481),
      TraStationData('南州', '5070', 22.49207, 120.51174),
      TraStationData('鎮安', '5080', 22.45794, 120.51129),
      TraStationData('加祿', '5130', 22.33085, 120.62445),
      TraStationData('枋寮', '5120', 22.36802, 120.59511),
      TraStationData('枋山', '5160', 22.26704, 120.65947),
      TraStationData('內獅', '5140', 22.30617, 120.64331),
      TraStationData('枋野', '5170', 22.28091, 120.71709),
    ],
    '台東地區': [
      TraStationData('大武', '5190', 22.36526, 120.90094),
      TraStationData('瀧溪', '5200', 22.46102, 120.94176),
      TraStationData('金崙', '5210', 22.53161, 120.96721),
      TraStationData('太麻里', '5220', 22.61883, 121.00492),
      TraStationData('知本', '5230', 22.71022, 121.06068),
      TraStationData('康樂', '5240', 22.76426, 121.09356),
      TraStationData('台東', '6000', 22.79372, 121.12310),
      TraStationData('山里', '6010', 22.86194, 121.13778),
      TraStationData('鹿野', '6020', 22.91249, 121.13701),
      TraStationData('瑞源', '6030', 22.95604, 121.15901),
      TraStationData('瑞和', '6040', 22.97997, 121.15595),
      TraStationData('關山', '6050', 23.04566, 121.16430),
      TraStationData('池上', '6070', 23.12613, 121.21949),
    ],
    '花蓮地區': [
      TraStationData('富里', '6080', 23.17924, 121.24864),
      TraStationData('東里', '6100', 23.27234, 121.30418),
      TraStationData('東竹', '6090', 23.22605, 121.27842),
      TraStationData('玉里', '6110', 23.33155, 121.31172),
      TraStationData('三民', '6120', 23.42458, 121.34539),
      TraStationData('瑞穗', '6130', 23.49738, 121.37684),
      TraStationData('富源', '6140', 23.58031, 121.38008),
      TraStationData('大富', '6150', 23.60571, 121.38963),
      TraStationData('光復', '6160', 23.66631, 121.42117),
      TraStationData('萬榮', '6170', 23.71199, 121.41907),
      TraStationData('鳳林', '6180', 23.74634, 121.44701),
      TraStationData('南平', '6190', 23.78231, 121.45824),
      TraStationData('林榮新光', '6200', 23.80176, 121.46169),
      TraStationData('豐田', '6210', 23.84842, 121.49618),
      TraStationData('壽豐', '6220', 23.86901, 121.51064),
      TraStationData('平和', '6230', 23.88279, 121.52045),
      TraStationData('志學', '6240', 23.90769, 121.52950),
      TraStationData('吉安', '6250', 23.96823, 121.58266),
      TraStationData('花蓮', '7000', 23.99265, 121.60131),
      TraStationData('北埔', '7010', 24.03253, 121.60166),
      TraStationData('景美', '7020', 24.09041, 121.61095),
      TraStationData('新城', '7030', 24.12756, 121.64086),
      TraStationData('崇德', '7040', 24.17199, 121.65536),
      TraStationData('和仁', '7050', 24.24225, 121.71182),
      TraStationData('和平', '7060', 24.29839, 121.75344),
      TraStationData('漢本', '7070', 24.33543, 121.76838),
    ],
    '宜蘭地區': [
      TraStationData('南澳', '7090', 24.46342, 121.80103),
      TraStationData('武塔', '7080', 24.44879, 121.77601),
      TraStationData('東澳', '7100', 24.51827, 121.83072),
      TraStationData('永樂', '7110', 24.56843, 121.84458),
      TraStationData('蘇澳新', '7130', 24.60852, 121.82735),
      TraStationData('蘇澳', '7120', 24.59516, 121.85143),
      TraStationData('新馬', '7140', 24.61541, 121.82291),
      TraStationData('冬山', '7150', 24.63633, 121.79211),
      TraStationData('羅東', '7160', 24.67791, 121.77464),
      TraStationData('二結', '7180', 24.70528, 121.77409),
      TraStationData('中里', '7170', 24.69415, 121.77526),
      TraStationData('宜蘭', '7190', 24.75457, 121.75803),
      TraStationData('四城', '7200', 24.78681, 121.76271),
      TraStationData('礁溪', '7210', 24.82703, 121.77535),
      TraStationData('頭城', '7230', 24.85898, 121.82258),
      TraStationData('外澳', '7240', 24.88375, 121.84572),
    ],
  };

  /// 所有車站（攤平）
  static List<TraStationData> get all =>
      stationsByRegion.values.expand((e) => e).toList();

  /// 將站名正規化（統一用「台」取代「臺」）
  static String _normalize(String name) => name.replaceAll('臺', '台');

  /// 依站名取得所屬地區；找不到時歸類到「其他」
  static String regionOf(String stationName) {
    final n = _normalize(stationName);
    for (final entry in stationsByRegion.entries) {
      if (entry.value.any((s) => s.name == n)) return entry.key;
    }
    return '其他';
  }

  /// 依站名取得車站資料
  static TraStationData? byName(String name) {
    final n = _normalize(name);
    for (final s in all) {
      if (s.name == n) return s;
    }
    return null;
  }

  /// 依 StationID 取得車站資料
  static TraStationData? byId(String id) {
    for (final s in all) {
      if (s.stationId == id) return s;
    }
    return null;
  }

  /// 依座標找出最近的車站（用於「自動帶入最近車站」）
  static TraStationData nearest(double lat, double lon) {
    TraStationData best = all.first;
    double bestD = _distSq(lat, lon, best.lat, best.lon);
    for (final s in all) {
      final d = _distSq(lat, lon, s.lat, s.lon);
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best;
  }

  static double _distSq(double lat1, double lon1, double lat2, double lon2) {
    final dlat = lat1 - lat2;
    final dlon = lon1 - lon2;
    return dlat * dlat + dlon * dlon;
  }
}
