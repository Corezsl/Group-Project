import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'icon': Icons.checkroom, 'label': 'Clothing'},
    {'icon': Icons.laptop, 'label': 'Tech'},
    {'icon': Icons.chair, 'label': 'Home'},
    {'icon': Icons.sports_basketball, 'label': 'Sports'},
    {'icon': Icons.menu_book, 'label': 'Books'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color.fromARGB(255, 71, 164, 245),
                child: Icon(
                  categories[index]['icon'],
                  color: const Color.fromARGB(255, 71, 164, 245),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                categories[index]['label'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      ),
    );
  }
}