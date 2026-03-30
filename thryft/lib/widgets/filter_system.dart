import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key, this.onApply});
  final VoidCallback? onApply;
  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white24,
        child: Row(
          children: [
            const Expanded(child: Text('Filters', style: TextStyle(color: Colors.white))),
            TextButton(onPressed: onApply, child: const Text('Apply')),
          ],
        ),
      );
}