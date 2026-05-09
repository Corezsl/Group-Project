import 'package:flutter_test/flutter_test.dart';


String? _filterValidation({
  String? size,
  double? minPrice, //set as 0.1 in validation (need to double check)
  double? maxPrice, //set as 10000 in validation rules (need to check aswell)
  String? department,
}) {
  // This is base logic for all cases or where department is null
  if (size != null && !['XS', 'S', 'M', 'L', 'XL', 'XXL'].contains(size)) {
    return 'Invalid size';
  }
  if (minPrice != null && minPrice < 0) {
    return 'Min price cannot be negative';
  }
  if (maxPrice != null && maxPrice < 0) {
    return 'Max price cannot be negative';
  }
  if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
    return 'Min price cannot be greater than max price'; //dont think i need this?
  }
  if (department != null && !['Menswear', 'Womenswear'].contains(department)) {
    return 'Invalid department';
  }
  if (department == 'Womenswear' && size != null && !['6', '8', '10', '12', '14', '16', '18', '20', '22'].contains(size)) {
    return 'Invalid size for womenswear';
  }
  if (department == 'Menswear' && size != null && !['30R', '32R', '34R', '36R', '38R', '40R', '42R', '44R', '46R', '48R', '50R'].contains(size)) {
    return 'Invalid size for menswear';
  }
  // Add more validation rules as needed.
  
  return null; // null means valid
}


void main() {

}