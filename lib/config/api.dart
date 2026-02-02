class ApiConfig {
  /// Base URL
  static const String baseUrl = 'http://192.168.1.14:8000/api';

  ///AUTH
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String profile = '$baseUrl/profile';

  ///ABSENSI
  static const String attendance = '$baseUrl/absen';
  static const String attendanceToday = '$baseUrl/absen/today';

  ///TASKLIST
  static const String task = '$baseUrl/task';

  ///IZIN
  static const String permission = '$baseUrl/izin';
}
