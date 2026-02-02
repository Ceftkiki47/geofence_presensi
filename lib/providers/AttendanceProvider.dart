import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../screens/MainMapScreen.dart';
import '../services/GoogleSheetService.dart';
// import '../models/ModelTask.dart';

/// =======================
/// ENUM
/// =======================
enum AttendanceTimeStatus {
  datangLebihAwal,
  tepatWaktu,
  telat,
  hadirSiang,
  alpha,
}

enum AttendanceAccessStatus {
  allowed,
  outsideZone,
  locationNotReady,
  alreadySubmitted,
  izinLocked,
  alpha,
  pulang,
  lembur,
  notAllowed,
}

enum DailyAttendanceStatus {
  none, // belum melakukan apa pun hari ini
  hadir,
  telat,
  hadirSiang,
  izinTidakHadir,
  alpha,
  pulang,
  lembur,
}

enum AttendancePhase { checkIn, checkOut, locked }

enum IzinType { tidakHadir, telat, hadirSiang }

enum GlobalAccessTime {
  locked, //jam 9 malam
  active, //jam 6.pagi - 8 malam
}

enum CheckoutTimeStatus { notAllowed, pulangNormal, lembur }

String mapIzinType(IzinType type) {
  switch (type) {
    case IzinType.tidakHadir:
      return 'TIDAK_HADIR';
    case IzinType.telat:
      return 'TELAT';
    case IzinType.hadirSiang:
      return 'HADIR_SIANG';
  }
}

/// =======================
/// PROVIDER
/// =======================
class AttendanceProvider extends ChangeNotifier {
  bool isLoading = false;

  LatLng? userLocation;
  bool isLocationReady = false;
  bool isInsideZone = false;

  /// =======================
  /// STATUS HARIAN (SINGLE SOURCE OF TRUTH)
  /// =======================
  final Map<String, DailyAttendanceStatus> _dailyStatus = {};
  final Map<String, DateTime> _dailyDate = {};

  /// =======================
  /// UTIL
  /// =======================
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool alreadySubmittedToday(String email) {
    final date = _dailyDate[email];
    if (date == null) return false;
    return _isSameDay(date, DateTime.now());
  }

  DailyAttendanceStatus todayStatus(String email) {
    if (!alreadySubmittedToday(email)) {
      return DailyAttendanceStatus.none;
    }
    return _dailyStatus[email] ?? DailyAttendanceStatus.none;
  }

  bool canSubmitIzin(String email) {
    final status = todayStatus(email);
    return status == DailyAttendanceStatus.none;
  }

  bool canSubmitAttendance(String email) {
    final status = todayStatus(email);
    return status == DailyAttendanceStatus.none;
  }

  bool isIzinTidakHadirToday(String email) {
    return todayStatus(email) == DailyAttendanceStatus.izinTidakHadir;
  }

  /// =======================
  /// MENENTUKAN JAM ABSENSI DAN PULANG
  /// =======================
  AttendancePhase getAttendancePhase(String email) {
    final now = DateTime.now();

    if (isGlobalLocked(now)) {
      return AttendancePhase.locked;
    }

    final status = todayStatus(email);

    if (status == DailyAttendanceStatus.hadir ||
        status == DailyAttendanceStatus.telat ||
        status == DailyAttendanceStatus.hadirSiang) {
      return AttendancePhase.checkOut;
    }

    return AttendancePhase.checkIn;
  }

  /// =======================
  /// WAKTU ABSENSI
  /// =======================
  AttendanceTimeStatus getAttendanceTimeStatus(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;
    final totalMinute = hour * 60 + minute;

    if (totalMinute <= 7 * 60 + 55) {
      return AttendanceTimeStatus.datangLebihAwal;
    }
    if (totalMinute <= 12 * 60 + 5) {
      return AttendanceTimeStatus.tepatWaktu;
    }
    if (totalMinute <= 12 * 60 + 50) {
      return AttendanceTimeStatus.telat;
    }
    if (totalMinute <= 13 * 60) {
      return AttendanceTimeStatus.hadirSiang;
    }
    return AttendanceTimeStatus.alpha;
  }

  /// =======================
  /// JAM PULANG
  /// =======================
  bool isGlobalLocked(DateTime now) {
    final total = now.hour * 60 + now.minute;
    return total >= 21 * 60 || total < 6 * 60;
  }

  CheckoutTimeStatus getCheckoutTimeStatus(DateTime now) {
    final total = now.hour * 60 + now.minute;

    if (total >= 13 * 60 + 55 && total <= 17 * 60 + 5) {
      return CheckoutTimeStatus.pulangNormal;
    }

    if (total >= 17 * 60 + 6 && total <= 20 * 60) {
      return CheckoutTimeStatus.lembur;
    }

    return CheckoutTimeStatus.notAllowed;
  }

  /// =======================
  /// MAPPING STATUS
  /// =======================
  DailyAttendanceStatus? mapToDailyStatus(AttendanceTimeStatus status) {
    switch (status) {
      case AttendanceTimeStatus.datangLebihAwal:
      case AttendanceTimeStatus.tepatWaktu:
        return DailyAttendanceStatus.hadir;

      case AttendanceTimeStatus.telat:
        return DailyAttendanceStatus.telat;

      case AttendanceTimeStatus.hadirSiang:
        return DailyAttendanceStatus.hadirSiang;

      case AttendanceTimeStatus.alpha:
        return DailyAttendanceStatus.alpha;
    }
  }

  /// =======================
  /// LOKASI
  /// =======================
  Future<void> _getAndCheckLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLocation = LatLng(pos.latitude, pos.longitude);
    isLocationReady = true;

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      MainMapScreen.schoolCenter.latitude,
      MainMapScreen.schoolCenter.longitude,
    );

    isInsideZone = distance <= MainMapScreen.schoolRadius;
  }

  /// =======================
  /// AKSES ABSENSI
  /// =======================
  Future<AttendanceAccessStatus> prepareAbsensi(String email) async {
    await _getAndCheckLocation();

    if (!isInsideZone) return AttendanceAccessStatus.outsideZone;

    final phase = getAttendancePhase(email);

    if (phase == AttendancePhase.locked) {
      return AttendanceAccessStatus.alpha;
    }

    if (phase == AttendancePhase.checkIn) {
      final checkInStatus = getAttendanceTimeStatus(DateTime.now());

      if (checkInStatus == AttendanceTimeStatus.telat) {
        return AttendanceAccessStatus.izinLocked;
      }

      return AttendanceAccessStatus.allowed;
    }

    if (phase == AttendancePhase.checkOut) {
      final checkoutStatus = getCheckoutTimeStatus(DateTime.now());

      if (checkoutStatus == CheckoutTimeStatus.notAllowed) {
        return AttendanceAccessStatus.notAllowed;
      }

      return AttendanceAccessStatus.pulang;
    }

    return AttendanceAccessStatus.notAllowed;
  }

  /// =======================
  /// SUBMIT ABSENSI
  /// =======================
  Future<bool> submitAttendance({
    required File image,
    required String email,
    required String nama,
    String? keteranganTelat,
    File? dokumentasiTelat,
  }) async {
    if (!canSubmitAttendance(email)) return false;

    final now = DateTime.now();
    final timeStatus = getAttendanceTimeStatus(now);
    final dailyStatus = mapToDailyStatus(timeStatus);

    if (dailyStatus == null || dailyStatus == DailyAttendanceStatus.alpha) {
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      await GoogleSheetService.appendAttendance(
        email: email,
        nama: nama,
        tanggal: DateFormat('yyyy-MM-dd').format(now),
        jam: DateFormat('HH:mm:ss').format(now),
        status: dailyStatus.name,
        latitude: userLocation?.latitude ?? 0,
        longitude: userLocation?.longitude ?? 0,
        zona: isInsideZone ? 'DALAM' : 'LUAR',
        keterangan: timeStatus == AttendanceTimeStatus.telat
            ? keteranganTelat ?? 'TELAT TANPA KETERANGAN'
            : '-',
      );

      _dailyStatus[email] = dailyStatus;
      _dailyDate[email] = now;

      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =======================
  /// IZIN
  /// =======================
  Future<bool> submitIzin({
    required IzinType type,
    required String alasan,
    required String email,
    required String nama,
  }) async {
    if (alasan.isEmpty) return false;
    if (!canSubmitIzin(email)) return false;
    if (getAttendanceTimeStatus(DateTime.now()) == AttendanceTimeStatus.alpha)
      return false;

    await GoogleSheetService.insertIzin(
      tanggal: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      email: email,
      nama: nama,
      jenis: mapIzinType(type),
      alasan: alasan,
      waktuPengajuan: DateTime.now().toIso8601String(),
    );

    _dailyStatus[email] = DailyAttendanceStatus.izinTidakHadir;
    _dailyDate[email] = DateTime.now();

    notifyListeners();
    return true;
  }

  /// =======================
  /// IZIN SIANG
  /// =======================
  Future<bool> submitHadirSiang({
    required String email,
    required String nama,
    required String alasan,
  }) async {
    if (!canSubmitAttendance(email)) return false;

    final now = DateTime.now();

    isLoading = true;
    notifyListeners();

    try {
      await GoogleSheetService.appendAttendance(
        email: email,
        nama: nama,
        tanggal: DateFormat('yyyy-MM-dd').format(now),
        jam: DateFormat('HH:mm:ss').format(now),
        status: DailyAttendanceStatus.hadirSiang.name,
        latitude: userLocation?.latitude ?? 0,
        longitude: userLocation?.longitude ?? 0,
        zona: isInsideZone ? 'DALAM' : 'LUAR',
        keterangan: alasan,
      );

      _dailyStatus[email] = DailyAttendanceStatus.hadirSiang;
      _dailyDate[email] = now;

      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =======================
  /// ABSENSI PULANG
  /// =======================
  bool canAccessFingerprint(String email) {
    final now = DateTime.now();

    if (isGlobalLocked(now)) return false;

    final status = todayStatus(email);

    // Sudah pulang → tidak bisa lagi
    if (status == DailyAttendanceStatus.pulang ||
        status == DailyAttendanceStatus.lembur) {
      return false;
    }

    // Jika sudah hadir → cek apakah waktu pulang
    if (status == DailyAttendanceStatus.hadir ||
        status == DailyAttendanceStatus.telat ||
        status == DailyAttendanceStatus.hadirSiang) {
      return getCheckoutTimeStatus(now) != CheckoutTimeStatus.notAllowed;
    }

    // Default (absensi datang)
    return true;
  }

  /// =======================
  /// SUBMIT PULANG
  /// =======================
  // Future<bool> submitCheckout({
  //   required File image,
  //   required String email,
  //   required String nama,
  //   required List<TaskItem> tasks,
  // }) async {
  //   if (alreadySubmittedToday(email)) return false;

  //   final now = DateTime.now();
  //   final checkoutStatus = getCheckoutTimeStatus(now);

  //   if (checkoutStatus == CheckoutTimeStatus.notAllowed) {
  //     return false;
  //   }

  //   isLoading = true;
  //   notifyListeners();

  //   try {
  //     final status = checkoutStatus == CheckoutTimeStatus.pulangNormal
  //         ? DailyAttendanceStatus.pulang
  //         : DailyAttendanceStatus.lembur;

  //     /// 🔹 SIMPAN ABSENSI PULANG
  //     await GoogleSheetService.appendAttendance(
  //       email: email,
  //       nama: nama,
  //       tanggal: DateFormat('yyyy-MM-dd').format(now),
  //       jam: DateFormat('HH:mm:ss').format(now),
  //       status: status.name,
  //       latitude: userLocation?.latitude ?? 0,
  //       longitude: userLocation?.longitude ?? 0,
  //       zona: isInsideZone ? 'DALAM' : 'LUAR',
  //       keterangan: checkoutStatus == CheckoutTimeStatus.lembur
  //           ? 'LEMBUR'
  //           : 'PULANG',
  //     );

  //     /// 🔹 SIMPAN TASK
  //     // for (final task in tasks) {
  //     //   await GoogleSheetService.insertTask(
  //     //     email: email,
  //     //     tanggal: DateFormat('yyyy-MM-dd').format(now),
  //     //     task: task.title,
  //     //     status: task.status.name,
  //     //   );
  //     // }

  //     _dailyStatus[email] = status;
  //     _dailyDate[email] = now;

  //     return true;
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  /// =======================
  /// AUTO ALPHA
  /// =======================
  Future<void> handleAutoAlpha({
    required String email,
    required String nama,
  }) async {
    if (alreadySubmittedToday(email)) return;

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinute = hour * 60 + minute;

    /// ALPHA HANYA SET SETELAH JAM 21.00
    if (totalMinute < 17 * 60 + 5) return;

    _dailyStatus[email] = DailyAttendanceStatus.alpha;
    _dailyDate[email] = now;

    await GoogleSheetService.appendAttendance(
      email: email,
      nama: nama,
      tanggal: DateFormat('yyyy-MM-dd').format(now),
      jam: DateFormat('HH:mm:ss').format(now),
      status: 'alpha',
      latitude: 0,
      longitude: 0,
      zona: 'LUAR',
      keterangan: 'TIDAK ABSEN SEHARI PENUH',
    );

    notifyListeners();
  }

  /// =======================
  /// RESET
  /// =======================
  void reset() {
    isLoading = false;
    userLocation = null;
    isLocationReady = false;
    isInsideZone = false;
    _dailyStatus.clear();
    _dailyDate.clear();
    notifyListeners();
  }
}
