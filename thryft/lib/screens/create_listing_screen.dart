// Used for both creating a new listing and editing an existing one.
// Reached via /create-listing (new) or pushed with initialData (edit).
// Handles image picking, form validation, Supabase upload, and price-drop notifications.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/utils/responsive.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/app_drawer.dart';
import 'package:thryft/widgets/header.dart';
import 'package:thryft/utils/size_options.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/utils/listing_form_validator.dart';

import 'package:thryft/repositories/create_listing_repository.dart';

class CreateListingScreen extends StatefulWidget {
  // Null when creating a new listing; populated with the existing product data when editing.
  final Map<String, dynamic>? initialData;
  const CreateListingScreen({super.key, this.initialData});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  bool _isLoading =
      false; // disables the submit button while upload is in progress
  int _selectedIndex =
      0; // which thumbnail slot is currently shown in the main preview
  late final TextEditingController _titleController;
  String? _selectedCategory;
  String? _selectedSize;
  String? _selectedCondition;
  String? _selectedBrand;
  String? _selectedFitting;
  String? _selectedDepartment;
  String? _selectedMaterial;
  String? _selectedColour;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Pre-populate all fields when editing an existing listing.
    // Normalize incoming initialData to avoid type mismatches (int vs String)
    Map<String, dynamic>? data;
    if (widget.initialData != null) {
      data = Map<String, dynamic>.from(widget.initialData!);

      // Map common snake_case DB column names to camelCase keys if needed.
      if (data['image_url'] != null && data['imageUrl'] == null) {
        data['imageUrl'] = data['image_url'];
      }
      if (data['original_price'] != null && data['originalPrice'] == null) {
        data['originalPrice'] = data['original_price'];
      }
    }

    _titleController = TextEditingController(text: data?['name']?.toString());

    final priceVal = data?['price'];
    _priceController = TextEditingController(
      text: priceVal != null ? priceVal.toString() : '',
    );

    _descriptionController = TextEditingController(
      text: data?['description']?.toString(),
    );

    if (data != null) {
      _selectedCategory = data['category']?.toString();
      _selectedSize = data['size']?.toString();
      _selectedBrand = data['brand']?.toString();
      _selectedCondition = data['condition']?.toString();
      _selectedFitting = data['fitting']?.toString();
      _selectedMaterial = data['material']?.toString();
      _selectedColour = data['colour']?.toString();
      // Use normalized department so it matches dropdown items
      _selectedDepartment = _normalizeDepartment(
        data['department']?.toString(),
      );

      final existingMain = data['imageUrl']?.toString();
      if (existingMain != null && existingMain.trim().isNotEmpty) {
        _existingImageUrls[0] = existingMain.trim();
      }

      // Load any additional images (slots 2–5) from the existing listing.
      for (int i = 2; i <= 5; i++) {
        final existing = data['image_url_$i']?.toString();
        if (existing != null && existing.trim().isNotEmpty) {
          _existingImageUrls[i - 1] = existing.trim();
        }
      }
    }
  }

  // Maps raw department strings from the DB (e.g. "Womenswear", "all") to dropdown values.
  String? _normalizeDepartment(String? input) {
    if (input == null) return null;
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) return null;
    if (lower == 'all') return 'All';
    if (lower.contains('women')) return 'Womens';
    if (lower.contains('men')) return 'Mens';
    // Fallback: title-case the value so it more likely matches an item
    return input[0].toUpperCase() + input.substring(1);
  }

  final List<XFile?> _images = List.filled(
    5,
    null,
  ); // newly picked files, one per slot
  final List<String?> _existingImageUrls = List.filled(
    5,
    null,
  ); // old URLs shown in edit mode until replaced
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _images[index] = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _submit() async {
    final String? validationError = validateListingForm(
      title: _titleController.text,
      price: _priceController.text,
      condition: _selectedCondition,
      brand: _selectedBrand,
      department: _selectedDepartment,
      category: _selectedCategory,
      size: _selectedSize,
      isNewListing: widget.initialData == null,
      hasImage: _images[0] != null,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to modify a listing.');
      }

      final listingRepo = CreateListingRepository(supabase);

      // Block listing creation if the seller hasn't added a payment method yet.
      final hasPaymentMethod = await listingRepo.hasPaymentMethod(user.id);

      if (!hasPaymentMethod) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please add a payment method in your profile settings before creating a listing.',
              ),
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      String? publicImageUrl = widget.initialData?['imageUrl'];

      // Only upload a new main image if the user picked one; otherwise keep the existing URL.
      if (_images[0] != null) {
        publicImageUrl = await listingRepo.uploadImage(_images[0]!);
      }

      // Upload each additional slot only if a new file was picked; keep the old URL otherwise.
      final List<String?> secondaryImageUrls = List.filled(4, null);
      for (int i = 1; i <= 4; i++) {
        if (_images[i] != null) {
          secondaryImageUrls[i - 1] = await listingRepo.uploadImage(
            _images[i]!,
          );
        } else {
          secondaryImageUrls[i - 1] = _existingImageUrls[i];
        }
      }

      // Build the product map used for both insert and update.
      final double newPrice = double.parse(_priceController.text);
      final Map<String, dynamic> productData = {
        'name': _titleController.text,
        'price': newPrice,
        'size': _selectedSize ?? 'One Size',
        'department': _selectedDepartment,
        'brand': _selectedBrand,
        'condition': _selectedCondition,
        'image_url': publicImageUrl,
        'image_url_2': secondaryImageUrls[0],
        'image_url_3': secondaryImageUrls[1],
        'image_url_4': secondaryImageUrls[2],
        'image_url_5': secondaryImageUrls[3],
        'category': _selectedCategory,
        'fitting': _selectedFitting,
        'material': _selectedMaterial,
        'colour': _selectedColour,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      };

      if (widget.initialData != null) {
        // If price went down, store the old price so the UI can show a strikethrough.
        final double? oldPrice = double.tryParse(
          widget.initialData!['price']?.toString() ?? '',
        );

        await listingRepo.updateListing(
          listingId: widget.initialData!['id'].toString(),
          productData: productData,
          oldPrice: oldPrice,
          newPrice: newPrice,
          title: _titleController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated successfully!')),
        );
        context.pop(); // return to the previous screen after a successful edit
      } else {
        await listingRepo.createListing(productData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully!')),
        );

        _clearForm();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Resets all fields and images after a new listing is successfully created.
  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedSize = null;
      _selectedCondition = null;
      _selectedBrand = null;
      _selectedFitting = null;
      _selectedDepartment = null;
      _selectedMaterial = null;
      _selectedColour = null;
      _images.fillRange(0, 5, null);
      _existingImageUrls.fillRange(0, 5, null);
      _selectedIndex = 0;
    });
  }

  // Web uses Image.network with the file path; mobile uses Image.file directly.
  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  // Loads an existing image from Supabase storage; shows a broken-image icon on error.
  Widget _buildNetworkPreview(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[400],
            size: 40,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // Large image area — tapping opens the gallery picker for the selected slot.
  Widget _buildMainPreview() {
    final XFile? currentImage = _images[_selectedIndex];
    final String? existingUrl = _existingImageUrls[_selectedIndex];

    return GestureDetector(
      onTap: () => _pickImage(_selectedIndex),
      child: Container(
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
        clipBehavior: Clip.hardEdge,
        child: currentImage != null
            ? _buildImagePreview(currentImage)
            : (existingUrl != null && existingUrl.isNotEmpty)
            ? _buildNetworkPreview(existingUrl)
            : Column(
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
      ),
    );
  }

  // Small slot selector — highlighted in blue when active, shows star icon for slot 0 (main).
  Widget _buildThumbnail(int index) {
    final bool isSelected = index == _selectedIndex;
    final XFile? currentImage = _images[index];
    final String? existingUrl = _existingImageUrls[index];

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
        clipBehavior: Clip.hardEdge,
        child: currentImage != null
            ? _buildImagePreview(currentImage)
            : (existingUrl != null && existingUrl.isNotEmpty)
            ? _buildNetworkPreview(existingUrl)
            : Column(
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Combines the main preview and the row of 5 thumbnail selectors.
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

  // All the listing detail dropdowns and text inputs.
  // Size is hidden for Accessories since it doesn't apply.
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Vintage Nike Hoodie',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final safeCat =
                _selectedCategory != null &&
                    categories.contains(_selectedCategory)
                ? _selectedCategory
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeCat,
              hint: const Text('Select a category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _selectedSize = null;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            const deptItems = ['All', 'Womens', 'Mens'];
            final validDept =
                _selectedDepartment != null &&
                    deptItems.contains(_selectedDepartment)
                ? _selectedDepartment
                : null;

            return DropdownButtonFormField<String>(
              value: validDept,
              hint: const Text('Select a department'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Womens', child: Text('Womens')),
                DropdownMenuItem(value: 'Mens', child: Text('Mens')),
              ],
              onChanged: (val) => setState(() => _selectedDepartment = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        if (_selectedCategory != 'Accessories') ...[
          const SizedBox(height: 20),
          const Text('Size', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final current = getSizeOptions(
                department: _selectedDepartment,
                category: _selectedCategory,
              ).toList();
              final sizes = List<String>.from(current);
              if (_selectedSize != null && !sizes.contains(_selectedSize)) {
                sizes.insert(0, _selectedSize!);
              }
              final safeInitial =
                  _selectedSize != null && sizes.contains(_selectedSize)
                  ? _selectedSize
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: safeInitial,
                hint: const Text('Select a size'),
                items: sizes
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
              );
            },
          ),
        ],
        const SizedBox(height: 20),
        const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final safeCondition =
                _selectedCondition != null &&
                    conditions.contains(_selectedCondition)
                ? _selectedCondition
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeCondition,
              hint: const Text('Select a condition'),
              items: conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCondition = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final safeBrand =
                _selectedBrand != null && brands.contains(_selectedBrand)
                ? _selectedBrand
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeBrand,
              hint: const Text('Select a brand'),
              items: brands
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBrand = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Fitting (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final safeFitting =
                _selectedFitting != null && fittings.contains(_selectedFitting)
                ? _selectedFitting
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeFitting,
              hint: const Text('Select a fitting'),
              items: fittings
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFitting = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Material (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Builder(
          builder: (context) {
            // defensive copy / null-safety: ensure we always work with a List<String>
            final List<String> materialsList = materials;
            final safeMaterial =
                _selectedMaterial != null &&
                    materialsList.contains(_selectedMaterial)
                ? _selectedMaterial
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeMaterial,
              hint: const Text('Select a material'),
              items: materialsList
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedMaterial = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Colour (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Builder(
          builder: (context) {
            final List<String> coloursList = colours;
            final safeColour =
                _selectedColour != null && coloursList.contains(_selectedColour)
                ? _selectedColour
                : null;
            return DropdownButtonFormField<String>(
              initialValue: safeColour,
              hint: const Text('Select a colour'),
              items: coloursList
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedColour = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Description (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLength: 200,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter item description...',
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
                      Text(
                        widget.initialData != null
                            ? 'Edit Listing'
                            : 'Create a Listing',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Photos on the left, form on the right for desktop; stacked on mobile.
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
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.initialData != null
                                      ? 'Update Listing'
                                      : 'Upload Listing',
                                  style: const TextStyle(
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
