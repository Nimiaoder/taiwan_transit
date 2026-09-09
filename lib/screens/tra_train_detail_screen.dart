import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';
import '../widgets/stop_time_tile.dart';

/// =====================================================================
/// 車次詳細資料畫面
/// =====================================================================
/// 列出該車次沿途所有停靠站與到站/發車時間，並標示：
/// - 使用者選擇的起站 / 迄站（不同顏色與標籤）
/// - 列車目前所在（或即將抵達）的車站位置（依即時動態 TrainLiveBoard 判斷）
class TraTrainDetailScreen extends StatefulWidget {
  final String trainNo;
  final String trainDate;
  final TraStation origin;
  final TraStation destination;

  const TraTrainDetailScreen({
    super.key,
    required this.trainNo,
    required this.trainDate,
    required this.origin,
    required this.destination,
  });

  @override
  State<TraTrainDetailScreen> createState() => _TraTrainDetailScreenState();
}

class _TraTrainDetailScreenState extends State<TraTrainDetailScreen> {
  final _service = TraService.instance;

  bool _loading = true;
  String? _error;

  TraTrainTimetableDetail? _detail;
  TraLiveBoard? _liveBoard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.getTrainStopTimes(
        trainNo: widget.trainNo,
        trainDate: widget.trainDate,
      );
      final liveBoards = await _service.getAllLiveBoards();
      setState(() {
        _detail = detail;
        _liveBoard = liveBoards[widget.trainNo];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = TraService.friendlyMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('車次 ${widget.trainNo}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
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

  Widget _buildBody() {
    final detail = _detail;
    if (detail == null || detail.stopTimes.isEmpty) {
      return const Center(child: Text('查無此車次的停靠站資料', style: TextStyle(color: AppColors.textSecondary)));
    }

    final stops = detail.stopTimes;
    final currentStationId = _liveBoard?.stationId;
    final currentIndex = currentStationId == null
        ? -1
        : stops.indexWhere((s) => s.stationId == currentStationId);

    return Column(
      children: [
        _buildHeader(detail),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return StopTimeTile(
                stop: stop,
                isFirst: index == 0,
                isLast: index == stops.length - 1,
                isOrigin: stop.stationId == widget.origin.stationId,
                isDestination: stop.stationId == widget.destination.stationId,
                isCurrent: currentIndex >= 0 && index == currentIndex,
                isPast: currentIndex >= 0 && index < currentIndex,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(TraTrainTimetableDetail detail) {
    final info = detail.trainInfo;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              info.trainTypeName.isEmpty ? '車種未知' : info.trainTypeName,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${info.startingStationName} → ${info.endingStationName}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_liveBoard != null)
            Text(
              _liveBoard!.isDelayed ? '誤點 ${_liveBoard!.delayTime} 分' : '準點',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _liveBoard!.isDelayed ? AppColors.warning : AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
