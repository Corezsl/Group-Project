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

// public canonical lists for reuse across the app
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

const List<String> conditions = [
  'New with tags',
  'New without tags',
  'Very good',
  'Good',
  'Okay',
  'Worn',
];

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

const List<String> fittings = ['Slim', 'Regular', 'Loose'];

const List<String> categories = [
  'Shirt',
  'Trousers',
  'Dresses',
  'Shorts',
  'Shoes',
  'Accessories',
];

// helper that mirrors previous _currentSizes logic but is stateless and reusable
List<String> getSizeOptions({String? department, String? category}) {
  if (category == 'Shoes') {
    return List.generate(19, (i) => (i + 30).toString());
  }
  if (category == 'Accessories') {
    return ["Woman's One Size", "Man's One Size", 'Unisex One Size'];
  }
  return sizeOptionsForDepartment(department);
}