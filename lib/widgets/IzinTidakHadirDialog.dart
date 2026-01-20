import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geofence_presensi/providers/AuthProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('id'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal izin wajib dipilih')),
      );
      return;
    }

    final provider = context.read<AttendanceProvider>();

    final success = await provider.submitIzin(
      type: IzinType.tidakHadir,
      alasan: _alasanController.text.trim(),
      email: widget.userEmail,
      nama: context.read<AuthProvider>().userName!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin tidak hadir berhasil dikirim')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin tidak hadir gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Izin Tidak Hadir',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Pilih tanggal'
                        : DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(_selectedDate!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ALASAN
              const Text('Alasan Tidak Hadir'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _alasanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Sakit, izin keluarga, dll',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Alasan wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// DOKUMENTASI (placeholder)
              Text(
                'Dokumentasi (opsional)',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  // NANTI: image picker
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Dokumen'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Kirim Izin'),
        ),
      ],
    );
  }
}
