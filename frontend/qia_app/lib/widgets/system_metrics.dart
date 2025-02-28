import 'package:flutter/material.dart';
import '../services/recovery_manager.dart';
import 'package:provider/provider.dart';

class SystemMetrics extends StatelessWidget {
  const SystemMetrics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'WebSocket',
              'Connected',
              Colors.green,
            ),
            _buildMetricRow(
              'AI Service',
              'Active',
              Colors.green,
            ),
            _buildMetricRow(
              'Voice Recognition',
              'Ready',
              Colors.green,
            ),
            const Divider(),
            const Text(
              'Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPerformanceMetric(
              'Response Time',
              '120ms',
              0.4,
            ),
            _buildPerformanceMetric(
              'Memory Usage',
              '45%',
              0.45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
      ],
    );
  }
} 