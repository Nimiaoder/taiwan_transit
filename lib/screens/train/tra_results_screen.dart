import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/tdx_config.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_top_bar.dart';
import '../../core/train/train_category.dart';
import '../../models/train/tra_models.dart';
import '../../services/train/tra_service.dart';
import '../../widgets/train/timetable_list_tile.dart';
import 'tra_train_detail_screen.dart';

/// =====================================================================
/// 台鐵時刻表查詢結果清單
/// =====================================================================
/// - 上方用頁籤區分「全部」「區間」「對號座」（預設為「全部」）
/// - 顯示「起站 -> 迄站」在查詢日期、出發時間到當日 23:59 的所有班次
/// - 開啟畫面後自動捲動到使用者輸入的起始時間附近
/// - 已經發車（早於目前時間）的班次整列反灰、標註「已過站」
/// - 定時刷新即時動態（誤點資訊），每一筆都會顯示準點/誤點/尚未發車狀態
class TraResultsScreen extends StatefulWidget {
  final TraStation origin;
  final TraStation destination;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const TraResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<TraResultsScreen> createState() => _TraResultsScreenState();
}

class _TraResultsScreenState extends State<TraResultsScreen>
    with SingleTickerProviderStateMixin {
  static const double _itemHeight = 108;

  final _service = TraService.instance;
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];
  late final TabController _tabController;

  bool _loading = true;
  String? _error;

  List<TraTimetableEntry> _allEntries = [];
  Map<String, TraLiveBoard> _liveBoards = {};

  Timer? _liveBoardTimer;

  late final String _trainDate; // yyyy-MM-dd

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStartTime());
        }
      });
    _trainDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _load();
    _liveBoardTimer = Timer.periodic(
      const Duration(seconds: TdxConfig.liveBoardRefreshSeconds),
      (_) => _refreshLiveBoards(),
    );
  }

  @override
  void dispose() {
    _liveBoardTimer?.cancel();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _service.getOdTimetable(
        originStationId: widget.origin.stationId,
        destinationStationId: widget.destination.stationId,
        trainDate: _trainDate,
      );
      entries.sort((a, b) => _timeToMinutes(a.originStopTime.departureTime)
          .compareTo(_timeToMinutes(b.originStopTime.departureTime)));

      setState(() {
        _allEntries = entries;
        _loading = false;
      });

      await _refreshLiveBoards();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStartTime());
    } catch (e) {
      setState(() {
        _error = TraService.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _refreshLiveBoards() async {
    final boards = await _service.getAllLiveBoards();
    if (mounted) setState(() => _liveBoards = boards);
  }

  /// 依「時間範圍」過濾（車種頁籤由 build() 時另外套用）
  List<TraTimetableEntry> get _timeFilteredEntries {
    final startMin = widget.startTime.hour * 60 + widget.startTime.minute;
    final endMin = widget.endTime.hour * 60 + widget.endTime.minute;
    return _allEntries.where((e) {
      final depMin = _timeToMinutes(e.originStopTime.departureTime);
      return depMin >= startMin && depMin <= endMin;
    }).toList();
  }

  /// 依目前頁籤過濾：0=全部, 1=區間, 2=對號座
  List<TraTimetableEntry> _entriesForTab(int tabIndex) {
    final timeFiltered = _timeFilteredEntries;
    if (tabIndex == 0) return timeFiltered;
    return timeFiltered.where((e) {
      final category = TrainCategoryUtil.categorize(e.trainInfo.trainTypeName);
      final isLocal = TrainCategoryUtil.isLocalGroup(category);
      return tabIndex == 1 ? isLocal : !isLocal;
    }).toList();
  }

  static int _timeToMinutes(String raw) {
    if (raw.length < 5) return 0;
    final h = int.tryParse(raw.substring(0, 2)) ?? 0;
    final m = int.tryParse(raw.substring(3, 5)) ?? 0;
    return h * 60 + m;
  }

  bool _isPast(TraTimetableEntry entry) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return _timeToMinutes(entry.originStopTime.departureTime) < nowMin;
  }

  void _scrollToStartTime() {
    final tabIndex = _tabController.index;
    final controller = _scrollControllers[tabIndex];
    final entries = _entriesForTab(tabIndex);
    if (entries.isEmpty || !controller.hasClients) return;
    final startMin = widget.startTime.hour * 60 + widget.startTime.minute;
    int targetIndex = entries.indexWhere(
      (e) => _timeToMinutes(e.originStopTime.departureTime) >= startMin,
    );
    if (targetIndex < 0) targetIndex = entries.length - 1;
    final maxExtent = controller.position.maxScrollExtent;
    final offset =
        (targetIndex * _itemHeight).clamp(0.0, maxExtent < 0 ? 0.0 : maxExtent);
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _openDetail(TraTimetableEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TraTrainDetailScreen(
          trainNo: entry.trainInfo.trainNo,
          trainDate: _trainDate,
          origin: widget.origin,
          destination: widget.destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 共用標題列（藍色漸層 + 右上角設定按鈕），車種頁籤掛在標題列下方
      appBar: AppTopBar(
        title: '${widget.origin.name} → ${widget.destination.name}',
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: TrainCategoryUtil.groupAll),
                  Tab(text: TrainCategoryUtil.groupLocal),
                  Tab(text: TrainCategoryUtil.groupExpress),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_entriesForTab(0), _scrollControllers[0]),
                    _buildList(_entriesForTab(1), _scrollControllers[1]),
                    _buildList(_entriesForTab(2), _scrollControllers[2]),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('重試')),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<TraTimetableEntry> entries, ScrollController controller) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('這個時間範圍內沒有符合條件的班次',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SizedBox(
            height: _itemHeight - 8,
            child: TimetableListTile(
              entry: entry,
              liveBoard: _liveBoards[entry.trainInfo.trainNo],
              isPast: _isPast(entry),
              onTap: () => _openDetail(entry),
            ),
          );
        },
      ),
    );
  }
}
