class RecoleccionResponse {
  final bool success;
  final String message;
  final RecoleccionData? data;

  RecoleccionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RecoleccionResponse.fromJson(Map<String, dynamic> json) {
    return RecoleccionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? RecoleccionData.fromJson(json['data']) : null,
    );
  }
}

class RecoleccionData {
  final String estado;
  final String urlMaps;

  RecoleccionData({
    required this.estado,
    required this.urlMaps,
  });

  factory RecoleccionData.fromJson(Map<String, dynamic> json) {
    return RecoleccionData(
      estado: json['estado'] ?? '',
      urlMaps: json['url_maps'] ?? '',
    );
  }
}