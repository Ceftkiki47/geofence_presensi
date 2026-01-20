import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/AuthProvider.dart';
import '../create_pin/widgets/PinIndicator.dart';
import '../create_pin/widgets/NumericKeypad.dart';

enum VerifyPinContext { auth, attendance }

class VerifyPinScreen extends StatefulWidget {
  final VerifyPinContext contextType;

  const VerifyPinScreen({
    super.key,
    required this.contextType,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  String _pin = '';
  int _attempt = 0;
  String? _error;

  void _onKeyTap(String value) {
    if (_pin.length >= 6) return;

    setState(() {
      _pin += value;
    });

    if (_pin.length == 6) {
      _verify();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyPin(_pin);

    if (success) {
      // AppGate akan handle redirect
      return;
    }

    setState(() {
      _attempt++;
      _pin = '';
      _error = 'PIN salah (${3 - _attempt} percobaan tersisa)';
    });

    if (_attempt >= 3) {
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.contextType == VerifyPinContext.auth
        ? 'Verifikasi PIN'
        : 'Masukkan PIN untuk Absensi';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.lock,
              size: 72,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 24),

            PinIndicator(length: _pin.length),

            TextButton(
              onPressed: () {
                // ke reset PIN
                // context.router.push(ReLoginRoute());
              },
              child: const Text('Lupa PIN?'),
            ),

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
