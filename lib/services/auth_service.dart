import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class AuthService {
  /// ===============================
  /// AUTH LOGIN API
  /// ===============================
  /// Flow:
  /// 1. Kirim request POST ke API Laravel
  /// 2. Kirim email & password dalam bentuk JSON
  /// 3. Terima response (status + body)
  /// 4. Lempar error jika status ≠ 200
  /// ===============================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/login');

    // ===============================
    // REQUEST LOG
    // ===============================
    debugPrint('🌐 [AUTH API] POST $url');
    debugPrint('📤 Payload:');
    debugPrint('   • email    : $email');
    debugPrint('   • password : ${'*' * password.length}');
    debugPrint('⏳ Mengirim request ke server...');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      // ===============================
      // RESPONSE LOG
      // ===============================
      debugPrint('📥 [AUTH API] RESPONSE');
      debugPrint('🔢 Status Code : ${response.statusCode}');
      debugPrint('📦 Raw Body    : ${response.body}');

      if (!response.headers['content-type']!.contains('application/json')) {
        throw Exception('Response bukan JSON');
      }

      // ===============================
      // PARSE RESPONSE (SAFE)
      // ===============================
      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Response tidak valid (bukan JSON): ${response.body}');
      }

      // Pastikan format JSON object
      if (data is! Map<String, dynamic>) {
        throw Exception('Format response salah (bukan object JSON): $data');
      }

      // ===============================
      // SUCCESS
      // ===============================
      if (response.statusCode == 200) {
        // Validasi struktur data
        if (!data.containsKey('token') || !data.containsKey('user')) {
          throw Exception('Response login tidak lengkap');
        }

        debugPrint('✅ [AUTH API] Login berhasil');
        debugPrint('🔑 Token diterima');
        debugPrint('👤 User: ${data['user']['name']}');

        return data;
      }

      // ===============================
      // FAILED (VALIDATION / AUTH)
      // ===============================
      debugPrint('❌ [AUTH API] Login gagal');
      debugPrint('📛 Message: ${data['message']}');

      throw Exception(data['message'] ?? 'Login gagal');
    } catch (e, stackTrace) {
      // ===============================
      // NETWORK / SERVER ERROR
      // ===============================
      debugPrint('🔥 [AUTH API] ERROR TERJADI');
      debugPrint('❗ Error: $e');
      debugPrint('📌 StackTrace:');
      debugPrint('$stackTrace');

      rethrow;
    }
  }
}
