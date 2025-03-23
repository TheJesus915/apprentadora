class CoordenadasResponse {
  final bool success;
  final String message;
  final RutaData? data;

  CoordenadasResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CoordenadasResponse.fromJson(Map<String, dynamic> json) {
    return CoordenadasResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? RutaData.fromJson(json['data']) : null,
    );
  }
}

class RutaData {
  final String? estado;
  final String urlMaps;

  RutaData({
    this.estado,
    required this.urlMaps,
  });

  factory RutaData.fromJson(Map<String, dynamic> json) {
    return RutaData(
      estado: json['estado'],
      urlMaps: json['url_maps'] ?? '',
    );
  }
}