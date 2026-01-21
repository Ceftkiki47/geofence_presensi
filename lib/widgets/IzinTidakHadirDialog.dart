import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geofence_presensi/providers/AuthProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/AttendanceProvider.dart';

class IzinTidakHadirDialog extends StatefulWidget {
  final String userEmail;

  const IzinTidakHadirDialog({
    super.key,
    required this.userEmail,
  });

  @override
  State<IzinTidakHadirDialog> createState() => _IzinTidakHadirDialogState();
}

class _IzinTidakHadirDialogState extends State<IzinTidakHadirDialog> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  DateTime? _selectedDate;
  File? _dokumentasi;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  /// =======================
  /// PICK DATE
  /// =======================
  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }


  /// =======================
  /// PICK DOCUMENT
  /// =======================
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() => _dokumentasi = File(result.path));
    }
  }

  /// =======================
  /// SUBMIT
  /// =======================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showSnack('Tanggal izin wajib dipilih');
      return;
    }

    final provider = context.read<AttendanceProvider>();

    /// VALIDASI IZIN GANDA
    if (provider.isIzinTidakHadirToday(widget.userEmail)) {
      _showSnack('Anda sudah mengajukan izin hari ini');
      return;
    }

    final success = await provider.submitIzin(
      type: IzinType.tidakHadir,
      alasan: _alasanController.text.trim(),
      email: widget.userEmail,
      nama: context.read<AuthProvider>().userName!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      _showSnack('Izin tidak hadir berhasil dikirim');
    } else {
      _showSnack('Izin tidak hadir gagal');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Izin Tidak Hadir',
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
              /// TANGGAL
              const Text('Tanggal Tidak Hadir'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Pilih tanggal'
                        : DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ALASAN
              const Text('Keterangan / Alasan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _alasanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Sakit, izin keluarga',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Alasan wajib diisi'
                        : null,
              ),

              const SizedBox(height: 16),

              /// DOKUMENTASI
              const Text('Dokumentasi (Opsional)'),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file, color: Colors.blue),
                label: Text(
                  _dokumentasi == null
                      ? 'Upload Dokumen'
                      : 'Dokumen Dipilih',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text('Kirim Izin'),
        ),
      ],
    );
  }
}
