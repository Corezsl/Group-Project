import 'package:flutter/material.dart';
//import 'package:flutter/widgets.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build (BuildContext context) {

    return Container(
      height: 100,
      color: const Color.fromARGB(255, 71, 164, 245),
      child: const Center(
        child: Row(
          children:[
            Spacer(),
            Text(
              'Placeholder for header',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon (Icons.person_outline,
                color: Colors.white
                ),
                onPressed: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}