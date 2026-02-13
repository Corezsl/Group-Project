import 'package:flutter/widgets.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build (BuildContext context) {

    return Container(
      height: 100,
      color: const Color.fromARGB(255, 71, 164, 245),
      child: const Center(
        child: Text(
          'Placeholder for header',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}