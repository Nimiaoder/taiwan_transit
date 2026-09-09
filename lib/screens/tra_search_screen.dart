import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';
import '../widgets/region_station_picker_sheet.dart';
import '../widgets/wheel_time_picker.dart';
import 'tra_results_screen.dart';

/// =====================================================================
/// 台鐵時刻表查詢畫面
/// =====================================================================
/// 使用者在這裡選擇：起站、迄站（先選地區、再選車站）、
/// 查詢時間範圍（滾輪、24 小時制），按下查詢後導向 [TraResultsScreen]。
///
/// 車種篩選已經移到結果頁用頁籤呈現，這裡不再需要選車種。
class TraSearchScreen extends StatefulWidget {
  const TraSearchScreen({super.key});

  @override
  State<TraSearchScreen> createState() => _TraSearchScreenState();
}

class _TraSearchScreenState extends State<TraSearchScreen> {
  final _service = TraService.instance;

  bool _loading = true;
  String? _loadError;

  List<TraStation> _stations = [];

  TraStation? _origin;
  TraStation? _destination;

  late TimeOfDay _startTime;
  TimeOfDay _currentEndTime = const TimeOfDay(hour: 23, minute: 59);

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final stations = await _service.getStations();
      setState(() {
        _stations = stations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = '資料載入失敗：$e';
        _loading = false;
      });
    }
  }

  Future<void> _pickOrigin() async {
    final result = await showRegionStationPickerSheet(
      context: context,
      stations: _stations,
      title: '選擇起站',
    );
    if (result != null) setState(() => _origin = result);
  }

  Future<void> _pickDestination() async {
    final result = await showRegionStationPickerSheet(
      context: context,
      stations: _stations,
      title: '選擇迄站',
    );
    if (result != null) setState(() => _destination = result);
  }

  void _swapStations() {
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
  }

  Future<void> _pickTimeRange() async {
    await showTimeRangePickerSheet(
      context: context,
      initialStart: _startTime,
      initialEnd: _currentEndTime,
      onConfirm: (start, end) {
        setState(() {
          _startTime = start;
          _currentEndTime = end;
        });
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _canQuery =>
      _origin != null && _destination != null && _origin!.stationId != _destination!.stationId;

  void _onQuery() {
    if (!_canQuery) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TraResultsScreen(
          origin: _origin!,
          destination: _destination!,
          startTime: _startTime,
          endTime: _currentEndTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('台鐵時刻表')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : _buildForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重試')),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 起訖站選擇區（先選地區、再選車站）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StationField(
                  label: '起站',
                  station: _origin,
                  onTap: _pickOrigin,
                ),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                    onPressed: _swapStations,
                    tooltip: '交換起訖站',
                  ),
                ),
                _StationField(
                  label: '迄站',
                  station: _destination,
                  onTap: _pickDestination,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 時間範圍選擇區
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.schedule, color: AppColors.primary),
            title: const Text('查詢時間範圍'),
            subtitle: Text(
              '${_formatTimeOfDay(_startTime)} ~ ${_formatTimeOfDay(_currentEndTime)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTimeRange,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _canQuery ? _onQuery : null,
          child: const Text('查詢時刻表'),
        ),
      ],
    );
  }
}

class _StationField extends StatelessWidget {
  final String label;
  final TraStation? station;
  final VoidCallback onTap;

  const _StationField({required this.label, required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                station?.name ?? '請選擇車站',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: station == null ? AppColors.textDisabled : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
