import 'package:flutter/material.dart';

class LogFilter extends StatelessWidget {
  final Set<String> selectedLevels;
  final Function(Set<String>) onFilterChanged;
  final Function(String) onSearchChanged;

  const LogFilter({
    Key? key,
    required this.selectedLevels,
    required this.onFilterChanged,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search logs...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('ERROR'),
              selected: selectedLevels.contains('ERROR'),
              onSelected: (selected) => _toggleLevel('ERROR', selected),
              backgroundColor: Colors.red.withOpacity(0.2),
              selectedColor: Colors.red.withOpacity(0.4),
            ),
            FilterChip(
              label: const Text('WARNING'),
              selected: selectedLevels.contains('WARNING'),
              onSelected: (selected) => _toggleLevel('WARNING', selected),
              backgroundColor: Colors.orange.withOpacity(0.2),
              selectedColor: Colors.orange.withOpacity(0.4),
            ),
            FilterChip(
              label: const Text('INFO'),
              selected: selectedLevels.contains('INFO'),
              onSelected: (selected) => _toggleLevel('INFO', selected),
              backgroundColor: Colors.blue.withOpacity(0.2),
              selectedColor: Colors.blue.withOpacity(0.4),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleLevel(String level, bool selected) {
    final newLevels = Set<String>.from(selectedLevels);
    if (selected) {
      newLevels.add(level);
    } else {
      newLevels.remove(level);
    }
    onFilterChanged(newLevels);
  }
} 