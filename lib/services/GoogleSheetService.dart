import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis_auth/auth_io.dart';

class AttendanceRow {
  final String email;
  final String tanggal;
  final String jam;
  final String status;
  final String zona;
  final String keterangan;

  AttendanceRow({
    required this.email,
    required this.tanggal,
    required this.jam,
    required this.status,
    required this.zona,
    required this.keterangan,
  });
}


class GoogleSheetService {
  static const _scopes = [SheetsApi.spreadsheetsScope];
  static const String spreadsheetId =
      '1X8vzx9CVYMf0XljG1vC4ZP-SGhnYRn1q6Stw7diWbeo';

  static Future<SheetsApi> _getApi() async {
    final jsonString = await rootBundle.loadString(
      'assets/credentials/service_account.json',
    );

    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonString));

    final client = await clientViaServiceAccount(credentials, _scopes);
    return SheetsApi(client);
  }

  /// =========================
  /// ABSENSI
  /// =========================
  static Future<void> appendAttendance({
    required String email,
    required String nama,
    required String tanggal,
    required String jam,
    required String status,
    required double latitude,
    required double longitude,
    required String zona,
    required String keterangan,
  }) async {
    
    final api = await _getApi();

    final values = ValueRange(values: [
      [
        email,
        tanggal,
        nama,
        jam,
        status,
        latitude,
        longitude,
        zona,
        keterangan,
      ]
    ]);

    await api.spreadsheets.values.append(
      values,
      spreadsheetId,
      'ABSENSI!A:I',
      valueInputOption: 'USER_ENTERED',
    );
  }

  /// =========================
  /// IZIN
  /// =========================
  static Future<void> insertIzin({
    required String tanggal,
    required String email,
    required String nama,
    required String jenis,
    required String alasan,
    String dokumentasi = '-',
    required String waktuPengajuan,
    String statusSistem = 'MENUNGGU',
  }) async {
    final api = await _getApi();

    final values = ValueRange(values: [
      [
        tanggal,
        email,
        nama,
        jenis,
        alasan,
        dokumentasi,
        waktuPengajuan,
        statusSistem,
      ]
    ]);

    await api.spreadsheets.values.append(
      values,
      spreadsheetId,
      'IZIN!A:H',
      valueInputOption: 'USER_ENTERED',
    );
  }

  static Future<List<AttendanceRow>> fetchAttendanceByEmail(
    String email,
  ) async {
    final api = await _getApi();

    final res = await api.spreadsheets.values.get(
      spreadsheetId,
      'ABSENSI!A:I',
    );

    final rows = res.values ?? [];

    return rows
        .skip(1) // skip header
        .where((r) => r.length >= 5 && r[0] == email)
        .map((r) => AttendanceRow(
              email: r[0].toString(),
              tanggal: r[1].toString(),
              jam: r[3].toString(),
              status: r[4].toString(),
              zona: r.length > 7 ? r[7].toString() : '',
              keterangan: r.length > 8 ? r[8].toString() : '',
            ))
        .toList();
  }

}
