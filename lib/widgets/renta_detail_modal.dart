import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/renta_model.dart';

class RentaDetailModal extends StatelessWidget {
  final Renta renta;

  const RentaDetailModal({
    Key? key,
    required this.renta,
  }) : super(key: key);

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.green;
      case 'Pendiente_Pago':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera con imagen y botón de cerrar
            Stack(
              children: [
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        renta.producto.imagen,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(Icons.error, size: 50),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            renta.producto.nombre,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(renta.estado),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              renta.estado,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            // Información de costos
            _buildSection(
              'Información de Costos',
              [
                _buildInfoRow('Total:', '\$${renta.costos.total}'),
                _buildInfoRow('Envío:', '\$${renta.costos.envio}'),
                if (renta.costos.subtotal != null)
                  _buildInfoRow('Subtotal:', '\$${renta.costos.subtotal}'),
              ],
            ),

            // Información de fechas
            _buildSection(
              'Fechas',
              [
                _buildInfoRow('Inicio:', _formatDate(renta.fechas.inicio)),
                _buildInfoRow('Final:', _formatDate(renta.fechas.final_)),
              ],
            ),

            // Información de dirección
            _buildSection(
              'Dirección de Entrega',
              [
                _buildInfoRow('Calle:',
                    '${renta.direccionEntrega.calle} ${renta.direccionEntrega.numeroExterior}'),
                if (renta.direccionEntrega.numeroInterior != null)
                  _buildInfoRow(
                      'Interior:', renta.direccionEntrega.numeroInterior!),
                _buildInfoRow('Colonia:', renta.direccionEntrega.colonia),
                _buildInfoRow('C.P.:', renta.direccionEntrega.codigoPostal),
                _buildInfoRow('Referencia:', renta.direccionEntrega.referencia),
              ],
            ),

            // Información del cliente
            _buildSection(
              'Información del Cliente',
              [
                _buildInfoRow('Nombre:', renta.cliente.nombre),
                _buildInfoRow('Correo:', renta.cliente.correo),
                _buildInfoRow('Contacto:', renta.direccionEntrega.contacto),
                if (renta.cliente.telefono != null)
                  _buildInfoRow('Teléfono:', renta.cliente.telefono!),
              ],
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 8),
          ...children,
          Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
