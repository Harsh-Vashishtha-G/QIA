import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class LogEntryCard extends StatelessWidget {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;
  final String? stackTrace;

  const LogEntryCard({
    Key? key,
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  }) : super(key: key);

  Color _getLevelColor() {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getLevelColor().withOpacity(0.2),
          child: Icon(
            _getLevelIcon(),
            color: _getLevelColor(),
          ),
        ),
        title: Text(message),
        subtitle: Text(
          timeago.format(timestamp),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  if (stackTrace != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Stack Trace:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        stackTrace!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getLevelIcon() {
    switch (level) {
      case 'ERROR':
        return Icons.error_outline;
      case 'WARNING':
        return Icons.warning_amber_outlined;
      case 'INFO':
        return Icons.info_outline;
      default:
        return Icons.circle_outlined;
    }
  }
} 