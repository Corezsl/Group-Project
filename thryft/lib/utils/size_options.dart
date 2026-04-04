List<String> sizeOptionsForDepartment(String? department) {
  final base = ['All', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  final womens = ['6', '8', '10', '12', '14', '16', '18', '20'];
  final mens = ['28R', '30R', '32R', '34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'];

  switch (department) {
    case 'Womens':
      return [...base, ...womens];
    case 'Mens':
      return [...base, ...mens];
    default:
      return [...base];
  }
}