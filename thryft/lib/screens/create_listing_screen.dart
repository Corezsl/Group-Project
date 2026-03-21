import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  int _selectedIndex = 0;
  String? _selectedCategory;
  String? _selectedSize;
  String? _selectedCondition;
  String? _selectedBrand;
  final TextEditingController _priceController = TextEditingController();

  final List<String> _brands = [
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

  final List<String> _categories = [
    'Shirt',
    'Pants',
    'Dresses',
    'Shorts',
    'Shoes',
    'Accessories',
  ];

  List<String> get _currentSizes {
    switch (_selectedCategory) {
      case 'Shoes':
        return List.generate(19, (i) => (i + 30).toString());
      case 'Accessories':
        return ["Woman's One Size", "Man's One Size", 'Unisex One Size'];
      default:
        return ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
    }
  }

  final List<String> _conditions = [
    'New with tags',
    'New without tags',
    'Very good',
    'Good',
    'Okay',
    'Worn',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Widget _buildMainPreview() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 71, 164, 245),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedIndex == 0
                ? 'Click to upload main photo'
                : 'Click to upload photo ${_selectedIndex + 1}',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          if (_selectedIndex == 0) ...[
            const SizedBox(height: 6),
            Text(
              'Required',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(int index) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 71, 164, 245)
                : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              index == 0
                  ? Icons.star_outline
                  : Icons.add_photo_alternate_outlined,
              size: 22,
              color: isSelected
                  ? const Color.fromARGB(255, 71, 164, 245)
                  : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              index == 0 ? 'Main' : 'Photo ${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color.fromARGB(255, 71, 164, 245)
                    : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Photo section (shared between layouts) ─────────────────────────────

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Add a main photo (required) and up to 4 additional photos.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildMainPreview(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) => _buildThumbnail(i)),
        ),
      ],
    );
  }

  // ─── Form fields section (shared between layouts) ───────────────────────

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: const Text('Select a category'),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
              // Reset size when category changes
              _selectedSize = null;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        if (_selectedCategory != 'Accessories') ...[
          const SizedBox(height: 20),
          const Text('Size', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedSize,
            hint: const Text('Select a size'),
            items: _currentSizes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => _selectedSize = val),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCondition,
          hint: const Text('Select a condition'),
          items: _conditions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCondition = val),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedBrand,
          hint: const Text('Select a brand'),
          items: _brands
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (val) => setState(() => _selectedBrand = val),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Price', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '£ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const SizedBox(height: 32),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a Listing',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mobile: stacked, Desktop: side-by-side
                      if (isMobile) ...[
                        _buildPhotoSection(),
                        const SizedBox(height: 24),
                        _buildFormSection(),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 400, child: _buildPhotoSection()),
                            const SizedBox(width: 40),
                            Expanded(child: _buildFormSection()),
                          ],
                        ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            // TO DO: validate and submit listing
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Upload Listing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
