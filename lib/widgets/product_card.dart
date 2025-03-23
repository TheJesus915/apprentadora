import 'package:flutter/material.dart';
import 'package:apprentadora/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product producto;

  const ProductCard({Key? key, required this.producto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: producto.urlImagenPrincipal.isNotEmpty
            ? Image.network(
          producto.urlImagenPrincipal,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        )
            : Icon(Icons.image, size: 50, color: Colors.grey),
        title: Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Cantidad: ${producto.cantidad}"),
      ),
    );
  }
}
