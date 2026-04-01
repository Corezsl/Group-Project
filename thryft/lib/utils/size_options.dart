List<String> sizeOptionsForDepartment(String? department) {
  switch (department) {
    case 'Womens':
      return ['All', '6', '8', '10', '12','14','16','18','20'];
    case 'Mens':
      return ['All', '28R', '30R', '32R', '34R','36R','38R','40R','42R','44R','46R','48R','50R'];
    default:
      return ['All', 'XS', 'S', 'M', 'L', 'XL','XXL','XXXL'];
  }
}