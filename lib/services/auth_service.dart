  import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
      String email, String password) async {

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message']);
    }
  }
}
