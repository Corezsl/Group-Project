import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build (BuildContext context) {

    return Container(
      height: 100,
      color: const Color.fromARGB(255, 71, 164, 245),
      child: Center(
        child: Row(
          children:[
            Image.asset(
              'assets/images/thyrft_logo.png',
              height: 24,
              fit: BoxFit.cover,
            ),
            Spacer(),
            SizedBox(
              width: 500,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Color.fromARGB(50, 255, 255, 255),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Spacer(),
            
            FilledButton.tonal(
              onPressed: null,
              style: FilledButton.styleFrom(
                textStyle: TextStyle(fontSize: 16.0),
              ),
              child: Text('SELL NOW'),
            ),
            Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon (Icons.favorite_outline,
                  color: Colors.white
                ),
                onPressed: null,
                ),
                IconButton(
                  icon: Icon (Icons.shopping_cart_outlined,
                  color: Colors.white
                ),
                onPressed: null,
                ),
                IconButton(
                icon: Icon (Icons.person_outline,
                color: Colors.white
                ),
                onPressed: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}