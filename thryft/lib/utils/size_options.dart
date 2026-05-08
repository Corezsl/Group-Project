/// Central source of dropdown / filter option lists used across the app.
/// Imported by `create_listing_screen.dart`, `filter_system.dart`,
/// and `standard_product_grid.dart` to populate dropdowns and filters.

/// Returns clothing size options based on [department].
/// Mens gets waist sizes (28R–50R), Womens gets UK dress sizes (6–20)
/// but both include the shared base sizes (XS–XXXL).
List<String> sizeOptionsForDepartment(String? department) {
  final base = const ['All', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final womens = const ['6', '8', '10', '12', '14', '16', '18', '20'];
  final mens = const ['28R', '30R', '32R', '34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'];

  switch (department) {
    case 'Womens':
      return [...base, ...womens];
    case 'Mens':
      return [...base, ...mens];
    default:
      return [...base];
  }
}

/// Supported brand names shown in the Create Listing brand dropdown.
const List<String> brands = [
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

/// Item condition choices for the Create Listing form, ordered best to worst.
const List<String> conditions = [
  'New with tags',
  'New without tags',
  'Very good',
  'Good',
  'Okay',
  'Worn',
];

/// Fabric / material options for the Create Listing form.
const List<String> materials = [
  'Cotton',
  'Polyester',
  'Wool',
  'Silk',
  'Denim',
  'Leather',
  'Linen',
  'Rayon',
  'Nylon',
  'Acrylic',
  'Other',
];

/// Colour options for the Create Listing form and filter system.
const List<String> colours = [
  'Black',
  'White',
  'Red',
  'Blue',
  'Green',
  'Yellow',
  'Purple',
  'Pink',
  'Brown',
  'Grey',
  'Orange',
  'Other',
];

/// Fit/silhouette options for the Create Listing form.
const List<String> fittings = ['Slim', 'Regular', 'Loose'];

/// Top-level clothing categories. 'Accessories' is special — it skips
/// the size dropdown (see [validateListingForm] and [getSizeOptions]).
const List<String> categories = [
  'Shirt',
  'Trousers',
  'Dresses',
  'Shorts',
  'Shoes',
  'Accessories',
];

/// Sort options for the price filter in the product grid.
const List<String> priceSortOptions = [
  'Lowest Price First',
  'Highest Price First',
];

/// Sort options for the date filter in the product grid.
const List<String> dateSortOptions = [
  'Newest First',
  'Oldest First',
];

/// Returns the correct size list depending on [category] and [department].
/// Shoes get numeric EU sizes (30–48), Accessories get one-size options,
List<String> getSizeOptions({String? department, String? category}) {
  if (category == 'Shoes') {
    return List.generate(19, (i) => (i + 30).toString());
  }
  if (category == 'Accessories') {
    return ["Woman's One Size", "Man's One Size", 'Unisex One Size'];
  }
  return sizeOptionsForDepartment(department);
}