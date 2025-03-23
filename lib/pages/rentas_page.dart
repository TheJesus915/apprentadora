import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/rentas_service.dart';
import '../models/renta_model.dart';
import '../widgets/renta_card.dart';
import '../widgets/renta_detail_modal.dart';
import 'iniciar_recoleccion_page.dart';
import 'iniciar_envio_page.dart';
import 'entrega_page.dart';

class RentasPage extends StatefulWidget {
  const RentasPage({Key? key}) : super(key: key);

  @override
  _RentasPageState createState() => _RentasPageState();
}

class _RentasPageState extends State<RentasPage> {
  final RentasService _rentasService = RentasService();
  List<Renta> rentas = [];
  bool isLoading = true;
  bool ordenAscendente = true;
  String filtroEstado = 'todos';

  // Constantes actualizadas
  static const String currentDate = '2025-03-23 17:32:23';
  static const String currentUser = 'TheJesus915';

  @override
  void initState() {
    super.initState();
    _cargarRentas();
  }

  Future<void> _cargarRentas() async {
    setState(() => isLoading = true);
    try {
      final rentasData = await _rentasService.getRentas();
      setState(() {
        rentas = rentasData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        rentas = [];
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las rentas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
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

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _toggleOrden() {
    setState(() {
      ordenAscendente = !ordenAscendente;
      rentas.sort((a, b) => ordenAscendente
          ? a.fechas.inicio.compareTo(b.fechas.inicio)
          : b.fechas.inicio.compareTo(a.fechas.inicio));
    });
  }

  List<Renta> get rentasFiltradas {
    return rentas.where((renta) {
      if (filtroEstado == 'todos') return true;
      return renta.estado == filtroEstado;
    }).toList();
  }

  Future<void> _iniciarRecoleccion(Renta renta) async {
    if (renta.estado != 'Entregado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden iniciar recolecciones de rentas entregadas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IniciarRecoleccionPage(
          idRenta: int.parse(renta.idRenta),
          estadoActual: renta.estado,
        ),
      ),
    );

    if (result == true) {
      await _cargarRentas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recolección iniciada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _iniciarEnvio(Renta renta) async {
    if (renta.estado != 'Pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden iniciar envíos de rentas pendientes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IniciarEnvioPage(
          idRenta: int.parse(renta.idRenta),
          estadoActual: renta.estado,
        ),
      ),
    );

    if (result == true) {
      await _cargarRentas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Envío iniciado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEntrega(Renta renta) async {
    if (renta.estado != 'En transito_Envio') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden confirmar entregas de rentas en tránsito'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmarEntregaPage(
          idRenta: int.parse(renta.idRenta),
          estadoActual: renta.estado,
        ),
      ),
    );

    if (result == true) {
      await _cargarRentas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega confirmada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _verRuta(Renta renta) async {
    try {
      // Primero obtener la ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await _rentasService.obtenerRuta(
        renta.idRenta,
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final url = Uri.parse(response.data!.urlMaps);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'No se pudo abrir la ruta';
        }
      } else {
        throw response.message ?? 'Error al obtener la ruta';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarOpcionesRenta(Renta renta) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (renta.estado == 'Pendiente')
                ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Iniciar Envío'),
                  onTap: () {
                    Navigator.pop(context);
                    _iniciarEnvio(renta);
                  },
                ),
              if (renta.estado == 'Entregado')
                ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Iniciar Recolección'),
                  onTap: () {
                    Navigator.pop(context);
                    _iniciarRecoleccion(renta);
                  },
                ),
              if (renta.estado == 'En transito_Recoleccion' ||
                  renta.estado == 'En transito_Envio')
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Ver Ruta'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await _checkLocationPermission()) {
                      _verRuta(renta);
                    }
                  },
                ),
              if (renta.estado == 'En transito_Envio')
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Confirmar Entrega'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmarEntrega(renta);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Ver Detalles'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDetalleRenta(renta.idRenta);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay rentas disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (filtroEstado != 'todos')
            Text(
              'Prueba cambiando los filtros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordenar por fecha',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _toggleOrden,
                  icon: Icon(
                    ordenAscendente
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  label: Text(
                    ordenAscendente
                        ? 'Más antiguo primero'
                        : 'Más reciente primero',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por estado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filtroEstado,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onChanged: (String? newValue) {
                        setState(() {
                          filtroEstado = newValue!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem(
                          value: 'Pendiente',
                          child: Text('Pendiente'),
                        ),
                        DropdownMenuItem(
                          value: 'Pendiente_Pago',
                          child: Text('Pendiente de Pago'),
                        ),
                        DropdownMenuItem(
                          value: 'En transito_Recoleccion',
                          child: Text('En Recolección'),
                        ),
                        DropdownMenuItem(
                          value: 'En transito_Envio',
                          child: Text('En Tránsito'),
                        ),
                        DropdownMenuItem(
                          value: 'Entregado',
                          child: Text('Entregado'),
                        ),
                        DropdownMenuItem(
                          value: 'Finalizado',
                          child: Text('Finalizado'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaRentas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentasFiltradas.length,
      itemBuilder: (context, index) {
        final renta = rentasFiltradas[index];
        return RentaCard(
          renta: renta,
          onTap: () => _mostrarOpcionesRenta(renta),
          rentasService: _rentasService,
        );
      },
    );
  }

  Future<void> _mostrarDetalleRenta(String idRenta) async {
    try {
      final rentaDetalle = await _rentasService.getRentaById(idRenta);
      if (rentaDetalle != null && mounted) {
        await showDialog(
          context: context,
          builder: (context) => RentaDetailModal(renta: rentaDetalle),
        );
        await _cargarRentas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los detalles de la renta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRentas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarRentas,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: rentasFiltradas.isEmpty
                  ? _buildEmptyState()
                  : _buildListaRentas(),
            ),
          ],
        ),
      ),

    );
  }
}