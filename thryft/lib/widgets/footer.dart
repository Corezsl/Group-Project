import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[50],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          final horizontalPadding = isMobile ? 16.0 : 80.0;
          
          // Responsive: single column on mobile, row on desktop
          if (isMobile) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
              ),
            );
          }
          },
        ),
      );
    }
  }