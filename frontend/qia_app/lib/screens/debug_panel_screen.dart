import 'package:flutter/material.dart';
import '../services/recovery_manager.dart';
import '../utils/logger.dart';
import '../widgets/log_viewer.dart';
import '../widgets/system_metrics.dart';
import 'dart:async';

class DebugPanelScreen extends StatefulWidget {
  const DebugPanelScreen({Key? key}) : super(key: key);

  @override
  _DebugPanelScreenState createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends State<DebugPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final RecoveryManager _recoveryManager = RecoveryManager();
  bool _deepLoggingEnabled = false;
  bool _aiDebugMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startMetricsRefresh();
  }

  void _startMetricsRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'System Logs'),
            Tab(text: 'Recovery Status'),
            Tab(text: 'AI Debug'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _recoveryManager.resetAllMetrics();
              setState(() {});
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsTab(),
          _buildRecoveryTab(),
          _buildAIDebugTab(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        _buildDebugControls(),
        const Expanded(child: LogViewer()),
      ],
    );
  }

  Widget _buildDebugControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Switch(
            value: _deepLoggingEnabled,
            onChanged: (value) {
              setState(() {
                _deepLoggingEnabled = value;
                Logger.setDeepLogging(value);
              });
            },
          ),
          const Text('Deep Logging'),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              final success = await _exportLogs();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs exported successfully')),
                );
              }
            },
            child: const Text('Export Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SystemMetrics(),
        const SizedBox(height: 16),
        _buildRecoveryMetrics(),
        const SizedBox(height: 16),
        _buildManualRecoveryControls(),
      ],
    );
  }

  Widget _buildRecoveryMetrics() {
    // Implementation for recovery metrics display
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recovery Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Add recovery metrics here
          ],
        ),
      ),
    );
  }

  Widget _buildManualRecoveryControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Recovery Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _triggerManualRecovery(RecoveryStrategy.reset),
                  child: const Text('Reset Services'),
                ),
                ElevatedButton(
                  onPressed: () => _triggerManualRecovery(RecoveryStrategy.selfHeal),
                  child: const Text('Self Heal'),
                ),
                // Add more recovery controls
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIDebugTab() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('AI Debug Mode'),
          subtitle: const Text('Show detailed AI processing information'),
          value: _aiDebugMode,
          onChanged: (value) {
            setState(() {
              _aiDebugMode = value;
              // Implement AI debug mode toggle
            });
          },
        ),
        // Add AI debug information
      ],
    );
  }

  Future<bool> _exportLogs() async {
    try {
      // Implement log export
      return true;
    } catch (e) {
      Logger.error('Failed to export logs', error: e);
      return false;
    }
  }

  Future<void> _triggerManualRecovery(RecoveryStrategy strategy) async {
    try {
      // Implement manual recovery
      setState(() {});
    } catch (e) {
      Logger.error('Manual recovery failed', error: e);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
} 