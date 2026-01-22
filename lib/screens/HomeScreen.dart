import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geofence_presensi/screens/ProfileScreen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/AttendanceProvider.dart';
import '../providers/AuthProvider.dart';
import '../widgets/IzinTidakHadirDialog.dart';
import '../widgets/izinTelatDialog.dart';
import 'PinEntryScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHadir = true;

  /// =======================
  /// LABEL IZIN
  /// =======================
  String izinLabel(IzinType type) {
    switch (type) {
      case IzinType.telat:
        return 'Telat Hadir';
      case IzinType.hadirSiang:
        return 'Hadir Siang';
      case IzinType.tidakHadir:
        return 'Tidak Hadir';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          _buildMainUI(context, now, auth),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomInfoBar(context),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// BOTTOM INFO
  /// =======================
  Widget _bottomInfoBar(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final auth = context.watch<AuthProvider>();

    final status = attendance.todayStatus(auth.userEmail ?? '');

    String label;
    Color color;

    switch (status) {
      case DailyAttendanceStatus.hadir:
        label = 'Anda sudah HADIR hari ini';
        color = Colors.green;
        break;
      case DailyAttendanceStatus.telat:
        label = 'Anda TELAT hari ini';
        color = Colors.orange;
        break;
      case DailyAttendanceStatus.hadirSiang:
        label = 'Anda HADIR SIANG hari ini';
        color = Colors.blue;
        break;
      case DailyAttendanceStatus.izinTidakHadir:
        label = 'Anda IZIN hari ini';
        color = Colors.deepOrange;
        break;
      case DailyAttendanceStatus.alpha:
        label = 'Status ALPHA hari ini';
        color = Colors.red;
        break;
      default:
        label = 'Belum melakukan absensi';
        color = Colors.grey;
    }

    return SafeArea(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        color: color.withOpacity(0.12),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// =======================
  /// MAIN UI
  /// =======================
  Widget _buildMainUI(
    BuildContext context,
    DateTime now,
    AuthProvider auth,
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
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF0FA3D1),
                          )
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// SWITCH
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _tabButton('Hadir', isHadir, () {
                          setState(() => isHadir = true);
                        }),
                        _tabButton('Izin', !isHadir, () {
                          setState(() => isHadir = false);
                        }),
                      ],
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () => _onFingerprintTap(context),
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

                  const SizedBox(height: 12),

                  Text(
                    isHadir
                        ? 'Absensi akan mengecek lokasi Anda'
                        : 'Ajukan Izin',
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

  /// =======================
  /// FINGERPRINT HANDLER
  /// =======================
  Future<void> _onFingerprintTap(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();

    final email = auth.userEmail;
    if (email == null) return;

    /// 🔒 KUNCI HARIAN
    if (!attendance.canSubmitAttendance(email) &&
        !attendance.canSubmitIzin(email)) {
      _snack(context, 'Anda sudah melakukan absensi hari ini');
      return;
    }

    final timeStatus =
        attendance.getAttendanceTimeStatus(DateTime.now());

    /// ⏰ TELAT / ALPHA
    if (_handleTimeBasedFlow(context, timeStatus)) return;

    /// 🟢 HADIR / IZIN
    await _handleNormalFlow(context, attendance, auth);
  }

  /// =======================
  /// TIME DISPATCHER
  /// =======================
  bool _handleTimeBasedFlow(
    BuildContext context,
    AttendanceTimeStatus status,
  ) {
    switch (status) {
      case AttendanceTimeStatus.telat:
        showDialog(
          context: context,
          builder: (_) => const IzinTelatDialog(),
        );
        return true;

      case AttendanceTimeStatus.alpha:
        _snack(context, 'Anda dinyatakan Alpha!');
        return true;

      default:
        return false;
    }
  }

  /// =======================
  /// NORMAL FLOW
  /// =======================
  Future<void> _handleNormalFlow(
    BuildContext context,
    AttendanceProvider attendance,
    AuthProvider auth,
  ) async {
    final email = auth.userEmail!;

    if (!isHadir) {
      if (!attendance.canSubmitIzin(email)) {
        _snack(context, 'Izin tidak dapat diajukan hari ini');
        return;
      }
      _showIzinSelector(context);
      return;
    }

    final accessStatus = await attendance.prepareAbsensi(email);

    switch (accessStatus) {
      case AttendanceAccessStatus.allowed:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const PinEntryScreen(),
        );
        break;

      case AttendanceAccessStatus.outsideZone:
        _snack(context, 'Anda berada di luar area absensi');
        break;

      case AttendanceAccessStatus.locationNotReady:
        _snack(context, 'GPS belum aktif');
        break;

      case AttendanceAccessStatus.alreadySubmitted:
        _snack(context, 'Anda sudah absensi hari ini');
        break;

      case AttendanceAccessStatus.izinLocked:
        _snack(context, 'Anda izin tidak hadir hari ini');
        break;

      case AttendanceAccessStatus.alpha:
        _snack(context, 'Waktu absensi telah berakhir');
        break;

      case AttendanceAccessStatus.izinLocked:
        _snack(context, 'Silakan ajukan izin telat terlebih dahulu');
        break;

    }
  }

  /// =======================
  /// IZIN SELECTOR
  /// =======================
  void _showIzinSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Tidak Hadir'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => IzinTidakHadirDialog(
                  userEmail:
                      context.read<AuthProvider>().userEmail!,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Telat / Hadir Siang'),
            onTap: () {
              Navigator.pop(context);
              _showIzinRingan(context);
            },
          ),
        ],
      ),
    );
  }

  void _showIzinRingan(BuildContext context) {
    final reasonCtrl = TextEditingController();
    IzinType selected = IzinType.telat;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Izin Kehadiran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<IzinType>(
              value: selected,
              items: [IzinType.telat, IzinType.hadirSiang]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(izinLabel(e)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => selected = v!,
            ),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Alasan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();

              await context.read<AttendanceProvider>().submitIzin(
                    type: selected,
                    alasan: reasonCtrl.text,
                    email: auth.userEmail!,
                    nama: auth.userName!,
                  );

              Navigator.pop(context);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// UI UTIL
  /// =======================
  Widget _tabButton(
    String text,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color:
                active ? const Color(0xFF6EE7F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color:
                    active ? Colors.white : Colors.black54,
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
