class RutaResponse {
  final bool success;
  final String message;
  final RutaData? data;

  RutaResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RutaResponse.fromJson(Map<String, dynamic> json) {
    return RutaResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? RutaData.fromJson(json['data']) : null,
    );
  }
}

class RutaData {
  final String estado;
  final String urlMaps;

  RutaData({
    required this.estado,
    required this.urlMaps,
  });

  factory RutaData.fromJson(Map<String, dynamic> json) {
    return RutaData(
      estado: json['estado'] ?? '',
      urlMaps: json['url_maps'] ?? '',
    );
  }
}