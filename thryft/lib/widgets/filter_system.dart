import 'package:flutter/material.dart';
import 'package:thryft/utils/size_options.dart';
import 'package:thryft/providers/search_provider.dart'; // new import
import 'package:thryft/screens/filter_results_screen.dart'; // added import

// Horizontally scrolling row of filter dropdowns shown under the search bar
// in the Header when the filter button is toggled. Pressing Apply navigates
// to the FilterResultsScreen with the assembled SearchFilters.
class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key, this.onApply});
  // optional callback fired with the assembled filters when Apply is pressed
  final ValueChanged<SearchFilters>? onApply; // changed type

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // currently selected value for each dropdown — 'All' means no filter
  String _department = 'All';
  String _size = 'All';
  String _brands = 'All';
  String _condition = 'All';
  String _fitting = 'All';
  String _material = 'All';
  String _colour = 'All';

  // user-typed max price (numeric, parsed on Apply)
  final TextEditingController _priceController = TextEditingController();
  // controls the horizontal scroll so the always-visible scrollbar lines up
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _priceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 72,
      color: Colors.white24,
      alignment: Alignment.topCenter,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        thickness: 10,
        radius: const Radius.circular(8),
        scrollbarOrientation: ScrollbarOrientation.top,
        child: Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('Department:', style: TextStyle(color: Colors.white)),
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
                      // changing department resets size if the previous size isn't
                      // valid for the new department (e.g. UK 8 makes no sense for Mens)
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
                      items: getSizeOptions(department: _department).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _size = v ?? 'All'),
                    ),

                    const Text('Brand:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _brands,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: (['All', ...brands]).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (z) => setState(() => _brands = z ?? 'All'),
                    ),

                    const Text('Condition:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _condition,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: (['All', ...conditions]).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (y) => setState(() => _condition = y ?? 'All'),
                    ),

                    const Text('Fitting:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _fitting,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: (['All', ...fittings]).map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (x) => setState(() => _fitting = x ?? 'All'),
                    ),

                    // numeric "max price" field — parsed on Apply, blank means no cap
                    const Text('Price:', style: TextStyle(color: Colors.white)),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter Max £',
                          hintStyle: TextStyle(color: Colors.white70),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    const Text('Material:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _material,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: (['All', ...materials]).map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (materials) => setState(() => _material = materials ?? 'All'),
                    ),

                    const Text('Color:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _colour,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: (['All', ...colours]).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (color) => setState(() => _colour = color ?? 'All'),
                    ),

                    // builds the SearchFilters object, fires the optional callback,
                    // then pushes the FilterResultsScreen
                    TextButton(
                      onPressed: () {
                        final maxPrice = _priceController.text.trim().isEmpty
                            ? null
                            : double.tryParse(_priceController.text.trim());
                        final filters = SearchFilters(
                          // 'All' is just our UI sentinel — the model expects null for "no filter"
                          department: _department == 'All' ? null : _department,
                          size: _size == 'All' ? null : _size,
                          brand: _brands == 'All' ? null : _brands,
                          condition: _condition == 'All' ? null : _condition,
                          fitting: _fitting == 'All' ? null : _fitting,
                          material: _material == 'All' ? null : _material,
                          colour: _colour == 'All' ? null : _colour,
                          minPrice: null,
                          maxPrice: maxPrice,
                          sortBy: 'newest',
                        );
                        widget.onApply?.call(filters);

                        // navigate to the filter results screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FilterResultsScreen(filters: filters),
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),

                    // resets every dropdown back to 'All' and dismisses the keyboard
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _department = 'All';
                          _size = 'All';
                          _brands = 'All';
                          _condition = 'All';
                          _fitting = 'All';
                          _priceController.clear();
                          _material = 'All';
                          _colour = 'All';
                        });
                        FocusScope.of(context).unfocus();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}