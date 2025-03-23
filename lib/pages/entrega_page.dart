import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../api/rentas_service.dart';
import '../models/entrega_response.dart';

class ConfirmarEntregaPage extends StatefulWidget {
  final int idRenta;
  final String? estadoActual;

  const ConfirmarEntregaPage({
    Key? key,
    required this.idRenta,
    this.estadoActual,
  }) : super(key: key);

  @override
  State<ConfirmarEntregaPage> createState() => _ConfirmarEntregaPageState();
}

class _ConfirmarEntregaPageState extends State<ConfirmarEntregaPage> {
  File? _imagen1;
  File? _imagen2;
  final ImagePicker _picker = ImagePicker();
  final RentasService _rentasService = RentasService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  void _verificarEstado() {
    if (widget.estadoActual != null &&
        widget.estadoActual != 'En transito_Envio') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La renta debe estar en estado "En transito_Envio" para ser marcada como entregada'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  Future<void> _seleccionarImagen(bool isPrimeraImagen) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Calidad reducida para optimizar
        maxWidth: 1024,   // Ancho máximo
        maxHeight: 1024,  // Alto máximo
      );

      if (imagen != null) {
        setState(() {
          if (isPrimeraImagen) {
            _imagen1 = File(imagen.path);
          } else {
            _imagen2 = File(imagen.path);
          }
          _errorMessage = null; // Limpiar mensaje de error si existe
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar la imagen: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Error al seleccionar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarEntrega() async {
    if (_imagen1 == null || _imagen2 == null) {
      setState(() {
        _errorMessage = 'Por favor selecciona ambas imágenes';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Subiendo imágenes...\nPor favor espere',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      final response = await _rentasService.marcarEntregado(
        widget.idRenta,
        _imagen1!,
        _imagen2!,
      );

      // Cerrar diálogo de progreso
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.mensaje),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Esperar a que se muestre el mensaje antes de cerrar
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = response.mensaje;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar diálogo de progreso si hay error
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _errorMessage = 'Error: $e';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 30),
                      SizedBox(height: 8),
                      Text(
                        'Toma fotos claras de la entrega',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Asegúrate de que las imágenes muestren claramente el estado de la entrega',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImagenSelector(
                      'Imagen 1',
                      _imagen1,
                          () => _seleccionarImagen(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagenSelector(
                      'Imagen 2',
                      _imagen2,
                          () => _seleccionarImagen(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmarEntrega,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Confirmar Entrega',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagenSelector(String titulo, File? imagen, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: imagen != null ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: imagen != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      imagen,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black54,
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tomar foto',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (imagen != null)
            TextButton(
              onPressed: () => _seleccionarImagen(titulo == 'Imagen 1'),
              child: const Text('Cambiar foto'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar archivos temporales si existen
    _imagen1?.delete().ignore();
    _imagen2?.delete().ignore();
    super.dispose();
  }
}