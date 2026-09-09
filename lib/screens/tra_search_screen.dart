import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/app_theme.dart';
import '../core/tra_stations.dart';
import '../models/tra_models.dart';
import '../services/search_history_service.dart';
import '../widgets/region_station_picker_sheet.dart';
import '../widgets/wheel_time_picker.dart';
import 'tra_results_screen.dart';

/// =====================================================================
/// 台鐵時刻表查詢畫面
/// =====================================================================
/// 使用者在這裡選擇：起站、迄站（先選地區、再選車站）、出發時間，
/// 按下查詢後導向 [TraResultsScreen]。
///
/// 車站清單來自內建靜態資料 [TraStations]（不再透過 API 查詢站名）。
/// 開啟畫面時會嘗試自動帶入「最近車站」為起站（逾時約 5 秒即放棄，
/// 不影響使用者操作）。
/// 歷史查詢與常用路線（愛心）儲存在本機 SQLite，不需網路。
class TraSearchScreen extends StatefulWidget {
  const TraSearchScreen({super.key});

  @override
  State<TraSearchScreen> createState() => _TraSearchScreenState();
}

class _TraSearchScreenState extends State<TraSearchScreen> {
  late final List<TraStation> _stations;

  TraStation? _origin;
  TraStation? _destination;

  late TimeOfDay _startTime;

  List<SearchRecord> _favorites = [];
  List<SearchRecord> _history = [];
  bool _isCurrentFavorite = false;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _stations = TraStations.all
        .map((s) => TraStation(
            stationId: s.stationId, stationName: BilingualName(zhTw: s.name)))
        .toList();
    _loadSavedData();
    _autoDetectNearestStation();
  }

  Future<void> _loadSavedData() async {
    final fav = await SearchHistoryService.instance.getFavorites();
    final hist = await SearchHistoryService.instance.getHistory();
    if (mounted) {
      setState(() {
        _favorites = fav;
        _history = hist;
      });
      _refreshFavoriteState();
    }
  }

  /// 嘗試取得定位並自動帶入最近車站為起站。
  /// 任何失敗（權限拒絕、逾時、定位失敗）都直接放棄，不讓畫面崩潰。
  Future<void> _autoDetectNearestStation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission().timeout(const Duration(seconds: 2));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 2));
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(timeLimit: Duration(seconds: 5)))
          .timeout(const Duration(seconds: 5));

      final nearest = TraStations.nearest(position.latitude, position.longitude);
      if (mounted && _origin == null) {
        setState(() => _origin = _toStation(nearest));
      }
    } catch (_) {
      // 忽略任何錯誤，避免使用者在此頁面因任何原因而崩潰
    }
  }

  TraStation _toStation(TraStationData d) =>
      TraStation(stationId: d.stationId, stationName: BilingualName(zhTw: d.name));

  Future<void> _refreshFavoriteState() async {
    if (_origin == null || _destination == null) {
      if (mounted) setState(() => _isCurrentFavorite = false);
      return;
    }
    final fav = await SearchHistoryService.instance
        .isFavorite(_origin!.stationId, _destination!.stationId);
    if (mounted) setState(() => _isCurrentFavorite = fav);
  }

  Future<void> _pickOrigin() async {
    final result = await showRegionStationPickerSheet(
      context: context,
      stations: _stations,
      title: '選擇起站',
    );
    if (result != null) {
      setState(() => _origin = result);
      _refreshFavoriteState();
    }
  }

  Future<void> _pickDestination() async {
    final result = await showRegionStationPickerSheet(
      context: context,
      stations: _stations,
      title: '選擇迄站',
    );
    if (result != null) {
      setState(() => _destination = result);
      _refreshFavoriteState();
    }
  }

  void _swapStations() {
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
    _refreshFavoriteState();
  }

  Future<void> _pickDepartureTime() async {
    await showDepartureTimePickerSheet(
      context: context,
      initialTime: _startTime,
      onConfirm: (t) => setState(() => _startTime = t),
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _canQuery =>
      _origin != null &&
      _destination != null &&
      _origin!.stationId != _destination!.stationId;

  void _onQuery() {
    if (!_canQuery) return;
    SearchHistoryService.instance.addHistory(
      originName: _origin!.name,
      originId: _origin!.stationId,
      destinationName: _destination!.name,
      destinationId: _destination!.stationId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TraResultsScreen(
          origin: _origin!,
          destination: _destination!,
          startTime: _startTime,
          endTime: const TimeOfDay(hour: 23, minute: 59),
        ),
      ),
    );
  }

  void _applyRecord(SearchRecord r) {
    final o = TraStations.byName(r.originName);
    final d = TraStations.byName(r.destinationName);
    setState(() {
      if (o != null) _origin = _toStation(o);
      if (d != null) _destination = _toStation(d);
    });
    _refreshFavoriteState();
  }

  Future<void> _toggleFavorite() async {
    if (!_canQuery) return;
    if (_isCurrentFavorite) {
      final favs = await SearchHistoryService.instance.getFavorites();
      final match = favs
          .where((f) =>
              f.originId == _origin!.stationId &&
              f.destinationId == _destination!.stationId)
          .toList();
      if (match.isNotEmpty) {
        await SearchHistoryService.instance.removeFavorite(match.first.id!);
      }
    } else {
      final label = await _askFavoriteLabel();
      if (label == null || label.isEmpty) return;
      await SearchHistoryService.instance.addFavorite(
        originName: _origin!.name,
        originId: _origin!.stationId,
        destinationName: _destination!.name,
        destinationId: _destination!.stationId,
        label: label,
      );
    }
    await _loadSavedData();
  }

  Future<String?> _askFavoriteLabel() async {
    final controller =
        TextEditingController(text: '${_origin!.name} → ${_destination!.name}');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加入常用路線'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '自訂名稱，例如「回家」'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFavoriteOptions(SearchRecord r) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('重新命名'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('刪除', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') {
      final controller = TextEditingController(text: r.label ?? '');
      final newLabel = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('重新命名'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('儲存'),
            ),
          ],
        ),
      );
      if (newLabel != null && newLabel.isNotEmpty) {
        await SearchHistoryService.instance.renameFavorite(r.id!, newLabel);
        await _loadSavedData();
      }
    } else if (action == 'delete') {
      await SearchHistoryService.instance.removeFavorite(r.id!);
      await _loadSavedData();
      _refreshFavoriteState();
    }
  }

  Future<void> _clearHistory() async {
    await SearchHistoryService.instance.clearHistory();
    await _loadSavedData();
  }

  String _formatHistoryTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inHours < 1) return '${diff.inMinutes} 分鐘前';
    if (diff.inDays < 1) return '${diff.inHours} 小時前';
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('台鐵時刻表')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStationCard(),
          const SizedBox(height: 16),
          _buildTimeCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _canQuery ? _onQuery : null,
                  child: const Text('查詢時刻表'),
                ),
              ),
              const SizedBox(width: 12),
              _buildFavoriteButton(),
            ],
          ),
          if (_favorites.isNotEmpty) ...[
            const SizedBox(height: 28),
            _buildFavoritesSection(),
          ],
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StationField(
                  label: '起站', station: _origin, onTap: _pickOrigin),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
              onPressed: _swapStations,
              tooltip: '交換起訖站',
            ),
            Expanded(
              child: _StationField(
                label: '迄站',
                station: _destination,
                onTap: _pickDestination,
                alignRight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.schedule, color: AppColors.primary),
        title: const Text('出發時間'),
        subtitle: Text(
          _formatTimeOfDay(_startTime),
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        trailing: const Text('查詢至當日 23:59',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        onTap: _pickDepartureTime,
      ),
    );
  }

  Widget _buildFavoriteButton() {
    final color = _canQuery ? AppColors.error : AppColors.textDisabled;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(
          _isCurrentFavorite ? Icons.favorite : Icons.favorite_border,
          color: color,
        ),
        onPressed: _canQuery ? _toggleFavorite : null,
        tooltip: _isCurrentFavorite ? '取消常用' : '加入常用路線',
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('常用路線',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _favorites
              .map<Widget>((f) => GestureDetector(
                onLongPress: () => _showFavoriteOptions(f),
                child: ActionChip(
                  label: Text(f.displayLabel),
                  avatar: const Icon(Icons.favorite, size: 16, color: AppColors.error),
                  backgroundColor: AppColors.surfaceVariant,
                  onPressed: () => _applyRecord(f),
                ),
              ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('最近查詢',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(onPressed: _clearHistory, child: const Text('清除')),
          ],
        ),
        const SizedBox(height: 4),
        Card(
          child: Column(
            children: _history
                .map((h) => ListTile(
                      leading: const Icon(Icons.history,
                          size: 20, color: AppColors.textSecondary),
                      title: Text('${h.originName} → ${h.destinationName}'),
                      subtitle: Text(_formatHistoryTime(h.createdAt),
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.north_east,
                          size: 18, color: AppColors.textSecondary),
                      onTap: () => _applyRecord(h),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StationField extends StatelessWidget {
  final String label;
  final TraStation? station;
  final VoidCallback onTap;
  final bool alignRight;

  const _StationField({
    required this.label,
    required this.station,
    required this.onTap,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              station?.name ?? '請選擇',
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: station == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
