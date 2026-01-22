import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/AttendanceProvider.dart';
import '../../providers/AuthProvider.dart';
import '../../widgets/izin/IzinTidakHadirDialog.dart';
import '../../widgets/izin/izinHadirSiangDialog.dart';

class IzinTelatDialog extends StatefulWidget {
  const IzinTelatDialog({super.key});

  @override
  State<IzinTelatDialog> createState() => _IzinTelatDialogState();
}

class _IzinTelatDialogState extends State<IzinTelatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();

  File? _dokumentasi;
  bool _submitting = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  /// =======================
  /// PICK DOCUMENT (CAMERA)
  /// =======================
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      preferredCameraDevice: CameraDevice.front,
    );

    if (result != null) {
      setState(() {
        _dokumentasi = File(result.path);
      });
    }
  }

  /// =======================
  /// SUBMIT TELAT
  /// =======================
  Future<void> _submitTelat() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dokumentasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumentasi wajib diambil melalui kamera'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final attendance = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    final success = await attendance.submitAttendance(
      image: File('dummy'), // fingerprint sudah diproses sebelumnya
      email: auth.userEmail!,
      nama: auth.userName!,
      keteranganTelat: _keteranganController.text.trim(),
      dokumentasiTelat: _dokumentasi,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi berhasil dengan status: TELAT'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim absensi telat')),
      );
    }
  }

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Anda Terlambat',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan isi keterangan keterlambatan '
              'dan ambil dokumentasi melalui kamera.',
            ),
            const SizedBox(height: 12),

            /// =======================
            /// FORM
            /// =======================
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _keteranganController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Telat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Keterangan wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  /// =======================
                  /// DOKUMENTASI CAMERA
                  /// =======================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dokumentasi (Kamera)',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 6),

                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _dokumentasi == null
                          ? 'Ambil Foto'
                          : 'Foto Berhasil Diambil',
                    ),
                  ),

                  /// =======================
                  /// PREVIEW FOTO (RASIO FIX)
                  /// =======================
                  if (_dokumentasi != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 3 / 4, // ✅ RASIO KAMERA PORTRAIT
                        child: Image.file(
                          _dokumentasi!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            /// =======================
            /// IZIN LAIN
            /// =======================
            const Text(
              'Atau pilih jenis izin lain:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.red),
              title: const Text('Izin Tidak Hadir'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => IzinTidakHadirDialog(
                    userEmail: context.read<AuthProvider>().userEmail!,
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text('Hadir Masuk Siang'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => const HadirSiangDialog(),
                );
              },
            ),
          ],
        ),
      ),

      /// =======================
      /// ACTIONS
      /// =======================
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: (_submitting || _dokumentasi == null)
              ? null
              : _submitTelat,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kirim Telat'),
        ),
      ],
    );
  }
}
