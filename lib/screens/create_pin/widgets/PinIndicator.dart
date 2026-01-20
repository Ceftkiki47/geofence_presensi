import 'package:flutter/material.dart';

class PinIndicator extends StatelessWidget {
  final int length;

  const PinIndicator({super.key, required this.length});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? Colors.blue : Colors.transparent,
            border: Border.all(color: Colors.blue),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
