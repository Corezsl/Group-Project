/// Returns an error message string if the listing form inputs are invalid,
/// or null if all inputs are valid.
String? validateListingForm({
  required String title,
  required String price,
  required String? condition,
  required String? brand,
  required String? department,
  required String? category,
  required String? size,
  required bool isNewListing,
  required bool hasImage,
}) {
  if (title.isEmpty ||
      condition == null ||
      brand == null ||
      department == null ||
      price.isEmpty ||
      (isNewListing && !hasImage)) {
    return 'Please fill all required fields.';
  }

  if (category != 'Accessories' && size == null) {
    return 'Please select a size.';
  }

  final double? parsedPrice = double.tryParse(price);
  if (parsedPrice == null || parsedPrice <= 0 || parsedPrice > 10000) {
    return 'Please enter a valid price greater than 0 or less than 10000.';
  }

  return null;
}
