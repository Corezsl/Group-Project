import 'package:flutter/material.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: const [
            Header(),
            Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            SizedBox(
              height: 500,
            ), 
            Footer(),
          ],
        ),
      ),
    );
  }
}
