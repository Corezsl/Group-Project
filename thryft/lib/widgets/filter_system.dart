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

  // New: controller for the price input
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Makes the filter panel horizontally scrollable for future controls addition.
    // Each control wrapped with padding to keep spacing when scrolling.
    return Container(
      // reduced vertical padding and fixed height so contents sit exactly in the middle
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 56, // adjust between 48-72 to taste
      color: Colors.white24,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: const Text('Department:', style: TextStyle(color: Colors.white)),
              ),
              DropdownButton<String>(
                value: _department,
                isDense: true,
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

              const Text('Size:', style: TextStyle(color: Colors.white)),
              DropdownButton<String>(
                value: _size,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: sizeOptionsForDepartment(_department).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _size = v ?? 'All'),
              ),

              const Text('Brand:', style: TextStyle(color: Colors.white)),
              DropdownButton<String>(
                value: _brands,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: (['All', ...brandOptions]).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (z) => setState(() => _brands = z ?? 'All'),
              ),

              const Text('Condition:', style: TextStyle(color: Colors.white)),
              DropdownButton<String>(
                value: _condition,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: (['All', ..._conditionOptions]).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (y) => setState(() => _condition = y ?? 'All'),
              ),

              const Text('Fitting:', style: TextStyle(color: Colors.white)),
              DropdownButton<String>(
                value: _fitting,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Slim', child: Text('Slim')),
                  DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'Loose', child: Text('Loose')),
                ],
                onChanged: (x) => setState(() => _fitting = x ?? 'All'),
              ),

                            // New Price input
              const Text('Price:', style: TextStyle(color: Colors.white)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter Max price',
                    hintStyle: TextStyle(color: Colors.white70),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                  ),
                  onChanged: (_) => setState(() {}), // keep UI reactive if needed
                ),
              ),

              TextButton(
                onPressed: () => widget.onApply?.call({
                  'department': _department,
                  'size': _size,
                  'brand': _brands,
                  'price': _priceController.text.trim(), // include price
                  'condition': _condition,
                  'fitting': _fitting,
                }),
                child: const Text('Apply'),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _department = 'All';
                    _size = 'All';
                    _brands = 'All';
                    _condition = 'All';
                    _fitting = 'All';
                    _priceController.clear(); // clear price input
                  });
                  // close any open dropdowns so UI immediately reflects reset
                  FocusScope.of(context).unfocus();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}