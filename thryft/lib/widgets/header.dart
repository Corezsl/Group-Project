import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: const Color.fromARGB(255, 71, 164, 245),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Image.asset(
                        'assets/images/thyrft_logo.png',
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Color.fromARGB(50, 255, 255, 255),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.tonal(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          textStyle: TextStyle(fontSize: 16.0),
                        ),
                        child: Text('SELL NOW'),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.favorite_outline,
                              color: Colors.white,
                            ),
                            onPressed: null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                            ),
                            onPressed: null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.person_outline,
                              color: Colors.white,
                            ),
                            onPressed: () => context.push('/account'),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.go('/'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text('Home'),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: Text('Shirts', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: Text(
                    'Trousers',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: Text('Shoes', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: Text(
                    'Accessories',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: null,
                  child: Text(
                    'About Us',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
