import 'package:flutter/material.dart';
import 'package:thryft/utils/size_options.dart';

const List<String> brandOptions = [
    'Nike',
    'Adidas',
    'Puma',
    'Reebok',
    'Under Armour',
    'New Balance',
    'Asics',
    'Vans',
    'Converse',
    'Jordan',
    'Fila',
    'Skechers',
    'Brooks',
    'Saucony',
    'Mizuno',
    'Hoka One One',
    'Salomon',
    'Merrell',
    'Columbia',
    'The North Face',
    'Patagonia',
    'Other',
  ];

  const List<String> _conditionOptions = [
    'New with tags',
    'New without tags',
    'Very good',
    'Good',
    'Okay',
    'Worn',
  ];

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  final ValueChanged<Map<String, String>>? onApply;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  String _department = 'All';
  String _size = 'All';
  String _brands = 'All';
  String _condition = 'All';
  String _fitting = 'All';

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
          const SizedBox(width: 16),
          const Text('Brand:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _brands,
            underline: const SizedBox.shrink(),
            items: (['All', ...brandOptions]).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (z) => setState(() => _brands = z ?? 'All'),
          ),
          const SizedBox(width: 16),
          const Text('Condition:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _condition,
            items: (['All', ..._conditionOptions]).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (y) => setState(() => _condition = y ?? 'All')
            ),
          const SizedBox(width: 16),
          const Text('Fitting:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _fitting,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Slim', child: Text('Slim')),
              DropdownMenuItem(value: 'Regular', child: Text('Regular')),
              DropdownMenuItem(value: 'Loose', child: Text('Loose')),
            ],
            onChanged: (x) => setState(() => _fitting = x ?? 'All')
            ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => widget.onApply?.call({'department': _department, 'size': _size, 'brand': _brands, 'condition': _condition, 'fitting': _fitting}),
            child: const Text('Apply'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _department = 'All';
                _size = 'All';
                _brands = 'All';
                _condition = 'All';
                _fitting = 'All';
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