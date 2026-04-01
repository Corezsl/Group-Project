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
          DropdownMenuItem(value: '8', child: Text('8')),
          DropdownMenuItem(value: '10', child: Text('10')),
          DropdownMenuItem(value: '12', child: Text('12')),
          DropdownMenuItem(value: '14', child: Text('14')),
          DropdownMenuItem(value: '16', child: Text('16')),
          DropdownMenuItem(value: '18', child: Text('18')),
          DropdownMenuItem(value: '20', child: Text('20')),
        ];

      case 'Mens':
        return const [
          DropdownMenuItem(value: 'All', child: Text('All')),
          DropdownMenuItem(value: '28R', child: Text('28R')),
          DropdownMenuItem(value: '30R', child: Text('30R')),
          DropdownMenuItem(value: '32R', child: Text('32R')),
          DropdownMenuItem(value: '34R', child: Text('34R')),
          DropdownMenuItem(value: '36R', child: Text('36R')),
          DropdownMenuItem(value: '38R', child: Text('38R')),
          DropdownMenuItem(value: '40R', child: Text('40R')),
          DropdownMenuItem(value: '42R', child: Text('42R')),
          DropdownMenuItem(value: '44R', child: Text('44R')),
          DropdownMenuItem(value: '46R', child: Text('46R')),
          DropdownMenuItem(value: '48R', child: Text('48R')),
          DropdownMenuItem(value: '50R', child: Text('50R')),          
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
              if (!_sizeOptions().any((items) => items.value == _size)) {
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