class Product {
  final int id;
  final String nombre;
  final String categoria;
  final int cantidad;
  final int cantidadActual;
  final double precio;
  final String descripcion;
  final String material;
  final bool listado;
  final bool disponible;
  final String urlImagenPrincipal;
  final bool esPromocion;
  final double precioPromocion;

  Product({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.cantidadActual,
    required this.precio,
    required this.descripcion,
    required this.material,
    required this.listado,
    required this.disponible,
    required this.urlImagenPrincipal,
    required this.esPromocion,
    required this.precioPromocion,
  });

  // Método para convertir JSON a un objeto Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["Id_producto"] ?? 0,
      nombre: json["nombre_producto"] ?? "Sin nombre",
      categoria: json["Categoria"] ?? "Sin categoría",
      cantidad: int.tryParse(json["cantidad"]?.toString() ?? "0") ?? 0,
      cantidadActual: int.tryParse(json["cantidad_actual"]?.toString() ?? "0") ?? 0,
      precio: double.tryParse(json["precio"]?.toString() ?? "0.0") ?? 0.0,
      descripcion: json["descripcion"] ?? "Sin descripción",
      material: json["material"] ?? "Desconocido",
      listado: (json["listado"] is bool) ? json["listado"] : json["listado"] == 1,
      disponible: (json["disponible"] is bool) ? json["disponible"] : json["disponible"] == 1,
      urlImagenPrincipal: json["url_imagenprincipal"] ?? "",
      esPromocion: (json["es_promocion"] is bool) ? json["es_promocion"] : json["es_promocion"] == 1,
      precioPromocion: double.tryParse(json["precio_promocion"]?.toString() ?? "0.0") ?? 0.0,
    );
  }

  // Método para convertir el objeto Product a JSON
  Map<String, dynamic> toJson() {
    return {
      "Id_producto": id,
      "nombre_producto": nombre,
      "Categoria": categoria,
      "cantidad": cantidad,
      "cantidad_actual": cantidadActual,
      "precio": precio,
      "descripcion": descripcion,
      "material": material,
      "listado": listado ? 1 : 0,
      "disponible": disponible ? 1 : 0,
      "url_imagenprincipal": urlImagenPrincipal,
      "es_promocion": esPromocion ? 1 : 0,
      "precio_promocion": precioPromocion,
    };
  }
}
