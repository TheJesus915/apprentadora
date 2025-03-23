class LoginRequest {
  final String correo;
  final String password;

  LoginRequest({required this.correo, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'correo': correo,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final bool necesitaPago;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    required this.necesitaPago,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Error desconocido',
      token: json['token'],
      necesitaPago: json['necesitaPago'] ?? false,
    );
  }
}
