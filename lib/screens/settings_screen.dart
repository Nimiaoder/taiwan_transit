import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/theme/app_theme.dart';

/// =====================================================================
/// 設定頁面
/// =====================================================================
/// 目前僅顯示應用程式版本，之後再擴充其他設定項目。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '關於',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('版本'),
              trailing: Text(
                _version.isEmpty ? '載入中…' : 'v$_version ($_buildNumber)',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '台灣大眾運輸時刻表整合 App',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
