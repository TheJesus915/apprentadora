class FinalizarRentaResponse {
  final bool success;
  final String message;
  final FinalizarRentaData? data;

  FinalizarRentaResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory FinalizarRentaResponse.fromJson(Map<String, dynamic> json) {
    return FinalizarRentaResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? FinalizarRentaData.fromJson(json['data']) : null,
    );
  }
}

class FinalizarRentaData {
  final String estado;

  FinalizarRentaData({
    required this.estado,
  });

  factory FinalizarRentaData.fromJson(Map<String, dynamic> json) {
    return FinalizarRentaData(
      estado: json['estado'] ?? '',
    );
  }
}