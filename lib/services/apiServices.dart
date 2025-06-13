import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL untuk API
  static const String baseUrl = "https://semarnari.sportballnesia.com/api/master/";

  // Menangani request POST login
  Future<http.Response> login(String username, String password) async {
    final url = Uri.parse("${baseUrl}user/login");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );
    return response;
  }

  Future<Map<String, dynamic>> register(
      String name,
      String email,
      String username,
      String password,
      String branch,
      int grade,
      String gender,
      String reasonForJoining,
      String childPhoneNumber,
      ) async {
    final url = Uri.parse('${baseUrl}user/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': name,
          'email': email,
          'username': username,
          'password': password,
          'branch': branch,
          'grade': grade,
          'gender': gender,
          'reason_for_joining': reasonForJoining,
          'child_phone_number': childPhoneNumber,
          'isActive': 1,
          'accessRole': 1,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorResponse = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': errorResponse['message'] ?? 'Terjadi kesalahan pada server',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Tidak dapat terhubung ke server. Silakan coba lagi.',
      };
    }
  }

  // Menangani request GET (jika diperlukan)
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http.get(url);
    return response;
  }

  // Menangani request POST (untuk pendaftaran atau data lainnya)
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
    return response;
  }
}
