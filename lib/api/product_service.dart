import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apprentadora/models/product_model.dart';

class ProductService {
  final String baseUrl = "https://rentzmx.com/api/api/v1";

  Future<List<Product>> fetchProducts() async {
    final url = Uri.parse("$baseUrl/rentadora/productos/listar");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    if (token == null) {
      throw Exception("⚠ No hay token de autenticación.");
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data["data"] as List).map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception("❌ Error ${response.statusCode}: ${response.body}");
      }
    } catch (error) {
      throw Exception("⚠ Error de conexión: $error");
    }
  }
}
