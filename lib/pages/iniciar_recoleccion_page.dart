import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/rentas_service.dart';
import '../models/coordenadas_model.dart';

class IniciarRecoleccionPage extends StatefulWidget {
  final int idRenta;
  final String? estadoActual;

  const IniciarRecoleccionPage({
    Key? key,
    required this.idRenta,
    this.estadoActual,
  }) : super(key: key);

  @override
  State<IniciarRecoleccionPage> createState() => _IniciarRecoleccionPageState();
}

class _IniciarRecoleccionPageState extends State<IniciarRecoleccionPage> {
  final RentasService _rentasService = RentasService();
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  CoordenadasResponse? _rutaInfo;

  static const String currentDate = '2025-03-23 17:29:27';
  static const String currentUser = 'TheJesus915';

  @override
  void initState() {
    super.initState();
    _verificarEstado();
    _checkLocationPermission();
  }

  void _verificarEstado() {
    if (widget.estadoActual != null &&
        widget.estadoActual == 'En transito_Recoleccion') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La recolección ya está en proceso'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  Future<void> _checkLocationPermission() async {
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

      _getCurrentLocation();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _obtenerRuta();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener la ubicación: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _obtenerRuta() async {
    if (_currentPosition == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _rentasService.obtenerRuta(
        widget.idRenta.toString(),
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _rutaInfo = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ruta: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _iniciarRecoleccion() async {
    if (_currentPosition == null) {
      setState(() {
        _errorMessage = 'No se ha podido obtener la ubicación';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _rentasService.iniciarRecoleccion(
        widget.idRenta,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (!mounted) return;

      if (response.success) {
        if (response.data?.urlMaps != null) {
          final abrirMaps = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Recolección Iniciada'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(response.message),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('Abrir en Google Maps'),
                      onPressed: () async {
                        final url = Uri.parse(response.data!.urlMaps);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context, true); // Volver a la página anterior
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              );
            },
          );

          if (abrirMaps == true) {
            final url = Uri.parse(response.data!.urlMaps);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          }
        }

        Navigator.pop(context, true);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Recolección'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Renta #${widget.idRenta}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Colors.green[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ubicación obtenida',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lat: ${_currentPosition!.latitude}\nLong: ${_currentPosition!.longitude}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_rutaInfo?.data != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Colors.blue[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.map,
                                  color: Colors.blue,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ruta disponible',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (_rutaInfo?.data?.urlMaps != null) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Ver en Google Maps'),
                                    onPressed: () async {
                                      final url = Uri.parse(_rutaInfo!.data!.urlMaps);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading || _currentPosition == null
                    ? null
                    : _iniciarRecoleccion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('INICIAR RECOLECCIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}