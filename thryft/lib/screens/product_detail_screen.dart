import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']!),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [          Hero(
            tag: 'product_image_${product['name']}',
            child: Container(
              height: 300,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name']!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      product['price']!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "This is a vintage item in great condition. "
                  "Fetch a real item description from backend later in the project.",
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: () {}, // Cart logic goes here later
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color.fromARGB(255, 71, 164, 245),
              ),
              child: const Text("Add to Cart"),
            ),
          )
        ],
      ),
    );
  }
}