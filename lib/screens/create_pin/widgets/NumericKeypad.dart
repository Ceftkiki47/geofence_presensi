import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onDelete;

  const NumericKeypad({
    super.key,
    required this.onKeyTap,
    required this.onDelete,
  });

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () => onKeyTap(value),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: [
          ...List.generate(9, (i) => _buildKey('${i + 1}')),
          const SizedBox(),
          _buildKey('0'),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.backspace_outlined),
          ),
        ],
      ),
    );
  }
}
