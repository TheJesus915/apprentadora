class EntregaResponse {
  final bool success;
  final String mensaje;
  final EntregaData? data;

  EntregaResponse({
    required this.success,
    required this.mensaje,
    this.data,
  });

  factory EntregaResponse.fromJson(Map<String, dynamic> json) {
    return EntregaResponse(
      success: json['success'] ?? false,
      mensaje: json['mensaje'] ?? json['message'] ?? '',
      data: json['data'] != null ? EntregaData.fromJson(json['data']) : null,
    );
  }
}

class EntregaData {
  final String estado;
  final String urlImagen1;
  final String urlImagen2;

  EntregaData({
    required this.estado,
    required this.urlImagen1,
    required this.urlImagen2,
  });

  factory EntregaData.fromJson(Map<String, dynamic> json) {
    return EntregaData(
      estado: json['estado'] ?? '',
      urlImagen1: json['url_imagen1'] ?? '',
      urlImagen2: json['url_imagen2'] ?? '',
    );
  }
}