import 'package:flutter/material.dart';
import 'dart:convert';
import '../utils/logger.dart';
import '../widgets/log_filter.dart';
import '../widgets/log_entry_card.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  _LogViewerScreenState createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<Map<String, dynamic>> _logs = [];
  Set<String> _selectedLevels = {'ERROR', 'WARNING', 'INFO'};
  String _searchQuery = '';
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    // Refresh logs every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await Logger.getLogs();
      setState(() {
        _logs = logs
            .map((log) => json.decode(log) as Map<String, dynamic>)
            .where((log) => _selectedLevels.contains(log['level']))
            .where((log) => _searchQuery.isEmpty ||
                log['message'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading logs: $e');
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await Logger.clearLogs();
      _loadLogs();
    }
  }

  void _updateFilter(Set<String> levels) {
    setState(() {
      _selectedLevels = levels;
    });
    _loadLogs();
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LogFilter(
              selectedLevels: _selectedLevels,
              onFilterChanged: _updateFilter,
              onSearchChanged: _updateSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No logs found'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return LogEntryCard(
                            timestamp: DateTime.parse(log['timestamp']),
                            level: log['level'],
                            message: log['message'],
                            error: log['error'],
                            stackTrace: log['stackTrace'],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
} 