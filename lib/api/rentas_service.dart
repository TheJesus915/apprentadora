import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http_parser/http_parser.dart';
import '../models/renta_model.dart';
import '../models/ruta_model.dart';
import '../models/coordenadas_model.dart';
import '../models/entrega_response.dart';
import '../models/recoleccion_response.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RentasService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 20), // Tiempo de espera de conexión
    receiveTimeout: Duration(seconds: 20), // Tiempo de espera de respuesta
  ));
  final String _baseUrl = 'https://rentzmx.com/api/api/v1/rentadora';
  late String _token;

  RentasService() {
    _loadToken();
  }

  Future<File> compressImage(File file) async {
    final dir = Directory.systemTemp;
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Calidad de compresión (0-100)
      minWidth: 1024, // Ancho máximo
      minHeight: 1024, // Alto máximo
    );

    return File(result?.path ?? file.path);
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
  }




  Future<Map<String, String>> _getHeaders() async {
    return {
      'Authorization': 'Bearer $_token',
      'Accept': 'application/json',
    };
  }


  // Método auxiliar para obtener los datos actuales
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Ubicación desactivada');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }
  // Obtener lista de rentas
  Future<List<Renta>> getRentas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await _dio.get(
        '$_baseUrl/rentas/obtener',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Respuesta getRentas: ${response.data}');

      if (response.statusCode == 404) {
        return [];
      }

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => Renta.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo las rentas: $e');
      return [];
    }
  }

  // Obtener detalle de una renta específica
  Future<Renta?> getRentaById(String idRenta) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      print('Obteniendo detalle de renta: $idRenta');

      final response = await _dio.get(
        '$_baseUrl/rentas/obtener/$idRenta',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Respuesta detalle renta: ${response.data}');

      if (response.statusCode == 404) {
        throw Exception('No se encontró la renta especificada');
      }

      if (response.data['success'] == true && response.data['data'] != null) {
        return Renta.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Error al obtener los detalles de la renta');
      }
    } catch (e) {
      print('Error obteniendo detalle de renta: $e');
      rethrow;
    }
  }

  // Iniciar envío
  Future<RutaResponse> iniciarEnvio(
      String idRenta,
      double latitud,
      double longitud,
      ) async {
    try {
      final token = await _token;
      if (token == null) throw Exception('No hay token de autenticación');

      final url = Uri.parse('$_baseUrl/rentas/iniciar-envio/$idRenta');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitud_origen': latitud.toString(),
          'longitud_origen': longitud.toString(),
        }),
      );

      final responseData = json.decode(response.body);

      return RutaResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Error al iniciar el envío: $e');
    }
  }

  // Obtener ruta
  Future<CoordenadasResponse> obtenerRuta(
      String idRenta,
      double latitudOrigen,
      double longitudOrigen,
      ) async {
    try {
      print('Enviando solicitud a: $_baseUrl/rentas/obtener-ruta/$idRenta');
      print('Con datos: lat: $latitudOrigen, lng: $longitudOrigen');

      final response = await _dio.post(
        '$_baseUrl/rentas/obtener-ruta/$idRenta', // Agregada la URL base
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'latitud_origen': latitudOrigen.toString(),
          'longitud_origen': longitudOrigen.toString(),
        },
      );

      print('Respuesta recibida: ${response.data}');
      return CoordenadasResponse.fromJson(response.data);
    } catch (e) {
      print('Error en obtenerRuta: $e');
      return CoordenadasResponse(
        success: false,
        message: 'Error al obtener ruta: $e',
      );
    }
  }// Marcar como entregado
  Future<EntregaResponse> marcarEntregado(
      int idRenta,
      File imagen1,
      File imagen2,
      ) async {
    try {
      final token = await _token;
      if (token == null) throw Exception('No hay token de autenticación');

      var url = Uri.parse('$_baseUrl/rentas/marcar-entregado/$idRenta');
      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Agregar imágenes con el nombre de campo correcto 'imagenes'
      request.files.addAll([
        await http.MultipartFile.fromPath(
          'imagenes', // Cambiado a 'imagenes'
          imagen1.path,
          contentType: MediaType('image', 'jpeg'),
        ),
        await http.MultipartFile.fromPath(
          'imagenes', // Cambiado a 'imagenes'
          imagen2.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      ]);

      print('Enviando request...');
      print('URL: $url');
      print('Headers: ${request.headers}');
      print('Files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Status Code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return EntregaResponse.fromJson(responseData);
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? responseData['mensaje'] ?? 'Error desconocido');
      }
    } catch (e) {
      print('Error en marcarEntregado: $e');
      throw Exception('Error al marcar como entregado: $e');
    }
  }

  Future<RecoleccionResponse> iniciarRecoleccion(
      int idRenta,
      double latitud,
      double longitud,
      ) async {
    try {
      final token = await _token;
      if (token == null) throw Exception('No hay token de autenticación');

      final url = Uri.parse('$_baseUrl/rentas/iniciar-recoleccion/$idRenta');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitud_origen': latitud.toString(),
          'longitud_origen': longitud.toString(),
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RecoleccionResponse.fromJson(json.decode(response.body));
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      print('Error en iniciarRecoleccion: $e');
      throw Exception('Error al iniciar recolección: $e');
    }
  }

  Future<Map<String, dynamic>> finalizarRenta(String idRenta) async {
    try {
      final token = await _token;
      if (token == null) throw Exception('No hay token de autenticación');

      final url = Uri.parse('$_baseUrl/rentas/finalizar/$idRenta');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Error al finalizar la renta');
      }
    } catch (e) {
      throw Exception('Error al finalizar la renta: $e');
    }
  }
}

