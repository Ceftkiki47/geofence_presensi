import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../utils/PinUtils.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;

  bool _initialized = false;
  bool _loggedIn = false;
  bool _hasPin = false;
  bool _pinVerified = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _loggedIn;
  bool get hasPin => _hasPin;
  bool get pinVerified => _pinVerified;

  String errorMessage = '';
  String? userEmail;
  String? userName;
  String? profileImage;

  // =======================
  // DEBUG STATE LOGGER
  // =======================
  void _logState(String from) {
    debugPrint(
      '🔐 [$from] '
      'initialized=$_initialized | '
      'loggedIn=$_loggedIn | '
      'hasPin=$_hasPin | '
      'pinVerified=$_pinVerified | '
      'loading=$isLoading',
    );
  }

  // =======================
  // CHECK LOGIN (APP START)
  // =======================
  // Catatan: Method ini selalu reset state ke logged out
  // agar app selalu mulai dari LoginScreen saat restart/refresh
  Future<void> checkLogin() async {
    debugPrint('🔐 checkLogin() START');

    final db = await DBHelper.database;

    // Reset semua isLogin ke 0 untuk memastikan app selalu mulai dari login
    // Ini mencegah app langsung masuk ke PIN verification saat restart
    await db.update('users', {'isLogin': 0});

    // Reset state ke logged out
    // Ini memastikan AppGate akan menampilkan LoginScreen
    _resetState();

    debugPrint(
      '🔐 checkLogin(): State di-reset, app akan mulai dari LoginScreen',
    );

    _initialized = true;
    notifyListeners();
    _logState('checkLogin:end');
  }

  // =======================
  // REGISTER
  // =======================
  Future<String?> register(String email, String password, String nama) async {
    final db = await DBHelper.database;

    final exists = await isEmailExists(email);
    if (exists) return 'EMAIL_EXISTS';

    await db.insert('users', {
      'email': email,
      'password': password,
      'nama': nama,
      'isLogin': 0,
      'pin': null,
    });

    return null;
  }

  // =======================
  // LOGIN
  // =======================
  /// HELPER
  // =======================

  void _setLoading(bool value, {required String context}) {
    isLoading = value;
    debugPrint('⏳ Loading = $value [$context]');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    debugPrint('🔐 [AUTH] API login() CALLED → $email');

    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // ===============================
      // CALL AUTH SERVICE
      // ===============================
      final data = await AuthService().login(email, password);

      // ===============================
      // LOG RESPONSE (DIJAGA)
      // ===============================
      debugPrint('🌐 Status Code: 200');
      debugPrint('📦 Response: $data');

      // ===============================
      // VALIDASI RESPONSE
      // ===============================
      if (data['token'] == null || data['user'] == null) {
        errorMessage = 'Response tidak valid';
        debugPrint('❌ [AUTH] Login FAILED');
        return false;
      }

      final token = data['token'];
      final user = data['user'];

      // ===============================
      // SAVE SESSION
      // ===============================
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_name', user['name']);
      await prefs.setString('user_email', user['email']);
      await prefs.setString('user_role', user['role']);

      _loggedIn = true;

      // ===============================
      // SUCCESS LOG
      // ===============================
      debugPrint('✅ [AUTH] Login SUCCESS');
      debugPrint('🔑 Token saved');
      debugPrint('👤 User: ${user['name']}');

      return true;
    } catch (e, stackTrace) {
      // ===============================
      // ERROR HANDLING
      // ===============================
      errorMessage = e.toString().replaceAll('Exception: ', '');

      debugPrint('🔥 [AUTH] ERROR');
      debugPrint('❗ $e');
      debugPrint('📌 $stackTrace');

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =======================
  // CREATE PIN
  // =======================
  Future<void> createPin(String pin) async {
    debugPrint('🔐 createPin() START');

    final db = await DBHelper.database;
    final hashed = hashPin(pin);

    await db.update('users', {'pin': hashed}, where: 'isLogin = 1');

    _hasPin = true;
    _pinVerified = false;
    notifyListeners();
    _logState('createPin:end');
  }

  // =======================
  // VERIFY PIN
  // =======================
  Future<bool> verifyPin(String inputPin) async {
    debugPrint('🔐 verifyPin() CALLED');

    final db = await DBHelper.database;
    final hashed = hashPin(inputPin);

    final res = await db.query(
      'users',
      where: 'isLogin = 1 AND pin = ?',
      whereArgs: [hashed],
      limit: 1,
    );

    if (res.isNotEmpty) {
      _pinVerified = true;
      notifyListeners();
      _logState('verifyPin:success');
      return true;
    }

    _logState('verifyPin:failed');
    return false;
  }

  // =======================
  // LOGOUT
  // =======================
  Future<void> logout() async {
    final db = await DBHelper.database;
    await db.update('users', {'isLogin': 0});

    _resetState();
    notifyListeners();
    _logState('logout');
  }

  void _resetState() {
    _loggedIn = false;
    _hasPin = false;
    _pinVerified = false;
    _initialized = true;

    userEmail = null;
    userName = null;
    profileImage = null;
  }

  // =======================
  // EMAIL CHECK
  // =======================
  Future<bool> isEmailExists(String email) async {
    final db = await DBHelper.database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  // =======================
  // UPDATE PROFILE IMAGE
  // =======================
  Future<void> updateProfileImage(String path) async {
    final db = await DBHelper.database;

    await db.update('users', {'profileImage': path}, where: 'isLogin = 1');

    profileImage = path;
    notifyListeners();
    _logState('updateProfileImage');
  }

  // =======================
  // CHANGE PASSWORD
  // =======================
  Future<String> changePassword(
    String oldPass,
    String newPass,
    String confirmPass,
  ) async {
    if (newPass.length < 6) return 'Password minimal 6 karakter';
    if (newPass != confirmPass) return 'Konfirmasi password tidak cocok';

    final db = await DBHelper.database;
    final user = await db.query('users', where: 'isLogin = 1');

    if (user.isEmpty) return 'User tidak ditemukan';
    if (user.first['password'] != oldPass) return 'Password lama salah';

    await db.update('users', {'password': newPass}, where: 'isLogin = 1');

    _logState('changePassword');
    return 'Password berhasil diubah';
  }
}
