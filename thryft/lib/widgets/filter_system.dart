import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  final ValueChanged<Map<String, String>>? onApply;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _department = 'All';
  String _size = 'Any';

  @override
  Widget build(BuildContext context) => Container(
        height: 64, // increase if needed
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
            DropdownButton<String>(
              value: _size,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Any', child: Text('Any')),
                DropdownMenuItem(value: 'XS', child: Text('XS')),
                DropdownMenuItem(value: 'S', child: Text('S')),
                DropdownMenuItem(value: 'M', child: Text('M')),
                DropdownMenuItem(value: 'L', child: Text('L')),
                DropdownMenuItem(value: 'XL', child: Text('XL')),
              ],
              onChanged: (v) => setState(() => _size = v ?? 'Any'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => widget.onApply?.call({'department': _department, 'size': _size}),
              child: const Text('Apply'),
            ),
          ],
        ),
      );
}