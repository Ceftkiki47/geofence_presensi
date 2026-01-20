import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        backgroundColor: const Color(0xFF0FA3D1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 80, color: Color(0xFF0FA3D1)),
            const SizedBox(height: 20),
            const Text(
              'Memiliki pertanyaan terkait aplikasi ini?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FA3D1),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur kirim pertanyaan dikembangkan')),
                );
              },
              child: const Text('Kirim Pertanyaan'),
            ),
          ],
        ),
      ),
    );
  }
}
