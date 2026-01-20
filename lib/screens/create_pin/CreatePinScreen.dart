import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/AuthProvider.dart';
import '../../screens/create_pin/widgets/NumericKeypad.dart';
import '../../screens/create_pin/widgets/PinIndicator.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onKeyTap(String value) {
    if (_pin.length >= 6) return;

    setState(() {
      _pin += value;
    });

    if (_pin.length == 6) {
      _submitPin();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    final auth = context.read<AuthProvider>();

    await auth.createPin(_pin);

    // Tidak perlu navigate manual
    // AppGate akan otomatis redirect
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.lock_outline,
              size: 72,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            const Text(
              'Buat PIN Keamanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Masukkan 6 digit PIN',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            PinIndicator(length: _pin.length),

            const Spacer(),

            NumericKeypad(
              onKeyTap: _onKeyTap,
              onDelete: _onDelete,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
