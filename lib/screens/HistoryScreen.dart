import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/AuthProvider.dart';
import '../services/GoogleSheetService.dart';
import 'ProfileScreen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool showHadir = true;

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<AuthProvider>().userEmail;

    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0FA3D1),
              Color(0xFF8FD3F4),
              Color(0xFFDFF6FD),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              'Riwayat Kehadiran',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _toggle(),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FutureBuilder<List<AttendanceRow>>(
                  future: GoogleSheetService.fetchAttendanceByEmail(userEmail),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Belum ada data'),
                      );
                    }

                    final filtered = snapshot.data!.where((e) {
                      if (showHadir) {
                        return e.status != 'alpha';
                      } else {
                        return e.status == 'alpha';
                      }
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Belum ada data'),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _historyCard(filtered[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// TOGGLE
  /// =======================
  Widget _toggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _toggleBtn(
            'Hadir',
            showHadir,
            () => setState(() => showHadir = true),
          ),
          _toggleBtn(
            'Alpha',
            !showHadir,
            () => setState(() => showHadir = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6EE7F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// =======================
  /// CARD
  /// =======================
  Widget _historyCard(AttendanceRow item) {
    final date = DateTime.parse(item.tanggal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(date),
        ),
        subtitle: Text(
          _statusLabel(item.status),
          style: const TextStyle(
            color: Color(0xFF0FA3D1),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          item.status == 'alpha'
              ? Icons.cancel
              : Icons.check_circle,
          color: item.status == 'alpha'
              ? Colors.red
              : Colors.green,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir Tepat Waktu';
      case 'telat':
        return 'Hadir Terlambat';
      case 'hadir_siang':
        return 'Hadir Siang';
      case 'alpha':
        return 'Alpha';
      default:
        return status;
    }
  }
}
