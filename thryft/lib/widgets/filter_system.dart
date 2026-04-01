import 'package:flutter/material.dart';
import 'package:thryft/utils/size_options.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  final ValueChanged<Map<String, String>>? onApply;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _department = 'All';
  String _size = 'All';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white24,
      child: Row(
        children: [
          const Text('Department:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _department,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Womens', child: Text('Womens')),
              DropdownMenuItem(value: 'Mens', child: Text('Mens')),
            ],
            onChanged: (v) => setState(() {
              _department = v ?? 'All';
              if (!sizeOptionsForDepartment(_department).contains(_size)) {
                _size = 'All';
              }
            }),
          ),
          const SizedBox(width: 16),
          const Text('Size:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _size,
            underline: const SizedBox.shrink(),
            items: sizeOptionsForDepartment(_department).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _size = v ?? 'All'),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => widget.onApply?.call({'department': _department, 'size': _size}),
            child: const Text('Apply'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _department = 'All';
                _size = 'All';
              });
              // close any open dropdowns so UI immediately reflects reset
              FocusScope.of(context).unfocus();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}