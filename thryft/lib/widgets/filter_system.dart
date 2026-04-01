import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  final ValueChanged<Map<String, String>>? onApply;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _department = 'All';
  String _size = 'All';

  List<DropdownMenuItem<String>> _sizeOptions() {
    switch (_department) {
      case 'Womens':
        return const [
          DropdownMenuItem(value: 'All', child: Text('All')),
          DropdownMenuItem(value: '6', child: Text('6')),
        ];

      case 'Mens':
        return const [
          DropdownMenuItem(value: 'All', child: Text('All')),
          DropdownMenuItem(value: '28R', child: Text('28R')),
        ]; 

      default:
        return const [
          DropdownMenuItem(value: 'All', child: Text('All')),
          DropdownMenuItem(value: 'XS', child: Text('XS')),
          DropdownMenuItem(value: 'S', child: Text('S')),
          DropdownMenuItem(value: 'M', child: Text('M')),
          DropdownMenuItem(value: 'L', child: Text('L')),
          DropdownMenuItem(value: 'XL', child: Text('XL')),
        ];
    }
  }
 
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
                   // reset size if it's not available for the selected department
                   if (!_sizeOptions().any((it) => it.value == _size)) {
                     _size = 'Any';
                   }
                 }),
           ),
           const SizedBox(width: 16),
           const Text('Size:', style: TextStyle(color: Colors.white)),
           const SizedBox(width: 8),
           DropdownButton<String>(
             value: _size,
             underline: const SizedBox.shrink(),
             items: _sizeOptions(),
             onChanged: (v) => setState(() => _size = v ?? 'Any'),
           ),
           const SizedBox(width: 12),
           TextButton(
             onPressed: () => widget.onApply?.call({'department': _department, 'size': _size}),
             child: const Text('Apply'),
           ),
           const SizedBox(width: 8),
           TextButton(
             onPressed: () => setState(() {
               _department = 'All';
               _size = 'Any';
             }),
             child: const Text('Clear'),
           ),
         ],
       ),
     );
   }
}