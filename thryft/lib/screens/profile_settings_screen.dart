import 'package:flutter/material.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), // Added AppDrawer in case of mobile view
      body: SingleChildScrollView(
        child: Column(
          children: const [
            Header(),
            SizedBox(height: 400), // Empty space holding the page structure
            Footer(),
          ],
        ),
      ),
    );
  }
}
