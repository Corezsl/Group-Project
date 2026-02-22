import 'package:flutter/material.dart';
import 'package:thryft/router.dart';

void main() {
  runApp(const ThryftApp());
}

class ThryftApp extends StatelessWidget {
  const ThryftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Thryft',
      theme: ThemeData(
        useMaterial3: true,
        // Primary colour theme
        primaryColor: const Color.fromARGB(255, 71, 164, 245),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 71, 164, 245),
          primary: const Color.fromARGB(255, 71, 164, 245),
        ),
      ),
      routerConfig: router,
    );
  }
}
