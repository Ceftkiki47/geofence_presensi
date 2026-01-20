import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'CameraAbsensiScreen.dart';
import '../providers/AttendanceProvider.dart';
import '../providers/AuthProvider.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verifikasi PIN Absensi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0FA3D1),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              enabled: !_processing,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '••••••',
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _processing ? null : _submitPinFlow,
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verifikasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPinFlow() async {
    final attendance = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    if (auth.userEmail == null || auth.userName == null) {
      _snack('User tidak valid', Colors.red);
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      _snack('PIN harus 6 digit', Colors.orange);
      return;
    }

    setState(() => _processing = true);

    /// 1️⃣ VERIFIKASI PIN
    final pinValid = await auth.verifyPin(pin);
    if (!pinValid) {
      _snack('PIN salah', Colors.red);
      _stop();
      return;
    }

    /// 2️⃣ CEK ULANG AKSES (ANTI BYPASS)
    final access =
        await attendance.prepareAbsensi(auth.userEmail!);

    if (access != AttendanceAccessStatus.allowed) {
      _snack(_mapAccessError(access), Colors.red);
      _stop();
      return;
    }

    /// 3️⃣ BUKA KAMERA
    final File? image = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraAbsensiScreen()),
    );

    if (image == null || !image.existsSync()) {
      _snack('Foto dibatalkan', Colors.orange);
      _stop();
      return;
    }

    /// 4️⃣ SUBMIT ABSENSI
    final success = await attendance.submitAttendance(
      image: image,
      email: auth.userEmail!,
      nama: auth.userName!,
    );

    if (!success) {
      _snack('Absensi gagal', Colors.red);
      _stop();
      return;
    }

    _snack('Absensi berhasil', Colors.green);

    if (mounted) Navigator.pop(context);
  }

  void _stop() {
    setState(() => _processing = false);
  }

  String _mapAccessError(AttendanceAccessStatus status) {
    switch (status) {
      case AttendanceAccessStatus.alreadySubmitted:
        return 'Anda sudah absen hari ini';
      case AttendanceAccessStatus.izinLocked:
        return 'Anda sudah mengajukan izin';
      case AttendanceAccessStatus.outsideZone:
        return 'Anda di luar area absensi';
      case AttendanceAccessStatus.locationNotReady:
        return 'Lokasi belum siap';
      case AttendanceAccessStatus.alpha:
        return 'Waktu absensi telah berakhir';
      default:
        return 'Akses ditolak';
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}
