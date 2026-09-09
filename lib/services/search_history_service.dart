import 'package:sqflite/sqflite.dart';

/// =====================================================================
/// 本機歷史查詢與常用路線儲存（SQLite，離線、不需網路）
/// =====================================================================
/// 記錄使用者查詢過的起訖站組合（歷史），以及使用者加入「愛心」的常用
/// 路線（可自訂名稱，例如「回家」）。全部存在本機 SQLite，不經過網路。
class SearchRecord {
  final int? id;
  final String originName;
  final String originId;
  final String destinationName;
  final String destinationId;
  final String? label; // 常用路線自訂名稱；歷史紀錄為 null
  final bool isFavorite;
  final DateTime createdAt;

  const SearchRecord({
    this.id,
    required this.originName,
    required this.originId,
    required this.destinationName,
    required this.destinationId,
    this.label,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory SearchRecord.fromMap(Map<String, dynamic> m) => SearchRecord(
        id: m['id'] as int?,
        originName: m['origin_name'] as String? ?? '',
        originId: m['origin_id'] as String? ?? '',
        destinationName: m['destination_name'] as String? ?? '',
        destinationId: m['destination_id'] as String? ?? '',
        label: m['label'] as String?,
        isFavorite: (m['is_favorite'] as int?) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((m['created_at'] as int?) ?? 0),
      );

  /// 顯示名稱：有自訂名稱就用自訂名稱，否則用「起 → 迄」
  String get displayLabel =>
      (label != null && label!.isNotEmpty) ? label! : '$originName → $destinationName';
}

class SearchHistoryService {
  SearchHistoryService._internal();
  static final SearchHistoryService instance = SearchHistoryService._internal();

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase('$dir/taiwan_transit.db', version: 1,
        onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE search_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          origin_name TEXT NOT NULL,
          origin_id TEXT NOT NULL,
          destination_name TEXT NOT NULL,
          destination_id TEXT NOT NULL,
          label TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          UNIQUE(origin_id, destination_id, is_favorite)
        )
      ''');
    });
    return _db!;
  }

  /// 新增一筆歷史查詢（同樣的起訖組合會更新到最前面，只保留最近 20 筆）
  Future<void> addHistory({
    required String originName,
    required String originId,
    required String destinationName,
    required String destinationId,
  }) async {
    if (originId == destinationId) return;
    final db = await _database();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('search_records',
        where: 'origin_id = ? AND destination_id = ? AND is_favorite = 0',
        whereArgs: [originId, destinationId]);
    await db.insert('search_records', {
      'origin_name': originName,
      'origin_id': originId,
      'destination_name': destinationName,
      'destination_id': destinationId,
      'label': null,
      'is_favorite': 0,
      'created_at': now,
    });
    // 只保留最近 20 筆歷史
    final histories = await db.query('search_records',
        where: 'is_favorite = 0', orderBy: 'created_at DESC', limit: 20);
    if (histories.length == 20) {
      final keepIds = histories.map((h) => h['id'] as int).toList();
      final placeholders = List.filled(keepIds.length, '?').join(',');
      await db.delete('search_records',
          where: 'is_favorite = 0 AND id NOT IN ($placeholders)',
          whereArgs: keepIds);
    }
  }

  Future<List<SearchRecord>> getHistory({int limit = 10}) async {
    final db = await _database();
    final rows = await db.query('search_records',
        where: 'is_favorite = 0', orderBy: 'created_at DESC', limit: limit);
    return rows.map(SearchRecord.fromMap).toList();
  }

  Future<void> clearHistory() async {
    final db = await _database();
    await db.delete('search_records', where: 'is_favorite = 0');
  }

  /// 加入常用路線（已存在則更新名稱）
  Future<SearchRecord> addFavorite({
    required String originName,
    required String originId,
    required String destinationName,
    required String destinationId,
    required String label,
  }) async {
    final db = await _database();
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('search_records',
        where: 'origin_id = ? AND destination_id = ? AND is_favorite = 1',
        whereArgs: [originId, destinationId]);
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
          'search_records',
          {
            'label': label,
            'origin_name': originName,
            'destination_name': destinationName,
            'created_at': now,
          },
          where: 'id = ?',
          whereArgs: [id]);
      return SearchRecord(
          id: id,
          originName: originName,
          originId: originId,
          destinationName: destinationName,
          destinationId: destinationId,
          label: label,
          isFavorite: true,
          createdAt: DateTime.now());
    }
    final id = await db.insert('search_records', {
      'origin_name': originName,
      'origin_id': originId,
      'destination_name': destinationName,
      'destination_id': destinationId,
      'label': label,
      'is_favorite': 1,
      'created_at': now,
    });
    return SearchRecord(
        id: id,
        originName: originName,
        originId: originId,
        destinationName: destinationName,
        destinationId: destinationId,
        label: label,
        isFavorite: true,
        createdAt: DateTime.now());
  }

  Future<List<SearchRecord>> getFavorites() async {
    final db = await _database();
    final rows = await db.query('search_records',
        where: 'is_favorite = 1', orderBy: 'created_at DESC');
    return rows.map(SearchRecord.fromMap).toList();
  }

  Future<bool> isFavorite(String originId, String destinationId) async {
    final db = await _database();
    final rows = await db.query('search_records',
        where: 'origin_id = ? AND destination_id = ? AND is_favorite = 1',
        whereArgs: [originId, destinationId],
        limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> removeFavorite(int id) async {
    final db = await _database();
    await db.delete('search_records',
        where: 'id = ? AND is_favorite = 1', whereArgs: [id]);
  }

  Future<void> renameFavorite(int id, String label) async {
    final db = await _database();
    await db.update('search_records', {'label': label},
        where: 'id = ? AND is_favorite = 1', whereArgs: [id]);
  }
}
