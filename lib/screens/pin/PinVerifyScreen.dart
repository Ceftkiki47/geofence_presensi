// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/AuthProvider.dart';

// class PinVerifyScreen extends StatefulWidget {
//   const PinVerifyScreen({super.key});

//   @override
//   State<PinVerifyScreen> createState() => _PinVerifyScreenState();
// }

// class _PinVerifyScreenState extends State<PinVerifyScreen> {
//   final _pinController = TextEditingController();

//   bool _isLoading = false;
//   String? _error;
//   int _attempt = 0;

//   static const int maxAttempt = 3;

//   Future<void> _verifyPin() async {
//     final pin = _pinController.text.trim();

//     // VALIDASI FORMAT
//     if (pin.length != 6 || int.tryParse(pin) == null) {
//       setState(() => _error = 'PIN harus 6 digit angka');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     final auth = context.read<AuthProvider>();
//     final success = await context.read<AuthProvider>().verifyPin(pin);

//     setState(() => _isLoading = false);

//     if (!success) {
//       // ❌ TIDAK navigasi manual
//       // AppGate akan otomatis redirect ke Home
//       setState(() 
//       => _error = 'PIN salah' 
//       );
//     }

//     _attempt++;
//     _pinController.clear();

//     if (_attempt >= maxAttempt) {
//       setState(() {
//         _error = 'Terlalu banyak percobaan. Silakan login ulang.';
//       });
//       await auth.logout();
//     } else {
//       setState(() {
//         _error = 'PIN salah. Sisa ${maxAttempt - _attempt} percobaan';
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _pinController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     if (auth.pinVerified) {
//       return const SizedBox.shrink();
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verifikasi PIN'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Masukkan PIN',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'PIN digunakan untuk keamanan dan absensi.',
//               style: TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 32),

//             TextField(
//               controller: _pinController,
//               keyboardType: TextInputType.number,
//               obscureText: true,
//               maxLength: 6,
//               decoration: const InputDecoration(
//                 labelText: 'PIN',
//                 border: OutlineInputBorder(),
//               ),
//             ),

//             if (_error != null) ...[
//               const SizedBox(height: 12),
//               Text(
//                 _error!,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ],

//             const Spacer(),

//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _verifyPin,
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('VERIFIKASI'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
