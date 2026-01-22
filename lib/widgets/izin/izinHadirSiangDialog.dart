import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/AttendanceProvider.dart';
import '../../providers/AuthProvider.dart';

class HadirSiangDialog extends StatefulWidget {
  const HadirSiangDialog({super.key});

  @override
  State<HadirSiangDialog> createState() => _HadirSiangDialogState();
}

class _HadirSiangDialogState extends State<HadirSiangDialog> {
  final TextEditingController _alasanCtrl = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();

    if (_alasanCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan wajib diisi')),
      );
      return;
    }

    if (auth.userEmail == null || auth.userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data user tidak valid')),
      );
      return;
    }

    final success = await attendance.submitHadirSiang(
      email: auth.userEmail!,
      nama: auth.userName!,
      alasan: _alasanCtrl.text,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal submit hadir siang')),
      );
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda berhasil absensi HADIR SIANG'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hadir Siang'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _alasanCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Center(
                        child: Text('Ambil Dokumentasi (Opsional)'),
                      )
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
