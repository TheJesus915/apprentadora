class Renta {
  final String idRenta;
  final Producto producto;
  final String estado;
  final Costos costos;
  final Fechas fechas;
  final DireccionEntrega direccionEntrega;
  final Cliente cliente;

  Renta({
    required this.idRenta,
    required this.producto,
    required this.estado,
    required this.costos,
    required this.fechas,
    required this.direccionEntrega,
    required this.cliente,
  });

  factory Renta.fromJson(Map<String, dynamic> json) {
    try {
      return Renta(
        idRenta: json['id_renta']?.toString() ?? '',
        producto: Producto.fromJson(json['producto'] ?? {}),
        estado: json['estado']?.toString() ?? 'Desconocido',
        costos: Costos.fromJson(json['costos'] ?? {}),
        fechas: Fechas.fromJson(json['fechas'] ?? {}),
        direccionEntrega: DireccionEntrega.fromJson(json['direccion_entrega'] ?? {}),
        cliente: Cliente.fromJson(json['cliente'] ?? {}),
      );
    } catch (e) {
      print('Error parsing Renta: $e');
      rethrow;
    }
  }
}

class Producto {
  final String nombre;
  final String imagen;
  final String? descripcion;
  final double? precio;

  Producto({
    required this.nombre,
    required this.imagen,
    this.descripcion,
    this.precio,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      imagen: json['imagen']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: _parseDouble(json['precio']),
    );
  }
}

class Costos {
  final double total;
  final double envio;
  final double? subtotal;
  final double? impuestos;

  Costos({
    required this.total,
    required this.envio,
    this.subtotal,
    this.impuestos,
  });

  factory Costos.fromJson(Map<String, dynamic> json) {
    return Costos(
      total: _parseDouble(json['total']),
      envio: _parseDouble(json['envio']),
      subtotal: _parseDouble(json['subtotal']),
      impuestos: _parseDouble(json['impuestos']),
    );
  }
}

class Fechas {
  final String inicio;
  final String final_;
  final String? fechaCreacion;
  final String? fechaActualizacion;

  Fechas({
    required this.inicio,
    required this.final_,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Fechas.fromJson(Map<String, dynamic> json) {
    return Fechas(
      inicio: json['inicio']?.toString() ?? '',
      final_: json['final']?.toString() ?? '',
      fechaCreacion: json['fecha_creacion']?.toString(),
      fechaActualizacion: json['fecha_actualizacion']?.toString(),
    );
  }
}

class DireccionEntrega {
  final String calle;
  final String numeroExterior;
  final String? numeroInterior;
  final String colonia;
  final String codigoPostal;
  final String referencia;
  final String contacto;
  final String? ciudad;
  final String? estado;
  final String? pais;

  DireccionEntrega({
    required this.calle,
    required this.numeroExterior,
    this.numeroInterior,
    required this.colonia,
    required this.codigoPostal,
    required this.referencia,
    required this.contacto,
    this.ciudad,
    this.estado,
    this.pais,
  });

  factory DireccionEntrega.fromJson(Map<String, dynamic> json) {
    return DireccionEntrega(
      calle: json['calle']?.toString() ?? '',
      numeroExterior: json['numero_exterior']?.toString() ?? '',
      numeroInterior: json['numero_interior']?.toString(),
      colonia: json['colonia']?.toString() ?? '',
      codigoPostal: json['codigo_postal']?.toString() ?? '',
      referencia: json['referencia']?.toString() ?? '',
      contacto: json['contacto']?.toString() ?? '',
      ciudad: json['ciudad']?.toString(),
      estado: json['estado']?.toString(),
      pais: json['pais']?.toString(),
    );
  }
}

class Cliente {
  final String nombre;
  final String correo;
  final String? telefono;
  final String? id;

  Cliente({
    required this.nombre,
    required this.correo,
    this.telefono,
    this.id,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      id: json['id']?.toString(),
    );
  }
}

// Función auxiliar para el parsing de números
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}