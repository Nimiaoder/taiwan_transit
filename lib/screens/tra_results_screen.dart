import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/tdx_config.dart';
import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';
import '../widgets/timetable_list_tile.dart';
import 'tra_train_detail_screen.dart';

/// =====================================================================
/// 台鐵時刻表查詢結果清單
/// =====================================================================
/// - 顯示「起站 -> 迄站」在查詢日期的所有班次（依選定車種過濾）
/// - 開啟畫面後自動捲動到使用者輸入的起始時間附近
/// - 已經發車（早於目前時間）的班次整列反灰、標註「已過站」
/// - 定時刷新即時動態（誤點資訊）
class TraResultsScreen extends StatefulWidget {
  final TraStation origin;
  final TraStation destination;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Set<String> selectedTrainTypeIds;

  const TraResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.startTime,
    required this.endTime,
    required this.selectedTrainTypeIds,
  });

  @override
  State<TraResultsScreen> createState() => _TraResultsScreenState();
}

class _TraResultsScreenState extends State<TraResultsScreen> {
  static const double _itemHeight = 100; // TimetableListTile 的預估高度（含間距）

  final _service = TraService.instance;
  final _scrollController = ScrollController();

  bool _loading = true;
  String? _error;

  List<TraTimetableEntry> _allEntries = [];
  List<TraTimetableEntry> _filteredEntries = [];
  Map<String, TraLiveBoard> _liveBoards = {};

  Timer? _liveBoardTimer;

  late final String _trainDate; // yyyy-MM-dd

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
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
      entries.sort((a, b) =>
          _timeToMinutes(a.originStopTime.departureTime).compareTo(_timeToMinutes(b.originStopTime.departureTime)));

      setState(() {
        _allEntries = entries;
        _filteredEntries = _applyFilter(entries);
        _loading = false;
      });

      await _refreshLiveBoards();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStartTime());
    } catch (e) {
      setState(() {
        _error = '查詢失敗：$e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshLiveBoards() async {
    final boards = await _service.getAllLiveBoards();
    if (mounted) setState(() => _liveBoards = boards);
  }

  List<TraTimetableEntry> _applyFilter(List<TraTimetableEntry> entries) {
    final startMin = widget.startTime.hour * 60 + widget.startTime.minute;
    final endMin = widget.endTime.hour * 60 + widget.endTime.minute;
    return entries.where((e) {
      final typeOk = widget.selectedTrainTypeIds.isEmpty ||
          widget.selectedTrainTypeIds.contains(e.trainInfo.trainTypeId);
      final depMin = _timeToMinutes(e.originStopTime.departureTime);
      final timeOk = depMin >= startMin && depMin <= endMin;
      return typeOk && timeOk;
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
    if (_filteredEntries.isEmpty || !_scrollController.hasClients) return;
    final startMin = widget.startTime.hour * 60 + widget.startTime.minute;
    int targetIndex = _filteredEntries.indexWhere(
      (e) => _timeToMinutes(e.originStopTime.departureTime) >= startMin,
    );
    if (targetIndex < 0) targetIndex = _filteredEntries.length - 1;
    final offset = (targetIndex * _itemHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
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
      appBar: AppBar(
        title: Text('${widget.origin.name} → ${widget.destination.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildList(),
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

  Widget _buildList() {
    if (_filteredEntries.isEmpty) {
      return const Center(
        child: Text('這個時間範圍內沒有符合條件的班次', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEntries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = _filteredEntries[index];
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
