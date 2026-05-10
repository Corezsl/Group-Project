/// Validation utility for the Create Listing form (FR3).
///
/// This is a pure function (no UI or DB dependency) that checks all
/// user-supplied listing fields before they are sent to Supabase.
/// Used by [CreateListingRepository] and tested in
/// `test/fr3_create_listing/create_listing_repository_test.dart`.

/// Validates every field of the listing form and returns an error message
/// if something is wrong, or `null` when all inputs are valid.
///
/// Parameters come directly from the Create Listing screen's form state:


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
  String? description,
}) {
  // 1. Required-field check — title, condition, brand, department, and price
  //    must all be filled in. New listings also need at least one image.
  if (title.isEmpty ||
      condition == null ||
      brand == null ||
      department == null ||
      price.isEmpty ||
      (isNewListing && !hasImage)) {
    return 'Please fill all required fields.';
  }

  // 2. Size is required for all categories except 'Accessories',
  //    which don't have a meaningful size attribute.
  if (category != 'Accessories' && size == null) {
    return 'Please select a size.';
  }

  // 3. Price must be a valid number between 0 (exclusive) and 10 000.
  final double? parsedPrice = double.tryParse(price);
  if (parsedPrice == null || parsedPrice <= 0 || parsedPrice > 10000) {
    return 'Please enter a valid price greater than 0 or less than 10000.';
  }

  // 4. Description is optional but must not exceed 200 characters.
  if (description != null && description.length > 200) {
    return 'Description must be 200 characters or less.';
  }

  // All checks passed — the form data is safe to submit.
  return null;
}
