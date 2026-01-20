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
  belumWaktu,
  hadir,
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
    return todayStatus(email) == DailyAttendanceStatus.none;
  }

  bool canSubmitAttendance(String email) {
    return todayStatus(email) == DailyAttendanceStatus.none;
  }

  /// =======================
  /// WAKTU ABSENSI
  /// =======================
  AttendanceTimeStatus getAttendanceTimeStatus(DateTime now) {
    if (now.hour < 6) return AttendanceTimeStatus.belumWaktu;
    if (now.hour < 15) return AttendanceTimeStatus.hadir;
    if (now.hour < 16) return AttendanceTimeStatus.telat;
    if (now.hour < 12) return AttendanceTimeStatus.hadirSiang;
    return AttendanceTimeStatus.alpha;
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
      if (getAttendanceTimeStatus(DateTime.now()) ==
          AttendanceTimeStatus.alpha) {
        return AttendanceAccessStatus.alpha;
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
  }) async {
    if (!canSubmitAttendance(email)) return false;

    final now = DateTime.now();
    final timeStatus = getAttendanceTimeStatus(now);

    final map = {
      AttendanceTimeStatus.hadir: DailyAttendanceStatus.hadir,
      AttendanceTimeStatus.telat: DailyAttendanceStatus.telat,
      AttendanceTimeStatus.hadirSiang: DailyAttendanceStatus.hadirSiang,
    };

    final status = map[timeStatus];
    if (status == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      await GoogleSheetService.appendAttendance(
        email: email,
        nama: nama,
        tanggal: DateFormat('yyyy-MM-dd').format(now),
        jam: DateFormat('HH:mm:ss').format(now),
        status: status.name,
        latitude: userLocation?.latitude ?? 0,
        longitude: userLocation?.longitude ?? 0,
        zona: isInsideZone ? 'DALAM' : 'LUAR',
        keterangan: '-',
      );

      _dailyStatus[email] = status;
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
