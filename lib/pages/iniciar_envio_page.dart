import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api/rentas_service.dart';
import '../models/coordenadas_model.dart';

class IniciarEnvioPage extends StatefulWidget {
  final int idRenta;
  final String estadoActual;

  const IniciarEnvioPage({
    Key? key,
    required this.idRenta,
    required this.estadoActual,
  }) : super(key: key);

  @override
  State<IniciarEnvioPage> createState() => _IniciarEnvioPageState();
}

class _IniciarEnvioPageState extends State<IniciarEnvioPage> {
  final RentasService _rentasService = RentasService();
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  WebViewController? _webViewController;
  Map<String, double>? _destinationCoords;

  // Constantes actualizadas
  static const String currentDate = '2025-03-23 17:44:40';
  static const String currentUser = 'TheJesus915';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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

  Future<void> _obtenerCoordenadasDestino() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _rentasService.obtenerRuta(
        widget.idRenta.toString(),
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final urlMaps = response.data!.urlMaps;
        print('URL Maps recibida: $urlMaps');

        // Extraer coordenadas de destino de la URL
        // El formato es: .../dir/origen_lat,origen_lng/destino_lat,destino_lng/
        final coordsPattern = RegExp(r'/(\-?\d+\.\d+),(\-?\d+\.\d+)/(\-?\d+\.\d+),(\-?\d+\.\d+)/');
        final match = coordsPattern.firstMatch(urlMaps);

        if (match != null && match.groupCount == 4) {
          try {
            // Usamos las coordenadas de destino (grupos 3 y 4)
            final lat = double.parse(match.group(3)!);
            final lng = double.parse(match.group(4)!);

            print('Coordenadas extraídas - Lat: $lat, Lng: $lng');

            setState(() {
              _destinationCoords = {
                'lat': lat,
                'lng': lng,
              };
            });

            _initializeWebView();
          } catch (e) {
            throw 'Error al procesar las coordenadas: $e';
          }
        } else {
          throw 'No se pudieron extraer las coordenadas de la URL: $urlMaps';
        }
      } else {
        throw response.message;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener coordenadas de destino: $e';
      });
      print('Error detallado: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      await _obtenerCoordenadasDestino();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener la ubicación: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    if (_currentPosition == null || _destinationCoords == null) {
      print('No se pueden inicializar el mapa sin coordenadas completas');
      return;
    }

    try {
      final mapHtml = '''
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
            <link rel="stylesheet" href="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.css" />
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
            <script src="https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.js"></script>
            <style>
              html, body {
                height: 100%;
                margin: 0;
                padding: 0;
              }
              #map {
                height: 100%;
                width: 100%;
                position: absolute;
              }
            </style>
          </head>
          <body>
            <div id="map"></div>
            <script>
              try {
                const map = L.map('map', {
                  zoomControl: true,
                  dragging: true,
                  scrollWheelZoom: true
                });

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                  attribution: '© OpenStreetMap contributors'
                }).addTo(map);

                const currentPos = [${_currentPosition!.latitude}, ${_currentPosition!.longitude}];
                const destPos = [${_destinationCoords!['lat']}, ${_destinationCoords!['lng']}];

                const bounds = L.latLngBounds([currentPos, destPos]);
                map.fitBounds(bounds, { padding: [50, 50] });

                L.marker(currentPos)
                  .addTo(map)
                  .bindPopup('Tu ubicación actual')
                  .openPopup();

                L.marker(destPos)
                  .addTo(map)
                  .bindPopup('Destino');

                L.Routing.control({
                  waypoints: [
                    L.latLng(currentPos[0], currentPos[1]),
                    L.latLng(destPos[0], destPos[1])
                  ],
                  routeWhileDragging: false,
                  showAlternatives: true,
                  fitSelectedRoutes: true,
                  language: 'es',
                  lineOptions: {
                    styles: [{color: '#0066CC', opacity: 0.8, weight: 6}]
                  }
                }).addTo(map);
              } catch (error) {
                console.error('Error initializing map:', error);
              }
            </script>
          </body>
        </html>
      ''';

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(mapHtml);

      setState(() {});
    } catch (e) {
      print('Error al inicializar el mapa: $e');
    }
  }

  Future<void> _iniciarEnvio() async {
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

      final response = await _rentasService.iniciarEnvio(
        widget.idRenta.toString(),
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        if (response.data!.urlMaps.isNotEmpty) {
          final abrirMaps = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Envío Iniciado'),
                content: const Text('¿Deseas ver la ruta en Google Maps?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sí'),
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
        title: const Text('Iniciar Envío'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${widget.estadoActual}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
            if (_currentPosition != null && _destinationCoords != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        if (_webViewController != null)
                          WebViewWidget(
                            controller: _webViewController!,
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Card(
                            child: IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                              tooltip: 'Actualizar ubicación',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ubicación obtenida',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _currentPosition == null
                  ? null
                  : _iniciarEnvio,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Color(0xFF00345E),
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
                  : const Text('INICIAR ENVÍO'),
            ),
          ],
        ),
      ),
    );
  }
}