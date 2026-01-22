import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/AuthProvider.dart';
import '../providers/AttendanceProvider.dart';
import '../screens/ProfileScreen.dart';
import '../screens/PinEntryScreen.dart';
import '../widgets/izin/IzinTidakHadirDialog.dart';
import '../widgets/izin/izinTelatDialog.dart';
import '../widgets/task/TaskDialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHadir = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final now = DateTime.now();

    final email = auth.userEmail ?? '';
    final canAccessFingerprint = attendance.canAccessFingerprint(email);

    return Scaffold(
      body: Stack(
        children: [
          _mainUI(context, auth, attendance, now, canAccessFingerprint),
          _bottomInfoBar(context),
        ],
      ),
    );
  }

  /// =======================
  /// MAIN UI
  /// =======================
  Widget _mainUI(
    BuildContext context,
    AuthProvider auth,
    AttendanceProvider attendance,
    DateTime now,
    bool canAccessFingerprint,
  ) {
    return Container(
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
          const SizedBox(height: 60),

          /// HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Beranda',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: auth.profileImage != null
                        ? FileImage(File(auth.profileImage!))
                        : null,
                    child: auth.profileImage == null
                        ? const Icon(Icons.person, color: Color(0xFF0FA3D1))
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now),
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 8),

          Text(
            DateFormat('HH:mm').format(now),
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pilih Kehadiran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  /// TAB
                  _tabSwitcher(),

                  const Spacer(),

                  /// FINGERPRINT
                  GestureDetector(
                    onTap: canAccessFingerprint
                        ? () => _onFingerprintTap(context)
                        : null,
                    child: Opacity(
                      opacity: canAccessFingerprint ? 1 : 0.4,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6EE7F9),
                              Color(0xFF0FA3D1),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    canAccessFingerprint
                        ? 'Tekan untuk melanjutkan'
                        : 'Belum waktunya absensi',
                    style: const TextStyle(
                      color: Color(0xFF0FA3D1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskAfterCheckout(
  BuildContext context,
  File image,
) {
  final auth = context.read<AuthProvider>();
  final attendance = context.read<AttendanceProvider>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskBottomSheet(
      onSubmit: (tasks) async {
        await attendance.submitCheckout(
          image: image,
          email: auth.userEmail!,
          nama: auth.userName!,
          tasks: tasks,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absensi pulang berhasil')),
          );
        }
      },
    ),
  );
}


  /// =======================
  /// FINGERPRINT FLOW
  /// =======================
  Future<void> _onFingerprintTap(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();

    final email = auth.userEmail!;
    final nama = auth.userName!;

    final access = await attendance.prepareAbsensi(email);

    if (access == AttendanceAccessStatus.allowed) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PinEntryScreen(),
      );
    } else if (access == AttendanceAccessStatus.izinLocked) {
      showDialog(
        context: context,
        builder: (_) => const IzinTelatDialog(),
      );
    } else {
      _snack(context, access.name);
    }
  }

  /// =======================
  /// BOTTOM INFO
  /// =======================
  Widget _bottomInfoBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final status = attendance.todayStatus(auth.userEmail ?? '');

    String label;
    Color color;

    switch (status) {
      case DailyAttendanceStatus.hadir:
        label = 'Anda sudah HADIR';
        color = Colors.green;
        break;
      case DailyAttendanceStatus.telat:
        label = 'Anda TELAT';
        color = Colors.orange;
        break;
      case DailyAttendanceStatus.hadirSiang:
        label = 'HADIR SIANG';
        color = Colors.blue;
        break;
      case DailyAttendanceStatus.izinTidakHadir:
        label = 'IZIN';
        color = Colors.deepOrange;
        break;
      case DailyAttendanceStatus.alpha:
        label = 'ALPHA';
        color = Colors.red;
        break;
      case DailyAttendanceStatus.pulang:
      case DailyAttendanceStatus.lembur:
        label = 'ANDA SUDAH PULANG';
        color = Colors.teal;
        break;
      default:
        label = 'Belum absensi';
        color = Colors.grey;
    }

    return SafeArea(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        color: color.withOpacity(0.12),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// =======================
  /// UI UTIL
  /// =======================
  Widget _tabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tab('Hadir', isHadir, () => setState(() => isHadir = true)),
          _tab('Izin', !isHadir, () => setState(() => isHadir = false)),
        ],
      ),
    );
  }

  Widget _tab(String text, bool active, VoidCallback onTap) {
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

  void _snack(BuildContext c, String msg) {
    ScaffoldMessenger.of(c)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
