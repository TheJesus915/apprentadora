import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../models/renta_model.dart';
import '../api/rentas_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/entrega_page.dart';
import '../pages/iniciar_recoleccion_page.dart';
import '../pages/finalizar_recoleccion_page.dart';

class RentaCard extends StatelessWidget {
  final Renta renta;
  final VoidCallback onTap;
  final RentasService rentasService;

  static const String currentDate = '2025-03-23 18:46:45';
  static const String currentUser = 'TheJesus915';

  const RentaCard({
    Key? key,
    required this.renta,
    required this.onTap,
    required this.rentasService,
  }) : super(key: key);

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.green;
      case 'Pendiente_Pago':
        return Colors.amber;
      case 'En transito_Recoleccion':
      case 'En Transito_Recoleccion':
        return Colors.orange;
      case 'En transito_Envio':
      case 'En Transito_Envio':
        return Colors.blue;
      case 'Entregado':
        return Colors.purple;
      case 'Finalizado':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación están desactivados';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Los permisos de ubicación fueron denegados';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Los permisos de ubicación están permanentemente denegados';
      }

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Error: $e');
      return null;
    }
  }

  Future<void> _handleRutaAction(BuildContext context) async {
    try {
      _showLoadingDialog(context);

      final position = await _getCurrentLocation(context);
      if (position == null) {
        _closeDialog(context);
        return;
      }

      final response = await rentasService.obtenerRuta(
        renta.idRenta,
        position.latitude,
        position.longitude,
      );

      _closeDialog(context);

      if (response.success && response.data != null) {
        // Formatear la URL para asegurar que sea compatible con Google Maps
        String urlString = response.data!.urlMaps;

        // Asegurarse de que la URL use https
        if (!urlString.startsWith('https://')) {
          urlString = urlString.replaceFirst('http://', 'https://');
        }

        // Intentar primero con la URL de Google Maps web
        Uri? url = Uri.tryParse(urlString);

        if (url != null) {
          // Intentar abrir en Google Maps app primero
          String mapsUrl = 'comgooglemaps://?${url.query}';
          if (await canLaunchUrl(Uri.parse(mapsUrl))) {
            await launchUrl(Uri.parse(mapsUrl));
          }
          // Si no se puede abrir en la app, intentar con la URL web
          else if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          }
          // Si ambos fallan, intentar con geo URI
          else {
            // Extraer coordenadas de la URL
            final coordsPattern = RegExp(r'/(-?\d+\.\d+),(-?\d+\.\d+)/');
            final matches = coordsPattern.allMatches(urlString);

            if (matches.length >= 2) {
              final originLat = matches.elementAt(0).group(1);
              final originLng = matches.elementAt(0).group(2);
              final destLat = matches.elementAt(1).group(1);
              final destLng = matches.elementAt(1).group(2);

              final geoUrl = Uri.parse(
                  'geo:$originLat,$originLng?q=$destLat,$destLng'
              );

              if (await canLaunchUrl(geoUrl)) {
                await launchUrl(geoUrl);
              } else {
                throw 'No se pudo abrir ninguna aplicación de mapas';
              }
            } else {
              throw 'Formato de URL no válido';
            }
          }
        } else {
          throw 'URL de mapas no válida';
        }
      } else {
        throw Exception(response.message ?? 'Error al obtener la ruta');
      }
    } catch (e) {
      _closeDialog(context);
      _showErrorSnackBar(
        context,
        'Error: ${e.toString().replaceAll('Exception:', '')}',
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Obteniendo ruta...'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _closeDialog(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String fecha) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha));
    } catch (e) {
      return fecha;
    }
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'Pendiente':
        return 'Pendiente';
      case 'Pendiente_Pago':
        return 'Pendiente de Pago';
      case 'En transito_Recoleccion':
      case 'En Transito_Recoleccion':
        return 'En Recolección';
      case 'En transito_Envio':
      case 'En Transito_Envio':
        return 'En Tránsito';
      case 'Entregado':
        return 'Entregado';
      case 'Finalizado':
        return 'Finalizado';
      default:
        return estado;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    print('Estado actual: "${renta.estado}"'); // Debug print

    switch (renta.estado.trim()) {
      case 'Pendiente':
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.local_shipping,
                label: 'Iniciar Envío',
                color: Colors.green,
                onPressed: () => onTap(),
              ),
            ),
          ],
        );

      case 'En transito_Recoleccion':
      case 'En Transito_Recoleccion':
      case 'En_Transito_Recoleccion':
      case 'En_transito_Recoleccion':
        print('Mostrando botones de recolección'); // Debug print
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.map,
                label: 'Ver Ruta',
                color: Colors.blue,
                onPressed: () => _handleRutaAction(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildButton(
                icon: Icons.check_circle,
                label: 'Finalizar',
                color: Colors.green,
                onPressed: () => _navigateToFinalizarRecoleccion(context),
              ),
            ),
          ],
        );

      case 'Entregado':
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.local_shipping,
                label: 'Iniciar Recolección',
                color: Colors.blue,
                onPressed: () => onTap(),
              ),
            ),
          ],
        );

      case 'En transito_Envio':
      case 'En Transito_Envio':
      case 'En_Transito_Envio':
      case 'En_transito_Envio':
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.map,
                label: 'Ver Ruta',
                color: Colors.blue,
                onPressed: () => _handleRutaAction(context),
              ),
            ),
          ],
        );

      default:
        print('Estado no manejado: "${renta.estado}"'); // Debug print
        return const SizedBox.shrink();
    }
  }

  Future<void>




  (BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalizarRecoleccionPage(
          renta: renta,
          rentasService: rentasService,
          onRentaFinalizada: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Renta finalizada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            onTap(); // Para actualizar la lista de rentas
          },
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo RentaCard con estado: "${renta.estado}"'); // Debug print

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      renta.producto.imagen,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          renta.producto.nombre,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(renta.estado),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(renta.estado),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cliente: ${renta.cliente.nombre}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inicio: ${_formatDate(renta.fechas.inicio)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Final: ${_formatDate(renta.fechas.final_)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }
}