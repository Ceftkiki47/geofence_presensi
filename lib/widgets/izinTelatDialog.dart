import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/AttendanceProvider.dart';
import '../providers/AuthProvider.dart';

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
  /// PICK DOCUMENT
  /// =======================
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _dokumentasi = File(result.path);
      });
    }
  }

  /// =======================
  /// SUBMIT TELAT
  /// =======================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final attendanceProvider = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    final success = await attendanceProvider.submitAttendance(
      image: File('dummy'), // kamera sudah diproses sebelumnya
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
          content: Text(
            'Anda sudah melakukan absensi dengan status: TELAT\n'
            'Mohon jangan diulangi kembali!',
          ),
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
      backgroundColor: Colors.white,
      title: const Text(
        'Anda Terlambat',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silakan isi keterangan keterlambatan Anda.',
              ),
              const SizedBox(height: 12),

              /// KETERANGAN
              TextFormField(
                controller: _keteranganController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Telat',
                  hintText: 'Contoh: Ban bocor, hujan deras',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Keterangan wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// DOKUMENTASI
              Text(
                'Dokumentasi (Opsional)',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file, color: Colors.blue),
                label: Text(
                  _dokumentasi == null
                      ? 'Upload Dokumentasi'
                      : 'Dokumentasi Dipilih',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }
}
