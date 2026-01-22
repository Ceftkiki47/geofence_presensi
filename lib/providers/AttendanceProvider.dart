import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../screens/MainMapScreen.dart';
import '../services/GoogleSheetService.dart';

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
}
enum DailyAttendanceStatus {
  none,            // belum melakukan apa pun hari ini
  hadir,
  telat,
  hadirSiang,
  izinTidakHadir,
  alpha,
}


enum IzinType {
  tidakHadir,
  telat,
  hadirSiang,
}

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
  /// WAKTU ABSENSI
  /// =======================
  AttendanceTimeStatus getAttendanceTimeStatus(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;
    final totalMinute = hour * 60 + minute;

    if (totalMinute > 7 * 60) {
      return AttendanceTimeStatus.alpha;
    }
    if (totalMinute <= 7 * 60 + 55) {
      return AttendanceTimeStatus.datangLebihAwal;
    }
    if (totalMinute <= 8 * 60 + 5) {
      return AttendanceTimeStatus.tepatWaktu;
    }
    if (totalMinute <= 2 * 60 + 50) {
      return AttendanceTimeStatus.telat;
    }
    return AttendanceTimeStatus.alpha;
  }
  
  /// =======================
  /// MAPPING STATUS
  /// ======================= 
  DailyAttendanceStatus? mapToDailyStatus(
    AttendanceTimeStatus status,
  ) {
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
    isLoading = true;
    notifyListeners();

    try {
      await _getAndCheckLocation();

      if (!isLocationReady) {
        return AttendanceAccessStatus.locationNotReady;
      }

      if (!isInsideZone) {
        return AttendanceAccessStatus.outsideZone;
      }

      if (!canSubmitAttendance(email)) {
        return AttendanceAccessStatus.alreadySubmitted;
      }

      final timeStatus = getAttendanceTimeStatus(DateTime.now());

      if (timeStatus == AttendanceTimeStatus.alpha) {
        return AttendanceAccessStatus.alpha;
      }

      if (timeStatus == AttendanceTimeStatus.telat) {
        return AttendanceAccessStatus.allowed; // akan trigger popup
      }

      return AttendanceAccessStatus.allowed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    if (getAttendanceTimeStatus(DateTime.now()) ==
        AttendanceTimeStatus.alpha) return false;

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
  /// AUTO ALPHA
  /// =======================
  Future<void> handleAutoAlpha({
    required String email,
    required String nama,
  }) async {
    if (alreadySubmittedToday(email)) return;

    final now = DateTime.now();
    if (getAttendanceTimeStatus(now) != AttendanceTimeStatus.alpha) return;

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
      keterangan: '-',
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
