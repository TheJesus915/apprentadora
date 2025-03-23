import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';

class AuthService {
  static const String apiUrl = 'https://rentzmx.com/api/api/v1/auth/login';

  Future<LoginResponse> login(LoginRequest credentials) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(credentials.toJson()),
      );

      final data = jsonDecode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      if (response.statusCode == 200 && loginResponse.success) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (loginResponse.token != null) {
          await prefs.setString('token', loginResponse.token!);
        }
      }

      return loginResponse;
    } catch (error) {
      print('Error: $error');
      return LoginResponse(
        success: false,
        message: 'Error de conexión',
        necesitaPago: false,
      );
    }
  }
}
