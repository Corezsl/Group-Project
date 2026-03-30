import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  final ValueChanged<String>? onApply;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _department = 'All';

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white24,
        child: Row(
          children: [
            const Expanded(child: Text('Filters', style: TextStyle(color: Colors.white))),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _department,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Womens', child: Text('Womens')),
                DropdownMenuItem(value: 'Mens', child: Text('Mens')),
              ],
              onChanged: (v) => setState(() => _department = v ?? 'All'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {}, // do nothing regardless of selection
              child: const Text('Apply'),
            ),
          ],
        ),
      );
}